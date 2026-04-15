import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'skill_model.dart';
import '../cdp_client.dart';

/// Executes a Skill step-by-step against a CDP browser session.
class SkillRunner {
  final CdpClient cdp;
  final Map<String, dynamic> _vars = {};

  SkillRunner(this.cdp);

  /// Run a skill with given parameters. Returns final result.
  Future<String> run(Skill skill, Map<String, dynamic> params) async {
    // Load params into variables
    for (final p in skill.params) {
      _vars[p.name] = params[p.name] ?? p.defaultValue ?? '';
    }

    String lastResult = '';

    for (var i = 0; i < skill.steps.length; i++) {
      final step = skill.steps[i];
      debugPrint('[Skill] Step $i: ${step.action} ${step.args}');

      try {
        lastResult = await _executeStep(step);
        debugPrint('[Skill] Step $i result: ${lastResult.length > 100 ? '${lastResult.substring(0, 100)}...' : lastResult}');
      } catch (e) {
        return jsonEncode({
          'status': 'error',
          'step': i,
          'action': step.action,
          'message': '$e',
        });
      }
    }

    return lastResult;
  }

  /// Resolve {{var}} placeholders in a string.
  String _resolve(String template) {
    return template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (m) => _vars[m.group(1)]?.toString() ?? m.group(0)!,
    );
  }

  String _resolveArg(Map<String, dynamic> args, String key, [String fallback = '']) {
    final val = args[key];
    if (val == null) return fallback;
    return _resolve(val.toString());
  }

  Future<String> _executeStep(SkillStep step) async {
    switch (step.action) {
      case 'navigate':
        final url = _resolveArg(step.args, 'url');
        await cdp.send('Page.navigate', {'url': url});
        await Future.delayed(const Duration(seconds: 1));
        return jsonEncode({'status': 'ok', 'url': url});

      case 'wait':
        final seconds = step.args['seconds'] as int? ?? 1;
        await Future.delayed(Duration(seconds: seconds));
        return jsonEncode({'status': 'ok', 'waited': seconds});

      case 'query':
        final selector = _resolveArg(step.args, 'selector');
        final saveAs = step.args['save_as'] as String?;
        final result = await _evalJs(
          '(() => { const el = document.querySelector(${jsonEncode(selector)}); '
          'if (!el) return null; '
          'return { tag: el.tagName, id: el.id, text: el.innerText?.substring(0, 200), '
          'value: el.value, href: el.href }; })()',
        );
        if (saveAs != null) _vars[saveAs] = selector; // save selector for later use
        return result;

      case 'query_all':
        final selector = _resolveArg(step.args, 'selector');
        final saveAs = step.args['save_as'] as String?;
        final limit = step.args['limit'] as int? ?? 10;
        final result = await _evalJs(
          '(() => { const els = document.querySelectorAll(${jsonEncode(selector)}); '
          'return Array.from(els).slice(0, $limit).map((el, i) => ({ '
          'index: i, tag: el.tagName, text: el.innerText?.substring(0, 100), '
          'id: el.id, href: el.href })); })()',
        );
        if (saveAs != null) _vars[saveAs] = result;
        return result;

      case 'query_text':
        final text = _resolveArg(step.args, 'text');
        final saveAs = step.args['save_as'] as String?;
        final result = await _evalJs(
          '(() => { const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); '
          'while (walker.nextNode()) { '
          'if (walker.currentNode.textContent.includes(${jsonEncode(text)})) { '
          'const el = walker.currentNode.parentElement; '
          'return { tag: el.tagName, text: el.innerText?.substring(0, 200), id: el.id }; }} '
          'return null; })()',
        );
        if (saveAs != null) _vars[saveAs] = text;
        return result;

      case 'click':
        final selector = _resolveArg(step.args, 'selector');
        await _evalJs('document.querySelector(${jsonEncode(selector)})?.click()');
        return jsonEncode({'status': 'ok', 'clicked': selector});

      case 'click_text':
        final text = _resolveArg(step.args, 'text');
        await _evalJs(
          '(() => { const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); '
          'while (walker.nextNode()) { '
          'if (walker.currentNode.textContent.includes(${jsonEncode(text)})) { '
          'walker.currentNode.parentElement.click(); return true; }} return false; })()',
        );
        return jsonEncode({'status': 'ok', 'clicked_text': text});

      case 'type_text':
        final selector = _resolveArg(step.args, 'selector');
        final text = _resolveArg(step.args, 'text');
        await _evalJs(
          'const el = document.querySelector(${jsonEncode(selector)}); '
          'if(el){el.focus(); el.value = ${jsonEncode(text)}; '
          'el.dispatchEvent(new Event("input",{bubbles:true})); '
          'el.dispatchEvent(new Event("change",{bubbles:true}));}',
        );
        return jsonEncode({'status': 'ok', 'typed': text});

      case 'press_key':
        final key = _resolveArg(step.args, 'key');
        await cdp.send('Input.dispatchKeyEvent', {
          'type': 'keyDown',
          'key': key,
          if (key == 'Enter') 'code': 'Enter',
          if (key == 'Tab') 'code': 'Tab',
        });
        await cdp.send('Input.dispatchKeyEvent', {'type': 'keyUp', 'key': key});
        return jsonEncode({'status': 'ok', 'key': key});

      case 'get_text':
        final selector = _resolveArg(step.args, 'selector');
        final saveAs = step.args['save_as'] as String?;
        final result = await _evalJs(
          'document.querySelector(${jsonEncode(selector)})?.innerText ?? ""',
        );
        if (saveAs != null) _vars[saveAs] = result;
        return result;

      case 'execute_js':
        final expr = _resolveArg(step.args, 'expression');
        return await _evalJs(expr);

      case 'save':
        final key = step.args['key'] as String;
        final value = _resolveArg(step.args, 'value');
        _vars[key] = value;
        return jsonEncode({'status': 'ok', 'saved': key});

      case 'return':
        final value = _resolveArg(step.args, 'value');
        return jsonEncode({'status': 'ok', 'result': value});

      default:
        return jsonEncode({'status': 'error', 'message': '未知 step action: ${step.action}'});
    }
  }

  Future<String> _evalJs(String expression) async {
    final result = await cdp.send('Runtime.evaluate', {
      'expression': expression,
      'returnByValue': true,
    });
    if (result['error'] != null) throw Exception(result['error']['message']);
    final val = result['result']?['result'];
    if (val == null || val['type'] == 'undefined') return 'null';
    if (val['value'] == null) return 'null';
    final v = val['value'];
    return v is String ? v : jsonEncode(v);
  }
}
