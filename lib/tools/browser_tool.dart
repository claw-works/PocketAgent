import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';
import '../services/cdp_client.dart';

/// 🌐 Browser control via Chrome DevTools Protocol.
/// Can navigate, read DOM, execute JS, click elements, fill forms, screenshot.
class BrowserTool extends BaseTool {
  static final _cdp = CdpClient();

  @override
  String get name => 'browser';

  @override
  String get description =>
      '通过 Chrome DevTools Protocol 操控浏览器：导航、读取页面内容、执行 JavaScript、'
      '点击元素、填写表单、截图。首次使用会自动启动 Chrome。';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': [
              'connect',
              'navigate',
              'get_content',
              'execute_js',
              'click',
              'type_text',
              'screenshot',
              'get_tabs',
            ],
            'description':
                'connect: 连接/启动 Chrome; '
                'navigate: 打开 URL; '
                'get_content: 获取页面文本或 HTML; '
                'execute_js: 执行 JavaScript; '
                'click: 点击 CSS 选择器匹配的元素; '
                'type_text: 在输入框中输入文字; '
                'screenshot: 截取页面截图; '
                'get_tabs: 获取所有标签页',
          },
          'url': {'type': 'string', 'description': '目标 URL（navigate 时必填）'},
          'selector': {'type': 'string', 'description': 'CSS 选择器（click/type_text 时必填）'},
          'text': {'type': 'string', 'description': '要输入的文字（type_text 时必填）'},
          'expression': {'type': 'string', 'description': 'JavaScript 表达式（execute_js 时必填）'},
          'format': {
            'type': 'string',
            'enum': ['text', 'html'],
            'description': 'get_content 返回格式，默认 text',
          },
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;

    try {
      // Auto-connect if needed
      if (action != 'connect' && !_cdp.isConnected) {
        await _cdp.connect();
      }

      switch (action) {
        case 'connect':
          await _cdp.connect();
          return _ok('Chrome 已连接');

        case 'navigate':
          final url = args['url'] as String? ?? '';
          final result = await _cdp.send('Page.navigate', {'url': url});
          if (result['error'] != null) return _err(result['error']['message']);
          // Wait for page load
          await Future.delayed(const Duration(seconds: 1));
          return _ok('已导航到 $url');

        case 'get_content':
          final format = args['format'] ?? 'text';
          final js = format == 'html'
              ? 'document.documentElement.outerHTML'
              : 'document.body.innerText';
          final result = await _evalJs(js);
          // Truncate to avoid token explosion
          final content = result.length > 4000 ? '${result.substring(0, 4000)}...(截断)' : result;
          return jsonEncode({'status': 'ok', 'content': content});

        case 'execute_js':
          final expr = args['expression'] as String? ?? '';
          final result = await _evalJs(expr);
          return jsonEncode({'status': 'ok', 'result': result});

        case 'click':
          final selector = args['selector'] as String? ?? '';
          await _evalJs('document.querySelector(${jsonEncode(selector)})?.click()');
          return _ok('已点击 $selector');

        case 'type_text':
          final selector = args['selector'] as String? ?? '';
          final text = args['text'] as String? ?? '';
          await _evalJs(
            'const el = document.querySelector(${jsonEncode(selector)}); '
            'if(el){el.focus(); el.value = ${jsonEncode(text)}; '
            'el.dispatchEvent(new Event("input",{bubbles:true}));}',
          );
          return _ok('已在 $selector 输入文字');

        case 'screenshot':
          final result = await _cdp.send('Page.captureScreenshot', {'format': 'png'});
          if (result['error'] != null) return _err(result['error']['message']);
          // Save to temp file
          final data = result['result']['data'] as String;
          final file = File('${Directory.systemTemp.path}/pa_screenshot.png');
          await file.writeAsBytes(base64Decode(data));
          return jsonEncode({'status': 'ok', 'path': file.path, 'message': '截图已保存'});

        case 'get_tabs':
          final result = await _cdp.send('Target.getTargets');
          final targets = (result['result']['targetInfos'] as List)
              .where((t) => t['type'] == 'page')
              .map((t) => {'title': t['title'], 'url': t['url']})
              .toList();
          return jsonEncode({'status': 'ok', 'tabs': targets});

        default:
          return _err('未知 action: $action');
      }
    } catch (e) {
      return _err('$e');
    }
  }

  Future<String> _evalJs(String expression) async {
    final result = await _cdp.send('Runtime.evaluate', {
      'expression': expression,
      'returnByValue': true,
    });
    if (result['error'] != null) throw Exception(result['error']['message']);
    final val = result['result']?['result'];
    if (val == null) return '';
    if (val['type'] == 'undefined') return '';
    return val['value']?.toString() ?? jsonEncode(val);
  }

  String _ok(String msg) => jsonEncode({'status': 'ok', 'message': msg});
  String _err(String msg) => jsonEncode({'status': 'error', 'message': msg});
}
