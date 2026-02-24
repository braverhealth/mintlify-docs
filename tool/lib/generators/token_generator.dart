import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Generates Mintlify-compatible MDX content for design tokens.
Future<String> generateTokenMdx(
  String tokenType,
  String designTokensPath,
  String flutterUiPath,
) async {
  switch (tokenType) {
    case 'colors':
      return _generateColorTokensMdx(designTokensPath, flutterUiPath);
    case 'typography':
      return _generateTypographyTokensMdx(designTokensPath);
    case 'spacing':
      return _generateSpacingTokensMdx(designTokensPath);
    case 'borders':
      return _generateBorderTokensMdx(designTokensPath);
    case 'shadows':
      return _generateShadowTokensMdx(designTokensPath);
    case 'animation':
      return _generateAnimationTokensMdx(designTokensPath);
    default:
      throw ArgumentError('Unknown token type: $tokenType');
  }
}

Future<String> _generateColorTokensMdx(
  String designTokensPath,
  String flutterUiPath,
) async {
  final yamlPath = path.join(
    path.dirname(designTokensPath),
    'tokens',
    'colors.yaml',
  );
  final yamlFile = File(yamlPath);

  final buffer = StringBuffer()
    ..writeln('---')
    ..writeln('title: Colors')
    ..writeln('description: Color tokens for the Braver design system')
    ..writeln('---')
    ..writeln()
    ..writeln('# Color Tokens')
    ..writeln()
    ..writeln(
      'Colors are organized into semantic categories. Most colors are '
      'adaptive, meaning they automatically adjust for light and dark modes.',
    )
    ..writeln()
    ..writeln('## Accessing Colors')
    ..writeln()
    ..writeln('```dart')
    ..writeln('// Access via context extension')
    ..writeln('final colors = context.getColors();')
    ..writeln()
    ..writeln('// Use semantic color getters')
    ..writeln('Container(')
    ..writeln('  color: colors.backgroundPrimary,')
    ..writeln('  child: Text(')
    ..writeln("    'Hello',")
    ..writeln('    style: TextStyle(color: colors.text),')
    ..writeln('  ),')
    ..writeln(')')
    ..writeln('```')
    ..writeln();

  if (yamlFile.existsSync()) {
    final yamlContent = await yamlFile.readAsString();
    final yaml = loadYaml(yamlContent) as YamlMap;

    for (final category in yaml.keys) {
      buffer
        ..writeln('## ${_formatCategoryTitle(category.toString())}')
        ..writeln();

      final categoryData = yaml[category];
      if (categoryData is YamlMap) {
        buffer.writeln('<CardGroup cols={2}>');
        for (final colorName in categoryData.keys) {
          final colorData = categoryData[colorName];
          final isAdaptive =
              colorData is YamlMap && colorData.containsKey('dark');

          buffer
            ..writeln(
              '  <Card title="${_formatColorName(colorName.toString())}">',
            )
            ..writeln(
              '    **Accessor:** '
              '`colors.$category${_capitalize(colorName.toString())}`',
            );
          if (isAdaptive) {
            buffer
              ..writeln('    ')
              ..writeln('    Adaptive: Light/Dark variants');
          }
          buffer.writeln('  </Card>');
        }
        buffer
          ..writeln('</CardGroup>')
          ..writeln();
      }
    }
  }

  return buffer.toString();
}

Future<String> _generateTypographyTokensMdx(String designTokensPath) async =>
    '''
---
title: Typography
description: Typography tokens for the Braver design system
---

# Typography Tokens

Typography tokens define font families, sizes, weights, and line heights used throughout the application.

## Accessing Typography

```dart
// Use BraverTypography widgets
BraverTypography.heading1('Title');
BraverTypography.body('Body text');
BraverTypography.caption('Caption');
```

## Text Styles

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| heading1 | 24px | Bold | Page titles |
| heading2 | 20px | SemiBold | Section headers |
| heading3 | 18px | SemiBold | Subsections |
| body | 16px | Regular | Body text |
| bodySmall | 14px | Regular | Secondary text |
| caption | 12px | Regular | Labels, hints |
''';

Future<String> _generateSpacingTokensMdx(String designTokensPath) async => '''
---
title: Spacing
description: Spacing tokens for consistent layout
---

# Spacing Tokens

Spacing tokens ensure consistent margins, padding, and gaps throughout the UI.

## Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight spacing |
| sm | 8px | Small spacing |
| md | 16px | Default spacing |
| lg | 24px | Large spacing |
| xl | 32px | Extra large spacing |
| xxl | 48px | Section spacing |
''';

Future<String> _generateBorderTokensMdx(String designTokensPath) async => '''
---
title: Borders
description: Border tokens for consistent styling
---

# Border Tokens

Border tokens define widths, radii, and styles for consistent border styling.

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| none | 0px | No rounding |
| sm | 4px | Subtle rounding |
| md | 8px | Default rounding |
| lg | 12px | Cards, containers |
| xl | 16px | Large elements |
| full | 9999px | Circular/pill shapes |
''';

Future<String> _generateShadowTokensMdx(String designTokensPath) async => '''
---
title: Shadows
description: Shadow tokens for elevation
---

# Shadow Tokens

Shadow tokens provide consistent elevation and depth throughout the UI.

## Elevation Levels

| Level | Usage |
|-------|-------|
| none | Flat elements |
| sm | Subtle lift (buttons) |
| md | Cards, dropdowns |
| lg | Modals, dialogs |
''';

Future<String> _generateAnimationTokensMdx(String designTokensPath) async => '''
---
title: Animation
description: Animation tokens for motion design
---

# Animation Tokens

Animation tokens define durations and easing curves for consistent motion.

## Durations

| Token | Value | Usage |
|-------|-------|-------|
| instant | 0ms | Immediate |
| fast | 150ms | Micro-interactions |
| normal | 300ms | Standard transitions |
| slow | 500ms | Complex animations |

## Easing Curves

| Curve | Usage |
|-------|-------|
| easeIn | Elements entering |
| easeOut | Elements exiting |
| easeInOut | State changes |
''';

String _formatCategoryTitle(String category) => category
    .replaceAllMapped(RegExp('([A-Z])'), (match) => ' ${match.group(1)}')
    .trim()
    .split(' ')
    .map(_capitalize)
    .join(' ');

String _formatColorName(String name) => name
    .replaceAllMapped(RegExp('([A-Z])'), (match) => ' ${match.group(1)}')
    .trim();

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
