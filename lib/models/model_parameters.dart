// ═══════════════════════════════════════════════════════════════
// 天枢 - 模型参数定义（对标 HermesApp StandardModelParameters）
// ═══════════════════════════════════════════════════════════════

/// 模型参数分类
enum ParameterCategory { generation, creativity, repetition, other }

/// 模型参数值类型
enum ParameterValueType { integer, float, boolean, string }

/// 单个模型参数定义
class ModelParamDef {
  final String id;
  final String name;
  final String apiName;
  final String description;
  final double defaultValue;
  final double currentValue;
  final bool isEnabled;
  final ParameterValueType valueType;
  final double minValue;
  final double maxValue;
  final ParameterCategory category;

  const ModelParamDef({
    required this.id,
    required this.name,
    required this.apiName,
    this.description = '',
    required this.defaultValue,
    this.currentValue = 0,
    this.isEnabled = false,
    required this.valueType,
    this.minValue = 0,
    this.maxValue = 100,
    this.category = ParameterCategory.other,
  });

  ModelParamDef copyWith({double? currentValue, bool? isEnabled}) {
    return ModelParamDef(
      id: id,
      name: name,
      apiName: apiName,
      description: description,
      defaultValue: defaultValue,
      currentValue: currentValue ?? this.currentValue,
      isEnabled: isEnabled ?? this.isEnabled,
      valueType: valueType,
      minValue: minValue,
      maxValue: maxValue,
      category: category,
    );
  }
}

/// 标准模型参数集
class StandardModelParameters {
  static const List<ModelParamDef> definitions = [
    ModelParamDef(
      id: 'max_tokens',
      name: 'Max Tokens',
      apiName: 'max_tokens',
      description: '单次生成的最大 token 数量',
      defaultValue: 4096,
      currentValue: 4096,
      isEnabled: false,
      valueType: ParameterValueType.integer,
      minValue: 1,
      maxValue: 128000,
      category: ParameterCategory.generation,
    ),
    ModelParamDef(
      id: 'temperature',
      name: 'Temperature',
      apiName: 'temperature',
      description: '控制随机性：越低越确定，越高越随机',
      defaultValue: 1.0,
      currentValue: 1.0,
      isEnabled: false,
      valueType: ParameterValueType.float,
      minValue: 0,
      maxValue: 2,
      category: ParameterCategory.creativity,
    ),
    ModelParamDef(
      id: 'top_p',
      name: 'Top-p',
      apiName: 'top_p',
      description: '核采样：只考虑累积概率 top-p 内的 token',
      defaultValue: 1.0,
      currentValue: 1.0,
      isEnabled: false,
      valueType: ParameterValueType.float,
      minValue: 0,
      maxValue: 1,
      category: ParameterCategory.creativity,
    ),
    ModelParamDef(
      id: 'top_k',
      name: 'Top-k',
      apiName: 'top_k',
      description: '只考虑概率最高的 top-k 个 token，0 表示禁用',
      defaultValue: 0,
      currentValue: 0,
      isEnabled: false,
      valueType: ParameterValueType.integer,
      minValue: 0,
      maxValue: 100,
      category: ParameterCategory.creativity,
    ),
    ModelParamDef(
      id: 'presence_penalty',
      name: 'Presence Penalty',
      apiName: 'presence_penalty',
      description: '惩罚已出现的 token，鼓励讨论新话题',
      defaultValue: 0,
      currentValue: 0,
      isEnabled: false,
      valueType: ParameterValueType.float,
      minValue: -2,
      maxValue: 2,
      category: ParameterCategory.repetition,
    ),
    ModelParamDef(
      id: 'frequency_penalty',
      name: 'Frequency Penalty',
      apiName: 'frequency_penalty',
      description: '根据 token 频率进行惩罚，减少重复',
      defaultValue: 0,
      currentValue: 0,
      isEnabled: false,
      valueType: ParameterValueType.float,
      minValue: -2,
      maxValue: 2,
      category: ParameterCategory.repetition,
    ),
    ModelParamDef(
      id: 'repetition_penalty',
      name: 'Repetition Penalty',
      apiName: 'repetition_penalty',
      description: '进一步减少重复：1.0 表示无惩罚',
      defaultValue: 1.0,
      currentValue: 1.0,
      isEnabled: false,
      valueType: ParameterValueType.float,
      minValue: 0,
      maxValue: 2,
      category: ParameterCategory.repetition,
    ),
  ];
}
