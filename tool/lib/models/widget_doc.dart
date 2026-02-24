/// Represents extracted documentation for a widget.
class WidgetDoc {
  WidgetDoc({
    required this.className,
    required this.description,
    this.variants = const [],
    this.features = const [],
    this.examples = const [],
    this.parameters = const [],
    this.constructors = const [],
  });

  final String className;
  final String description;
  final List<String> variants;
  final List<String> features;
  final List<CodeExample> examples;
  final List<ParameterDoc> parameters;
  final List<ConstructorDoc> constructors;
}

/// Represents a code example from doc comments.
class CodeExample {
  CodeExample({required this.code, this.description});

  final String code;
  final String? description;
}

/// Represents a documented parameter.
class ParameterDoc {
  ParameterDoc({
    required this.name,
    required this.type,
    this.description,
    this.isRequired = false,
    this.defaultValue,
  });

  final String name;
  final String type;
  final String? description;
  final bool isRequired;
  final String? defaultValue;
}

/// Represents a documented constructor.
class ConstructorDoc {
  ConstructorDoc({
    required this.name,
    this.description,
    this.parameters = const [],
  });

  final String name;
  final String? description;
  final List<ParameterDoc> parameters;
}

/// Represents a design token accessor.
class TokenAccessorDoc {
  TokenAccessorDoc({
    required this.name,
    required this.type,
    this.description,
    this.isAdaptive = false,
    this.lightValue,
    this.darkValue,
  });

  final String name;
  final String type;
  final String? description;
  final bool isAdaptive;
  final String? lightValue;
  final String? darkValue;
}
