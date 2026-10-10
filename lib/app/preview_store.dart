import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/app_theme.dart';
import '../models/preview_models.dart';

class PreviewStore extends ChangeNotifier {
  PreviewStore(this.preferences);
  final SharedPreferences preferences;
  int destination = 0;
  String selectedId = 'garden';
  bool showChatOnMobile = false;
  ThemeMode get mode => ThemeMode.values[preferences.getInt('themeMode') ?? 0];
  Color get seed =>
      Color(preferences.getInt('seed') ?? AppTheme.seeds.first.toARGB32());
  Future<void> setMode(ThemeMode value) async {
    await preferences.setInt('themeMode', value.index);
    notifyListeners();
  }

  Future<void> setSeed(Color value) async {
    await preferences.setInt('seed', value.toARGB32());
    notifyListeners();
  }

  void changed() => notifyListeners();
  void navigate(int value) {
    destination = value;
    showChatOnMobile = false;
    notifyListeners();
  }

  void select(String id) {
    selectedId = id;
    destination = 0;
    showChatOnMobile = true;
    conversations.firstWhere((c) => c.id == id).unread = 0;
    notifyListeners();
  }

  Conversation get selected => conversations.firstWhere(
    (c) => c.id == selectedId,
    orElse: () => conversations.first,
  );
  RoleProfile role(String id) => roles.firstWhere((r) => r.id == id);
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();
  void send(String text, {String? reply}) {
    if (text.trim().isEmpty) return;
    selected.messages.add(
      ChatMessage(
        id: newId(),
        text: text.trim(),
        time: TimeOfDay.now().format24,
        reply: reply,
      ),
    );
    notifyListeners();
  }

  void addRole(RoleProfile profile) {
    roles.add(profile);
    conversations.add(
      Conversation(
        id: 'private-${profile.id}',
        name: profile.name,
        emoji: profile.emoji,
        members: [profile.id],
      ),
    );
    notifyListeners();
  }

  void removeRole(String id) {
    roles.removeWhere((r) => r.id == id);
    for (final c in conversations) {
      c.members.remove(id);
    }
    notifyListeners();
  }

  void addGroup(String name, List<String> members) {
    final id = newId();
    conversations.insert(
      0,
      Conversation(
        id: id,
        name: name,
        emoji: '🌿',
        members: members,
        group: true,
      ),
    );
    select(id);
  }

  final apis = [
    ApiProfile(id: 'demo', name: '我的模型接口', url: 'https://api.example.com/v1'),
  ];
  final roles = [
    RoleProfile(
      id: 'lin',
      name: '林间',
      emoji: '🌱',
      color: const Color(0xffb8cfbb),
      description: '植物爱好者 · 慢慢生活',
      identity: '你是林间，一个喜欢植物、散步和手写信的朋友。说话温和自然，留意生活里的细节。',
      soul: '最近学会了不急着给每件事一个答案。比起计划好的旅程，更喜欢偶然遇到的小风景。',
      examples: [
        {'question': '今天有点累。', 'answer': '那就先把今天放一放吧。要不要一起坐在窗边，看一会儿树影？'},
      ],
    ),
    RoleProfile(
      id: 'moon',
      name: '月白',
      emoji: '🌙',
      color: const Color(0xffd6c9e4),
      description: '夜猫子 · 收集电影与故事',
      identity: '你是月白，喜欢电影和城市夜晚的大学生。幽默、坦率，偶尔带一点诗意。',
      soul: '觉得朋友之间最珍贵的，是可以安心地沉默。想把这座城市的深夜都记下来。',
    ),
    RoleProfile(
      id: 'summer',
      name: '夏芽',
      emoji: '🍊',
      color: const Color(0xffead2ab),
      description: '元气满满 · 周末探店搭子',
      identity: '你是夏芽，热爱咖啡、拍照和周末探店。表达活泼，但尊重朋友的节奏。',
      soul: '想把每一个普通的周末变成值得期待的小冒险。',
    ),
  ];
  final conversations = [
    Conversation(
      id: 'garden',
      name: '周末小花园',
      emoji: '🌷',
      members: ['lin', 'moon', 'summer'],
      group: true,
      messages: [
        ChatMessage(
          id: 'm1',
          roleId: 'lin',
          text: '刚刚路过花店，发现第一批洋甘菊开了。\n这个周末，要不要一起去走走？',
          time: '16:38',
        ),
        ChatMessage(
          id: 'm2',
          roleId: 'summer',
          text: '我要去！🌼\n顺便找到一家有花园的咖啡店，窗边的位置特别好看。',
          time: '16:39',
        ),
        ChatMessage(id: 'm3', text: '听起来很棒。周六下午怎么样？', time: '16:40'),
        ChatMessage(
          id: 'm4',
          roleId: 'moon',
          text: '我带相机。希望那天有一点阳光，\n也有足够多的时间可以浪费。',
          time: '16:41',
          reply: '周六下午怎么样？',
        ),
        ChatMessage(
          id: 'm5',
          roleId: 'lin',
          text: '那就说好了。不用安排太满，\n我们慢慢走。',
          time: '16:42',
        ),
      ],
    ),
    Conversation(
      id: 'lin-chat',
      name: '林间',
      emoji: '🌱',
      members: ['lin'],
      messages: [
        ChatMessage(
          id: 'p1',
          roleId: 'lin',
          text: '今天给窗台的小植物换了个位置。\n它好像比昨天精神了一点。',
          time: '15:20',
        ),
      ],
    ),
    Conversation(
      id: 'moon-chat',
      name: '月白',
      emoji: '🌙',
      members: ['moon'],
      messages: [
        ChatMessage(
          id: 'p2',
          roleId: 'moon',
          text: '留了一部电影，等你有空一起看。',
          time: '昨天',
        ),
      ],
    ),
    Conversation(
      id: 'summer-chat',
      name: '夏芽',
      emoji: '🍊',
      members: ['summer'],
      messages: [],
    ),
  ];
  final memories = [
    MemoryEntry(
      id: 'mem1',
      roleId: 'lin',
      text: '你喜欢安静的咖啡店，最好能坐在窗边。',
      tag: '偏好',
    ),
    MemoryEntry(
      id: 'mem2',
      roleId: 'lin',
      text: '约好了周六下午和月白、夏芽一起去花店。',
      tag: '约定',
    ),
    MemoryEntry(
      id: 'mem3',
      roleId: 'moon',
      text: '一起看电影的时候，喜欢留下片尾曲。',
      tag: '日常',
    ),
  ];
  final schedules = [
    ScheduleEntry(
      id: 's1',
      roleId: 'lin',
      activity: '睡觉',
      condition: '每天',
      start: '23:00',
      end: '08:00',
      probability: 0,
    ),
    ScheduleEntry(
      id: 's2',
      roleId: 'lin',
      activity: '上课',
      condition: '每周一至周五',
      start: '09:00',
      end: '12:00',
      probability: 20,
    ),
    ScheduleEntry(
      id: 's3',
      roleId: 'lin',
      activity: '散步与聊天',
      condition: '每天',
      start: '16:00',
      end: '19:00',
      probability: 100,
    ),
  ];
}

extension on TimeOfDay {
  String get format24 =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
