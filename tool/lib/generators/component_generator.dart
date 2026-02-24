import '../models/widget_doc.dart';

/// Generates Mintlify-compatible MDX content for a widget.
String generateComponentMdx(WidgetDoc doc) {
  final buffer = StringBuffer()
    // Frontmatter
    ..writeln('---')
    ..writeln('title: ${_formatTitle(doc.className)}')
    ..writeln('description: ${_escapeYaml(doc.description.split('\n').first)}')
    ..writeln('---')
    ..writeln()
    // Title and description
    ..writeln('# ${doc.className}')
    ..writeln()
    ..writeln(doc.description)
    ..writeln();

  // Variants section
  if (doc.variants.isNotEmpty) {
    buffer
      ..writeln('## Variants')
      ..writeln();
    for (final variant in doc.variants) {
      buffer.writeln('- $variant');
    }
    buffer.writeln();
  }

  // Features section
  if (doc.features.isNotEmpty) {
    buffer
      ..writeln('## Features')
      ..writeln()
      ..writeln('<CardGroup cols={2}>');
    for (final feature in doc.features) {
      final parts = feature.split(' - ');
      final title = parts.isNotEmpty ? parts[0].replaceAll('**', '') : feature;
      final description = parts.length > 1 ? parts.sublist(1).join(' - ') : '';
      buffer.writeln('  <Card title="$title">');
      if (description.isNotEmpty) {
        buffer.writeln('    $description');
      }
      buffer.writeln('  </Card>');
    }
    buffer
      ..writeln('</CardGroup>')
      ..writeln();
  }

  // Constructors section
  if (doc.constructors.isNotEmpty) {
    buffer
      ..writeln('## Constructors')
      ..writeln()
      ..writeln('<AccordionGroup>');
    for (final constructor in doc.constructors) {
      buffer.writeln('  <Accordion title="${constructor.name}">');
      if (constructor.description != null) {
        buffer.writeln('    ${constructor.description}');
      }
      buffer.writeln('  </Accordion>');
    }
    buffer
      ..writeln('</AccordionGroup>')
      ..writeln();
  }

  // Examples section
  if (doc.examples.isNotEmpty) {
    buffer
      ..writeln('## Examples')
      ..writeln();
    for (final example in doc.examples) {
      if (example.description != null) {
        buffer
          ..writeln(example.description)
          ..writeln();
      }
      buffer
        ..writeln('```dart')
        ..writeln(example.code)
        ..writeln('```')
        ..writeln();
    }
  }

  // Parameters section
  if (doc.parameters.isNotEmpty) {
    buffer
      ..writeln('## Parameters')
      ..writeln()
      ..writeln('<ResponseField name="Parameter" type="Type" required>')
      ..writeln('  Description')
      ..writeln('</ResponseField>')
      ..writeln();
    for (final param in doc.parameters) {
      buffer
        ..writeln(
          '<ResponseField name="${param.name}" type="${param.type}"'
          '${param.isRequired ? ' required' : ''}>',
        )
        ..writeln('  ${param.description ?? 'No description available.'}')
        ..writeln('</ResponseField>')
        ..writeln();
    }
  }

  return buffer.toString();
}

// Convert PascalCase to Title Case with spaces
String _formatTitle(String className) => className
    .replaceAllMapped(RegExp('([A-Z])'), (match) => ' ${match.group(1)}')
    .trim();

String _escapeYaml(String text) {
  if (text.contains(':') || text.contains('"') || text.contains("'")) {
    return '"${text.replaceAll('"', r'\"')}"';
  }
  return text;
}
