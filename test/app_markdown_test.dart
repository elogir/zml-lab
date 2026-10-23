import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/core/widgets/app_markdown.dart';

Widget _host(String markdown, AppColors colors) => Directionality(
  textDirection: TextDirection.ltr,
  child: AppTheme(
    colors: colors,
    child: SizedBox(width: 600, child: AppMarkdown(markdown)),
  ),
);

void main() {
  for (final colors in [AppColors.dark, AppColors.light]) {
    testWidgets('table header uses the ${colors.brightness.name} palette', (
      tester,
    ) async {
      // Left to the package it was Material's light default even in dark
      // mode: a bright bar across every table.
      await tester.pumpWidget(
        _host('| a | \$x^2\$ |\n|---|---|\n| 1 | 2 |', colors),
      );
      final header = tester.widget<Table>(find.byType(Table)).children.first;
      expect(
        (header.decoration! as BoxDecoration).color,
        colors.surfaceSelected,
      );
    });
  }

  // Shapes models actually emit; each must render as math without throwing
  // (a throwing widget paints a blank box in release builds).
  const math = <String>[
    r'Inline $x^2 + y^2 = z^2$ and display:',
    r'$$\int_0^1 f(x)\,dx$$',
    '\$\$\n\\begin{aligned}\nx &= 1 \\\\\ny &= 2\n\\end{aligned}\n\$\$',
    r'\[ \operatorname{softmax}(z)_i = \frac{e^{z_i}}{\sum_j e^{z_j}} \]',
    r'Inline \( \alpha + \beta \).',
    r'$$f(x) = \begin{cases} 1 & x > 0 \\ 0 & \text{else} \end{cases}$$',
    r'$$\begin{pmatrix} 1 & 2 \\ 3 & 4 \end{pmatrix}$$',
    r'$$\left( \frac{1}{2} \right.$$',
    r'$$\frac{a',
    r'Prices: $5 and $10.',
  ];
  for (final (i, sample) in math.indexed) {
    testWidgets('math sample $i renders', (tester) async {
      await tester.pumpWidget(_host(sample, AppColors.dark));
      expect(tester.takeException(), isNull);
    });
  }
}
