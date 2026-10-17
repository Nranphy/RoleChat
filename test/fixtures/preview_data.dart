import 'package:rolechat/models/preview_models.dart';

/// Fresh sample objects for each store, never shared mutable application state.
abstract final class PreviewData {
  static List<ApiProfile> apis() => [
    ApiProfile(
      id: '44444444-4444-4444-8444-444444444444',
      name: '我的模型接口',
      url: 'https://api.example.com/v1',
      models: {'gpt-4o': ModelSettings()},
    ),
  ];
  static List<RoleProfile> roles() => [
    RoleProfile(
      id: '11111111-1111-4111-8111-111111111111',
      name: '林间',
      model: 'gpt-4o',
      memory: '你喜欢安静的咖啡店，最好能坐在窗边。\n\n约好了周六下午和月白、夏芽一起去花店。',
      identity: '你是林间，一个喜欢植物、散步和手写信的朋友。说话温和自然，留意生活里的细节。',
      soul: '最近学会了不急着给每件事一个答案。比起计划好的旅程，更喜欢偶然遇到的小风景。',
      examples: [
        {'question': '今天有点累。', 'answer': '那就先把今天放一放吧。要不要一起坐在窗边，看一会儿树影？'},
      ],
    ),
    RoleProfile(
      id: '22222222-2222-4222-8222-222222222222',
      name: '月白',
      model: 'gpt-4o',
      memory: '一起看电影的时候，喜欢留下片尾曲。',
      identity: '你是月白，喜欢电影和城市夜晚的大学生。幽默、坦率，偶尔带一点诗意。',
      soul: '觉得朋友之间最珍贵的，是可以安心地沉默。想把这座城市的深夜都记下来。',
    ),
    RoleProfile(
      id: '33333333-3333-4333-8333-333333333333',
      name: '夏芽',
      model: 'gpt-4o',
      identity: '你是夏芽，热爱咖啡、拍照和周末探店。表达活泼，但尊重朋友的节奏。',
      soul: '想把每一个普通的周末变成值得期待的小冒险。',
    ),
  ];
  static List<Conversation> conversations() => [
    Conversation(
      id: '55555555-5555-4555-8555-555555555555',
      name: '周末小花园',

      members: [
        '11111111-1111-4111-8111-111111111111',
        '22222222-2222-4222-8222-222222222222',
        '33333333-3333-4333-8333-333333333333',
      ],
      group: true,
      messages: [
        ChatMessage(
          id: 'm1',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '刚刚路过花店，发现第一批洋甘菊开了。\n这个周末，要不要一起去走走？',
          time: '16:38',
        ),
        ChatMessage(
          id: 'm1b',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '花店就在河边那条路上。',
          time: '16:38',
        ),
        ChatMessage(
          id: 'm1c',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '走过去大概十分钟。',
          time: '16:38',
        ),
        ChatMessage(
          id: 'm2',
          roleId: '33333333-3333-4333-8333-333333333333',
          text: '我要去！\n顺便找到一家有花园的咖啡店，窗边的位置特别好看。',
          time: '16:39',
        ),
        ChatMessage(
          id: 'm2b',
          roleId: '33333333-3333-4333-8333-333333333333',
          text: '我还想看看他们家的蛋糕。',
          time: '16:39',
        ),
        ChatMessage(
          id: 'm2c',
          roleId: '33333333-3333-4333-8333-333333333333',
          text: '到时候拍张照片给你们。',
          time: '16:39',
        ),
        ChatMessage(id: 'm3', text: '听起来很棒。周六下午怎么样？', time: '16:40'),
        ChatMessage(
          id: 'm4',
          roleId: '22222222-2222-4222-8222-222222222222',
          text: '我带相机。希望那天有一点阳光，\n也有足够多的时间可以浪费。',
          time: '16:41',
          reply: const MessageReference(
            messageId: 'm3',
            text: '周六下午怎么样？',
            senderName: '你',
          ),
        ),
        ChatMessage(
          id: 'm5',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '那就说好了。不用安排太满，\n我们慢慢走。',
          time: '16:42',
        ),
      ],
    ),
    Conversation(
      id: '66666666-6666-4666-8666-666666666666',
      name: '林间',

      members: ['11111111-1111-4111-8111-111111111111'],
      messages: [
        ChatMessage(
          id: 'p1',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '今天给窗台的小植物换了个位置。\n它好像比昨天精神了一点。',
          time: '15:20',
        ),
        ChatMessage(
          id: 'p1b',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '现在下午的阳光正好能照到它。',
          time: '15:20',
        ),
        ChatMessage(
          id: 'p1c',
          roleId: '11111111-1111-4111-8111-111111111111',
          text: '等长出新叶子再给你看。',
          time: '15:21',
        ),
      ],
    ),
    Conversation(
      id: '77777777-7777-4777-8777-777777777777',
      name: '月白',

      members: ['22222222-2222-4222-8222-222222222222'],
      messages: [
        ChatMessage(
          id: 'p2',
          roleId: '22222222-2222-4222-8222-222222222222',
          text: '留了一部电影，等你有空一起看。',
          time: '昨天',
        ),
      ],
    ),
    Conversation(
      id: '88888888-8888-4888-8888-888888888888',
      name: '夏芽',

      members: ['33333333-3333-4333-8333-333333333333'],
      messages: [],
    ),
  ];
  static List<ScheduleEntry> schedules() => [
    ScheduleEntry(
      id: 's1',
      roleId: '11111111-1111-4111-8111-111111111111',
      activity: '睡觉',
      start: '23:00',
      end: '08:00',
      probability: 0,
    ),
    ScheduleEntry(
      id: 's2',
      roleId: '11111111-1111-4111-8111-111111111111',
      activity: '上课',
      ruleKind: ScheduleRuleKind.weekly,
      weekdays: [1, 2, 3, 4, 5],
      start: '09:00',
      end: '12:00',
      probability: 20,
    ),
    ScheduleEntry(
      id: 's3',
      roleId: '11111111-1111-4111-8111-111111111111',
      activity: '散步与聊天',
      start: '16:00',
      end: '19:00',
      probability: 100,
    ),
  ];
}
