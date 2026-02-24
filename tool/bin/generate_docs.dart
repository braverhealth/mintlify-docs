import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/generators/component_generator.dart';
import '../lib/generators/token_generator.dart';
import '../lib/parsers/dart_doc_parser.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: '../',
      help: 'Output directory for generated docs',
    )
    ..addFlag(
      'components',
      defaultsTo: true,
      help: 'Generate component documentation',
    )
    ..addFlag(
      'tokens',
      defaultsTo: true,
      help: 'Generate design token documentation',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    );

  final results = parser.parse(args);

  if (results['help'] as bool) {
    stdout
      ..writeln('Usage: dart run bin/generate_docs.dart [options]')
      ..writeln(parser.usage);
    exit(0);
  }

  final outputDir = results['output'] as String;
  final generateComponents = results['components'] as bool;
  final generateTokens = results['tokens'] as bool;

  stdout
    ..writeln('🚀 Braver Flutter UI Documentation Generator')
    ..writeln();

  final flutterUiLib = path.normalize(
    path.join(Directory.current.path, '../../lib'),
  );
  final designTokensLib = path.normalize(
    path.join(Directory.current.path, '../../../design_tokens/lib'),
  );

  if (generateComponents) {
    stdout.writeln('📦 Generating component documentation...');
    await generateComponentDocs(flutterUiLib, outputDir);
  }

  if (generateTokens) {
    stdout.writeln('🎨 Generating design token documentation...');
    await generateTokenDocs(designTokensLib, flutterUiLib, outputDir);
  }

  stdout
    ..writeln()
    ..writeln('✅ Documentation generation complete!');
}

Future<void> generateComponentDocs(String libPath, String outputDir) async {
  final componentsPath = path.join(libPath, 'src', 'components');
  final componentsDir = Directory(componentsPath);

  if (!componentsDir.existsSync()) {
    stdout.writeln('  ⚠️  Components directory not found: $componentsPath');
    return;
  }

  final categories = componentsDir.listSync().whereType<Directory>();

  for (final categoryDir in categories) {
    final categoryName = path.basename(categoryDir.path);
    final dartFiles = categoryDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.dart'),
    );

    for (final file in dartFiles) {
      final fileName = path.basenameWithoutExtension(file.path);
      if (fileName.startsWith('_') || fileName == categoryName) continue;

      try {
        final widgetDoc = await parseWidgetFile(file.path);
        if (widgetDoc != null) {
          final mdxContent = generateComponentMdx(widgetDoc);
          final outputPath = path.join(
            outputDir,
            'components',
            categoryName,
            '$fileName.mdx',
          );
          await _writeFile(outputPath, mdxContent);
          stdout.writeln(
            '  ✓ Generated: components/$categoryName/$fileName.mdx',
          );
        }
      } catch (e) {
        stdout.writeln('  ⚠️  Error parsing ${file.path}: $e');
      }
    }
  }
}

Future<void> generateTokenDocs(
  String designTokensPath,
  String flutterUiPath,
  String outputDir,
) async {
  final tokenTypes = [
    'colors',
    'typography',
    'spacing',
    'borders',
    'shadows',
    'animation',
  ];

  for (final tokenType in tokenTypes) {
    try {
      final mdxContent = await generateTokenMdx(
        tokenType,
        designTokensPath,
        flutterUiPath,
      );
      final outputPath = path.join(
        outputDir,
        'tokens',
        tokenType,
        'overview.mdx',
      );
      await _writeFile(outputPath, mdxContent);
      stdout.writeln('  ✓ Generated: tokens/$tokenType/overview.mdx');
    } catch (e) {
      stdout.writeln('  ⚠️  Error generating $tokenType tokens: $e');
    }
  }
}

Future<void> _writeFile(String filePath, String content) async {
  final file = File(filePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
