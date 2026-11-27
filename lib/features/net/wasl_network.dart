import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/system_bridge.dart';
import '../../l10n/l10n.dart';
import '../../mesh/mesh_router.dart';

enum NetState {
  idle,

  /// بنفتح الشبكة.
  starting,

  /// شبكتي شغالة (الهوت سبوت مفتوح من التطبيق).
  hosting,

  /// بندخل شبكة حد تاني (مستنيين موافقة المستخدم من النظام).
  joining,

  /// إحنا على شبكة حد تاني.
  joined,
}

/// "شبكة وصل": الموبايل بيعمل شبكة واي فاي لوحده (من غير إنترنت) والتانيين بيدخلوها من التطبيق.
///
/// صاحب الشبكة بيبعت اسمها وكلمة سرها مع "أنا موجود" ([WifiOffer] في [MeshRouter]) — فاللي جنبه على البلوتوث
/// بيشوفها ويدخلها بضغطة (أندرويد 10+). الشبكة بتتقفل لما الشبكة (الـ hub) تقف أو التطبيق يتقفل.
class WaslNetwork extends ChangeNotifier {
  WaslNetwork._();
  static final WaslNetwork instance = WaslNetwork._();

  static const _native = MethodChannel('wasl/net');

  NetState state = NetState.idle;

  /// شبكتي (لما أكون فاتحها).
  WifiOffer? hosted;

  /// الشبكة اللي دخلتها ومين صاحبها.
  WifiOffer? joined;
  String? joinedFrom;

  /// شبكات المستخدم قال عليها "مش دلوقتي".
  final Set<String> dismissed = {};

  void dismiss(String ssid) {
    dismissed.add(ssid);
    notifyListeners();
  }

  /// تنبيهات للواجهة (الشبكة وقعت...).
  void Function(String message)? onNotice;

  /// اتغيرت (عشان الـ hub يعلن من جديد).
  VoidCallback? onOfferChanged;

  bool get busy => state == NetState.starting || state == NetState.joining;

  /// يفتح الشبكة. يرجّع رسالة خطأ (للمستخدم) أو null.
  Future<String?> host() async {
    if (state == NetState.hosting) return null;
    if (busy) return null;
    final need = await _permissions();
    if (need != null) return need;
    state = NetState.starting;
    notifyListeners();
    try {
      final r = await _native.invokeMapMethod<String, dynamic>('hostStart');
      final offer = WifiOffer.fromWire({'s': r?['ssid'], 'p': r?['pass'] ?? '', 'x': r?['sec']});
      if (offer == null) {
        await _native.invokeMethod<void>('hostStop');
        _reset();
        return tr.netErrFailed;
      }
      hosted = offer;
      state = NetState.hosting;
      notifyListeners();
      onOfferChanged?.call();
      return null;
    } on PlatformException catch (e) {
      _reset();
      return switch (e.code) {
        'incompatible' => tr.netErrIncompatible,
        'disallowed' => tr.netErrDisallowed,
        'permission' => tr.netErrPermission,
        _ => tr.netErrFailed,
      };
    } on MissingPluginException {
      _reset();
      return tr.netErrFailed;
    }
  }

  /// أندرويد 13+: إذن "الأجهزة القريبة". أقدم: إذن الموقع والموقع نفسه شغال.
  Future<String?> _permissions() async {
    try {
      final sdk = await SystemBridge.sdkInt();
      if (sdk >= 33) {
        final st = await Permission.nearbyWifiDevices.request();
        return st.isGranted ? null : tr.netErrPermission;
      }
      final st = await Permission.locationWhenInUse.request();
      if (!st.isGranted) return tr.netErrPermission;
      if (!await SystemBridge.locationEnabled()) return tr.netErrLocation;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> stopHosting() async {
    if (hosted == null && state != NetState.starting) return;
    try {
      await _native.invokeMethod<void>('hostStop');
    } catch (_) {}
    _reset();
    onOfferChanged?.call();
  }

  /// الموبايل يقدر يدخل الشبكة من جوه التطبيق؟ (أندرويد 10+)
  Future<bool> canJoinInApp() async {
    try {
      return await _native.invokeMethod<bool>('joinSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// يدخل شبكة حد قريب. يرجّع رسالة خطأ أو null.
  Future<String?> join(MeshNode node) async {
    final offer = node.wifi;
    if (offer == null || busy) return null;
    if (state == NetState.hosting) await stopHosting();
    state = NetState.joining;
    notifyListeners();
    try {
      final ok = await _native.invokeMethod<bool>('join', {
        'ssid': offer.ssid,
        'pass': offer.pass,
        'sec': offer.security,
      });
      if (ok != true) {
        _reset();
        return tr.netErrJoin;
      }
      joined = offer;
      joinedFrom = node.name;
      state = NetState.joined;
      notifyListeners();
      return null;
    } on PlatformException catch (e) {
      _reset();
      return e.code == 'unsupported' ? tr.netOldAndroid(offer.ssid, offer.pass) : tr.netErrJoin;
    } on MissingPluginException {
      _reset();
      return tr.netErrJoin;
    }
  }

  Future<void> leave() async {
    if (joined == null && state != NetState.joining) return;
    try {
      await _native.invokeMethod<void>('leave');
    } catch (_) {}
    _reset();
  }

  /// الشبكة (الـ hub) وقفت: نقفل كل حاجة.
  Future<void> shutdown() async {
    await stopHosting();
    await leave();
    suggestDismissed = false;
  }

  /// حدث من النظام.
  void onSystemEvent(String event) {
    if (event == 'netLost' && joined != null) {
      _reset();
      onNotice?.call(tr.netLost);
    } else if (event == 'hostLost' && hosted != null) {
      _reset();
      onOfferChanged?.call();
      onNotice?.call(tr.netHostLost);
    }
  }

  void _reset() {
    state = NetState.idle;
    if (hosted != null) suggestDismissed = true;
    hosted = null;
    joined = null;
    joinedFrom = null;
    notifyListeners();
  }

  /// المستخدم قال "مش دلوقتي" على اقتراح فتح الشبكة (لحد ما الـ hub يقف).
  bool suggestDismissed = false;

  void dismissSuggestion() {
    suggestDismissed = true;
    notifyListeners();
  }

  /// أقل عدد ناس جنبي على البلوتوث بس عشان نقترح فتح شبكة.
  static const suggestAt = 3;

  /// نقترح عليّا أنا أفتح شبكة وصل؟ لما يكون جنبي [suggestAt] أو أكتر على البلوتوث بس، ومفيش حد فاتح شبكة،
  /// وأنا أصغر معرّف بينهم (عشان واحد بس يتقاله، مش الكل يفتحوا شبكات مع بعض).
  static bool suggestAmong({
    required String myId,
    required List<String> bluetoothNeighbours,
    required bool anyOffer,
    required NetState state,
    bool dismissed = false,
  }) {
    if (dismissed || anyOffer || state != NetState.idle) return false;
    if (bluetoothNeighbours.length < suggestAt) return false;
    return bluetoothNeighbours.every((id) => myId.compareTo(id) < 0);
  }

  /// شبكات وصل قريبة أقدر أدخلها: من جيران مباشرين (البلوتوث = جنبي فعلاً)، ومش شبكتي ولا اللي أنا فيها.
  List<MeshNode> offersFrom(Iterable<MeshNode> nodes) => offersAmong(nodes, state: state, joined: joined, dismissed: dismissed);

  @visibleForTesting
  static List<MeshNode> offersAmong(
    Iterable<MeshNode> nodes, {
    required NetState state,
    WifiOffer? joined,
    Set<String> dismissed = const {},
  }) {
    if (state == NetState.hosting || state == NetState.joining) return const [];
    return [
      for (final n in nodes)
        if (n.wifi != null && n.hops == 1 && n.wifi != joined && !dismissed.contains(n.wifi!.ssid)) n,
    ];
  }
}
