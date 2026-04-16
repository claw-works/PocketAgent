/// Base class for all PocketAgent tools.
/// Each tool maps to an OpenAI function_call definition.
abstract class BaseTool {
  String get name;
  String get description;

  /// JSON Schema for parameters, used in OpenAI tools definition.
  Map<String, dynamic> get parameters;

  /// Whether this tool requires user confirmation before execution.
  bool get requiresConfirmation => false;

  /// Execute the tool with given arguments, return result string.
  Future<String> execute(Map<String, dynamic> args);

  /// Convert to OpenAI function tool format.
  Map<String, dynamic> toOpenAI() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}
