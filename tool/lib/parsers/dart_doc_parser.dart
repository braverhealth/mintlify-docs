import 'dart:io';

import '../models/widget_doc.dart';

/// Parses a Dart file and extracts widget documentation.
Future<WidgetDoc?> parseWidgetFile(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) return null;

  final content = await file.readAsString();
  final className = _extractClassName(content);
  if (className == null) return null;

  final docComment = _extractClassDocComment(content, className);
  if (docComment == null) return null;

  return WidgetDoc(
    className: className,
    description: _extractDescription(docComment),
    variants: _extractSection(docComment, 'Variants'),
    features: _extractSection(docComment, 'Features'),
    examples: _extractExamples(docComment),
    parameters: _extractParameters(content, className),
    constructors: _extractConstructors(content, className),
  );
}

String? _extractClassName(String content) {
  final classMatch = RegExp(r'class\s+(\w+)\s+extends').firstMatch(content);
  return classMatch?.group(1);
}

String? _extractClassDocComment(String content, String className) {
  final pattern = RegExp(
    r'((?:\/\/\/[^\n]*\n)+)\s*class\s+' + className,
    multiLine: true,
  );
  final match = pattern.firstMatch(content);
  if (match == null) return null;

  return match
      .group(1)
      ?.split('\n')
      .map((line) => line.replaceFirst(RegExp(r'^\s*\/\/\/\s?'), ''))
      .join('\n')
      .trim();
}

String _extractDescription(String docComment) {
  final lines = docComment.split('\n');
  final descriptionLines = <String>[];

  for (final line in lines) {
    if (line.startsWith('##') || line.startsWith('```')) break;
    descriptionLines.add(line);
  }

  return descriptionLines.join('\n').trim();
}

List<String> _extractSection(String docComment, String sectionName) {
  final pattern = RegExp(
    r'##\s+' + sectionName + r'\s*\n([\s\S]*?)(?=\n##|\n```|\Z)',
    multiLine: true,
  );
  final match = pattern.firstMatch(docComment);
  if (match == null) return [];

  final sectionContent = match.group(1) ?? '';
  return sectionContent
      .split('\n')
      .where(
        (line) => line.trim().startsWith('-') || line.trim().startsWith('*'),
      )
      .map((line) => line.replaceFirst(RegExp(r'^\s*[-*]\s*'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

List<CodeExample> _extractExamples(String docComment) {
  final examples = <CodeExample>[];
  final pattern = RegExp(r'```dart\n([\s\S]*?)```', multiLine: true);

  for (final match in pattern.allMatches(docComment)) {
    final code = match.group(1)?.trim() ?? '';
    if (code.isNotEmpty) {
      examples.add(CodeExample(code: code));
    }
  }

  return examples;
}

List<ParameterDoc> _extractParameters(String content, String className) {
  final parameters = <ParameterDoc>[];

  // Match constructor parameters with doc comments
  final constructorPattern = RegExp(
    className + r'\s*\(\s*\{([^}]*)\}',
    dotAll: true,
  );
  final match = constructorPattern.firstMatch(content);
  if (match == null) return parameters;

  final paramsBlock = match.group(1) ?? '';
  final paramPattern = RegExp(
    r'(?:\/\/\/\s*([^\n]*)\n\s*)?(?:required\s+)?(\w+(?:<[^>]+>)?)\s+(\w+)',
  );

  for (final paramMatch in paramPattern.allMatches(paramsBlock)) {
    parameters.add(
      ParameterDoc(
        name: paramMatch.group(3) ?? '',
        type: paramMatch.group(2) ?? '',
        description: paramMatch.group(1),
        isRequired: paramsBlock.contains(
          'required ${paramMatch.group(2)} ${paramMatch.group(3)}',
        ),
      ),
    );
  }

  return parameters;
}

List<ConstructorDoc> _extractConstructors(String content, String className) {
  final constructors = <ConstructorDoc>[];

  // Match named constructors with doc comments
  final pattern = RegExp(
    r'((?:\/\/\/[^\n]*\n)+)?\s*' + className + r'\.(\w+)\s*\(',
  );

  for (final match in pattern.allMatches(content)) {
    final docComment = match
        .group(1)
        ?.split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*\/\/\/\s?'), ''))
        .join('\n')
        .trim();

    constructors.add(
      ConstructorDoc(
        name: '$className.${match.group(2)}',
        description: docComment,
      ),
    );
  }

  return constructors;
}
