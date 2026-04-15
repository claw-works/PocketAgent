import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'crc32.dart';

/// A single header in an AWS Event Stream message.
class EventStreamHeader {
  final String name;
  final int type;
  final dynamic value;
  EventStreamHeader(this.name, this.type, this.value);

  @override
  String toString() => '$name=$value';
}

/// A decoded AWS Event Stream message (frame).
class EventStreamMessage {
  final List<EventStreamHeader> headers;
  final Uint8List payload;

  EventStreamMessage(this.headers, this.payload);

  String? header(String name) {
    for (final h in headers) {
      if (h.name == name) return h.value?.toString();
    }
    return null;
  }

  String get payloadString => utf8.decode(payload);

  /// The :message-type header — "event", "exception", or "error".
  String? get messageType => header(':message-type');

  /// The :event-type header — e.g. "contentBlockDelta".
  String? get eventType => header(':event-type');

  /// The :exception-type header for error frames.
  String? get exceptionType => header(':exception-type');
}

/// Exception thrown when an AWS Event Stream error/exception frame is received.
class EventStreamException implements Exception {
  final String type;
  final String message;
  EventStreamException(this.type, this.message);

  @override
  String toString() => 'EventStreamException($type): $message';
}

/// AWS Event Stream binary protocol decoder.
///
/// Frame layout:
/// ```
/// [total_length:4] [headers_length:4] [prelude_crc:4]
/// [headers:headers_length]
/// [payload:total_length - headers_length - 16]
/// [message_crc:4]
/// ```
///
/// Prelude = first 8 bytes (total_length + headers_length).
/// Prelude CRC covers the 8-byte prelude.
/// Message CRC covers everything except the last 4 bytes.
class EventStreamDecoder extends StreamTransformerBase<List<int>, EventStreamMessage> {
  const EventStreamDecoder();

  @override
  Stream<EventStreamMessage> bind(Stream<List<int>> stream) {
    return Stream.eventTransformed(stream, (sink) => _DecoderSink(sink));
  }
}

class _DecoderSink implements EventSink<List<int>> {
  final EventSink<EventStreamMessage> _out;
  final _buffer = BytesBuilder(copy: false);

  _DecoderSink(this._out);

  @override
  void add(List<int> data) {
    _buffer.add(data);
    _drain();
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _out.addError(error, stackTrace);
  }

  @override
  void close() {
    _out.close();
  }

  void _drain() {
    while (true) {
      final bytes = _buffer.toBytes();
      // Need at least 12 bytes for prelude + prelude CRC
      if (bytes.length < 12) break;

      final view = ByteData.sublistView(bytes);
      final totalLength = view.getUint32(0);
      final headersLength = view.getUint32(4);

      // Validate prelude CRC
      final preludeCrc = view.getUint32(8);
      final computedPreludeCrc = Crc32.compute(Uint8List.sublistView(bytes, 0, 8));
      if (preludeCrc != computedPreludeCrc) {
        _out.addError(EventStreamException('CrcError', 'Prelude CRC mismatch: expected $preludeCrc, got $computedPreludeCrc'));
        // Try to recover by skipping a byte
        _buffer.clear();
        _buffer.add(bytes.sublist(1));
        continue;
      }

      // Wait for full frame
      if (bytes.length < totalLength) break;

      // Validate message CRC
      final messageCrc = view.getUint32(totalLength - 4);
      final computedMessageCrc = Crc32.compute(Uint8List.sublistView(bytes, 0, totalLength - 4));
      if (messageCrc != computedMessageCrc) {
        _out.addError(EventStreamException('CrcError', 'Message CRC mismatch'));
        _buffer.clear();
        _buffer.add(bytes.sublist(totalLength));
        continue;
      }

      // Parse headers
      final headersStart = 12;
      final headersEnd = headersStart + headersLength;
      final headers = _parseHeaders(Uint8List.sublistView(bytes, headersStart, headersEnd));

      // Extract payload
      final payloadStart = headersEnd;
      final payloadEnd = totalLength - 4; // before message CRC
      final payload = Uint8List.sublistView(bytes, payloadStart, payloadEnd);

      final msg = EventStreamMessage(headers, Uint8List.fromList(payload));

      // Check for error/exception frames
      if (msg.messageType == 'exception' || msg.messageType == 'error') {
        final errType = msg.exceptionType ?? msg.messageType ?? 'Unknown';
        String errMsg;
        try {
          final body = jsonDecode(msg.payloadString);
          errMsg = body['message'] ?? body['Message'] ?? msg.payloadString;
        } catch (_) {
          errMsg = msg.payloadString;
        }
        _out.addError(EventStreamException(errType, errMsg));
      } else {
        _out.add(msg);
      }

      // Consume frame from buffer
      _buffer.clear();
      if (bytes.length > totalLength) {
        _buffer.add(bytes.sublist(totalLength));
      }
    }
  }

  /// Parse headers from binary format.
  /// Each header: [name_len:1] [name:name_len] [type:1] [value...]
  /// Type 7 (string): [value_len:2] [value:value_len]
  /// Type 6 (bytes):  [value_len:2] [value:value_len]
  /// Type 4 (int32):  [value:4]
  /// Type 5 (int64):  [value:8]
  /// Type 0 (bool true), 1 (bool false): no value bytes
  /// Type 8 (timestamp): [value:8]
  /// Type 9 (uuid): [value:16]
  static List<EventStreamHeader> _parseHeaders(Uint8List data) {
    final headers = <EventStreamHeader>[];
    var offset = 0;
    final view = ByteData.sublistView(data);

    while (offset < data.length) {
      // Header name
      final nameLen = data[offset];
      offset += 1;
      final name = utf8.decode(data.sublist(offset, offset + nameLen));
      offset += nameLen;

      // Header type
      final type = data[offset];
      offset += 1;

      // Header value based on type
      dynamic value;
      switch (type) {
        case 0: // bool true
          value = true;
          break;
        case 1: // bool false
          value = false;
          break;
        case 2: // byte
          value = data[offset];
          offset += 1;
          break;
        case 3: // short
          value = view.getInt16(offset);
          offset += 2;
          break;
        case 4: // int
          value = view.getInt32(offset);
          offset += 4;
          break;
        case 5: // long
          value = view.getInt64(offset);
          offset += 8;
          break;
        case 6: // bytes
          final len = view.getUint16(offset);
          offset += 2;
          value = data.sublist(offset, offset + len);
          offset += len;
          break;
        case 7: // string
          final len = view.getUint16(offset);
          offset += 2;
          value = utf8.decode(data.sublist(offset, offset + len));
          offset += len;
          break;
        case 8: // timestamp (int64 millis)
          value = view.getInt64(offset);
          offset += 8;
          break;
        case 9: // uuid (16 bytes)
          value = data.sublist(offset, offset + 16);
          offset += 16;
          break;
        default:
          // Unknown type — skip rest
          value = null;
          offset = data.length;
      }

      headers.add(EventStreamHeader(name, type, value));
    }

    return headers;
  }
}
