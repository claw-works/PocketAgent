import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';
import '../services/cdp_client.dart';
import '../services/skill/skill_registry.dart';

/// 🌐 Browser control via Chrome DevTools Protocol.
/// Can navigate, read DOM, execute JS, click elements, fill forms, screenshot.
class BrowserTool extends BaseTool {
  static final _cdp = CdpClient();

  @override
  String get name => 'browser';

  @override
  String get description =>
      '通过 Chrome DevTools Protocol 操控浏览器：导航、读取页面内容、执行 JavaScript、'
      '点击元素（CSS 选择器或坐标）、填写表单、截图、等待加载。首次使用会自动启动 Chrome。\n'
      '操作策略：有 Skill/SOP 时直接用选择器（最快）；选择器失效或陌生网站时，'
      '用截图 → click_at_xy 坐标点击（穿透 iframe/shadow DOM）。';

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
              'click_at_xy',
              'type_text',
              'screenshot',
              'get_tabs',
              'wait_for_load',
            ],
            'description':
                'connect: 连接/启动 Chrome; '
                'navigate: 打开 URL（自动等待加载完成）; '
                'get_content: 获取页面文本或 HTML; '
                'execute_js: 执行 JavaScript; '
                'click: 点击 CSS 选择器匹配的元素; '
                'click_at_xy: 在指定坐标点击（穿透 iframe/shadow DOM）; '
                'type_text: 在输入框中输入文字; '
                'screenshot: 截取页面截图; '
                'get_tabs: 获取所有标签页; '
                'wait_for_load: 等待页面加载完成',
          },
          'url': {'type': 'string', 'description': '目标 URL（navigate 时必填）'},
          'selector': {'type': 'string', 'description': 'CSS 选择器（click/type_text 时必填）'},
          'text': {'type': 'string', 'description': '要输入的文字（type_text 时必填）'},
          'expression': {'type': 'string', 'description': 'JavaScript 表达式（execute_js 时必填）'},
          'x': {'type': 'number', 'description': 'X 坐标（click_at_xy 时必填）'},
          'y': {'type': 'number', 'description': 'Y 坐标（click_at_xy 时必填）'},
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
          // 先注册 load 事件监听，再发起导航
          final loadFuture = _cdp.waitForLoad(timeout: const Duration(seconds: 15));
          final result = await _cdp.send('Page.navigate', {'url': url});
          if (result['error'] != null) return _err(result['error']['message']);
          await loadFuture;
          // 按域名查找匹配的 skill
          final skillHint = SkillRegistry.instance.getSkillsForUrl(url);
          final msg = StringBuffer('已导航到 $url（页面已加载完成）。💡 建议截图查看当前页面状态');
          if (skillHint.isNotEmpty) {
            msg.write('\n\n$skillHint');
          }
          return _ok(msg.toString());

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
          return _ok('已点击 $selector。💡 建议截图验证点击效果');

        case 'click_at_xy':
          final x = (args['x'] as num).toDouble();
          final y = (args['y'] as num).toDouble();
          // Input.dispatchMouseEvent 走 compositor 层，穿透 iframe/shadow DOM/跨域
          await _cdp.send('Input.dispatchMouseEvent', {
            'type': 'mousePressed', 'x': x, 'y': y,
            'button': 'left', 'clickCount': 1,
          });
          await _cdp.send('Input.dispatchMouseEvent', {
            'type': 'mouseReleased', 'x': x, 'y': y,
            'button': 'left', 'clickCount': 1,
          });
          return _ok('已点击坐标 ($x, $y)。💡 建议截图验证点击效果');

        case 'type_text':
          final selector = args['selector'] as String? ?? '';
          final text = args['text'] as String? ?? '';
          await _evalJs(
            'const el = document.querySelector(${jsonEncode(selector)}); '
            'if(el){el.focus(); el.value = ${jsonEncode(text)}; '
            'el.dispatchEvent(new Event("input",{bubbles:true}));}',
          );
          return _ok('已在 $selector 输入文字。💡 建议截图验证输入结果');

        case 'wait_for_load':
          await _cdp.waitForLoad();
          return _ok('页面已加载完成');

        case 'screenshot':
          // CDP 截图不需要窗口前台，直接从渲染引擎抓 bitmap
          final result = await _cdp.send('Page.captureScreenshot', {
            'format': 'jpeg',
            'quality': 85,
          });
          if (result['error'] != null) return _err(result['error']['message']);
          final data = result['result']['data'] as String;
          // 保存一份到本地（方便调试）
          final file = File('${Directory.systemTemp.path}/pa_screenshot.jpg');
          await file.writeAsBytes(base64Decode(data));
          // 同时把 base64 返给 LLM 走 vision 分析
          return jsonEncode({
            'status': 'ok',
            'image_base64': data,
            'path': file.path,
            'size_bytes': (data.length * 3) ~/ 4,
            'message': '截图已保存并传给视觉分析',
          });

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
