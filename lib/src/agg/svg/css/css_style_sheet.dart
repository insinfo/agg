import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as css_visitor;

class CssStyleSheet {
  final Map<String, Map<String, String>> rules = {};

  void parse(String cssText) {
    final stylesheet = css.parse(cssText);

    for (final node in stylesheet.topLevels) {
      if (node is css_visitor.RuleSet) {
        final properties = <String, String>{};

        for (final decl in node.declarationGroup.declarations) {
          if (decl is css_visitor.Declaration) {
            properties[decl.property] = _expressionToString(decl.expression);
          }
        }

        for (final selector in node.selectorGroup!.selectors) {
          String selectorStr = selector.span!.text.trim();
          selectorStr = selectorStr.replaceAll(RegExp(r'\s+'), ' ');

          if (rules.containsKey(selectorStr)) {
            rules[selectorStr]!.addAll(properties);
          } else {
            rules[selectorStr] = Map.from(properties);
          }
        }
      }
    }
  }

  String _expressionToString(css_visitor.TreeNode? expr) {
    if (expr == null) return '';
    return expr.span!.text;
  }

  Map<String, String> getStyle(String tagName, String? id, String? className) {
    final result = <String, String>{};

    // Tag
    if (rules.containsKey(tagName)) {
      result.addAll(rules[tagName]!);
    }

    // Class
    if (className != null) {
      for (final c in className.split(' ')) {
        if (c.isEmpty) continue;
        final selector = '.$c';
        if (rules.containsKey(selector)) {
          result.addAll(rules[selector]!);
        }
        final tagClass = '$tagName.$c';
        if (rules.containsKey(tagClass)) {
          result.addAll(rules[tagClass]!);
        }
      }
    }

    // ID
    if (id != null) {
      final selector = '#$id';
      if (rules.containsKey(selector)) {
        result.addAll(rules[selector]!);
      }
    }

    return result;
  }
}
