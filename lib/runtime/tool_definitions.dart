Map<String, dynamic> _tool(
  String name,
  String description,
  Map<String, dynamic> properties,
  List<String> required,
) => {
  'type': 'function',
  'function': {
    'name': name,
    'description': description,
    'parameters': {
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': false,
    },
  },
};
const _string = {'type': 'string'};
final agentTools = <Map<String, dynamic>>[
  _tool(
    'send_message',
    '向当前会话发送一条自然的纯文本消息，可以分条发送。发送成功的内容已对外可见。',
    {'text': _string},
    ['text'],
  ),
  _tool(
    'search_history',
    '在当前有权限参与的会话中关键词搜索；空关键词读取最近消息。',
    {'conversation_id': _string, 'query': _string},
    ['conversation_id', 'query'],
  ),
  _tool('search_memory', '关键词检索自己的记忆。', {'query': _string}, ['query']),
  _tool(
    'read_document',
    '读取自己的soul.md、memory.md或schedule.json及当前哈希。',
    {'name': _string},
    ['name'],
  ),
  _tool(
    'update_document',
    '按读取时的哈希更新自己的灵魂、记忆或结构化行程。行程正文为JSON数组，规则格式与读取结果一致。',
    {'name': _string, 'content': _string, 'expected_hash': _string},
    ['name', 'content', 'expected_hash'],
  ),
  _tool('finish', '结束本轮处理，允许不发言。', {}, []),
];
