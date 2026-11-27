import 'dart:typed_data';

import 'package:wasl/features/chat/core/chat_session.dart';
import 'package:wasl/features/hub/chat_hub.dart';
import 'package:wasl/mesh/mesh_router.dart';

/// بيانات تجريبية للصور: ناس حواليك، محادثات، جروبات.
class Sample {
  Sample._();

  static const karim = 'aaaaaaaaaaaaaaa1';
  static const salma = 'aaaaaaaaaaaaaaa2';
  static const mona = 'aaaaaaaaaaaaaaa3';
  static const omar = 'aaaaaaaaaaaaaaa4';
  static const nour = 'aaaaaaaaaaaaaaa5';

  static late GroupChat shilla;
  static late DirectChat karimChat;

  static MeshNode _node(String id, String name, int color, int? cartoon, {int hops = 1}) =>
      MeshNode(id, Uint8List(32))
        ..name = name
        ..color = color
        ..cartoon = cartoon
        ..hops = hops;

  /// رسالة مستنية صاحبها (لصورة "مش موجود").
  static ChatMessage awayMessage() => ChatMessage(
    id: 'mb-0011223344556677',
    text: 'أنا مستنيك عند البوابة',
    kind: MessageKind.mine,
    status: MessageStatus.queued,
  );

  /// الهب لازم يكون شغال (hub.start).
  static Future<void> fill(ChatHub hub) async {
    final r = hub.router!;
    for (final n in [
      _node(karim, 'كريم', 4, 7),
      _node(salma, 'سلمى', 7, 12),
      _node(mona, 'منى', 2, 18),
      _node(omar, 'عمر', 5, null, hops: 2),
      _node(nour, 'نور', 8, 21, hops: 3),
    ]) {
      r.nodes[n.id] = n;
    }
    shilla = await hub.createGroup(name: 'الشلة', mode: GroupMode.password, password: 'سر1234');
    shilla.session.messages.addAll([
      ChatMessage(id: 'g1', text: 'هنتقابل فين بكرة؟', kind: MessageKind.theirs, sender: 'كريم', senderId: karim),
      ChatMessage(id: 'g2', text: 'عند البوابة الساعة 5', kind: MessageKind.mine, status: MessageStatus.read),
      ChatMessage(
        id: 'g3',
        text: '@آدم هات الشاحن معاك 😅',
        kind: MessageKind.theirs,
        sender: 'منى',
        senderId: mona,
        mentions: {hub.myId: 'آدم'},
      )
        ..mentionsMe = true
        ..reactions[karim] = '😂',
    ]);
    shilla.unread = 3;
    karimChat = hub.openDirect(karim)!;
    karimChat.session.messages.addAll([
      ChatMessage(id: 'd1', text: 'إنت فين؟', kind: MessageKind.theirs),
      ChatMessage(id: 'd2', text: 'جنب المسرح، تعالى', kind: MessageKind.mine, status: MessageStatus.read),
      ChatMessage(id: 'd3', text: 'تمام يا معلم 👍', kind: MessageKind.theirs),
    ]);
    final salmaChat = hub.openDirect(salma)!;
    salmaChat.session.messages.add(ChatMessage(id: 's1', text: 'بعتتلك الملف، شوفه لما تفضى', kind: MessageKind.theirs));
    salmaChat.unread = 1;
    final trip = await hub.createGroup(name: 'رحلة الساحل', mode: GroupMode.open);
    trip.session.messages.add(
      ChatMessage(id: 't1', text: 'الأتوبيس هيتحرك الساعة 6 الصبح', kind: MessageKind.theirs, sender: 'عمر', senderId: omar),
    );
  }
}
