import '../../../mesh/mesh_router.dart';
import 'game_kind.dart';

/// قراية آمنة للحالة اللي جاية من صاحب الغرفة: أي قيمة نوعها غلط بتبقى فاضية بدل ما الشاشة توقع.
/// (صاحب غرفة بتطبيق معدّل ممكن يبعت أي حاجة.)
class ViewRead {
  ViewRead._();

  static String? str(Object? raw) => raw is String ? raw : null;

  static int? integer(Object? raw) => raw is num ? raw.toInt() : null;

  static List<String> strs(Object? raw) => [
        if (raw is List)
          for (final x in raw.take(256))
            if (x is String) x,
      ];

  static List<int> ints(Object? raw) => [
        if (raw is List)
          for (final x in raw.take(512)) x is num ? x.toInt() : -1,
      ];

  static Map<String, int> intMap(Object? raw) => {
        if (raw is Map)
          for (final e in raw.entries.take(64))
            if (e.value is num) '${e.key}': (e.value as num).toInt(),
      };

  static Map<String, String> strMap(Object? raw) => {
        if (raw is Map)
          for (final e in raw.entries.take(64))
            if (e.value is String) '${e.key}': e.value as String,
      };

  static Map<Object?, Object?> map(Object? raw) => raw is Map ? raw : const {};

  /// ترتيب اللاعبين في الحالة (أو اللي في الغرفة لو مش موجود).
  static List<String> order(Map<String, dynamic> view, List<String> fallback) {
    final o = view['o'];
    if (o is! List) return fallback;
    return [for (final x in o.take(16)) if (x is String && MeshRouter.isId(x)) x];
  }
}

/// بيتأكد إن حالة الألعاب اللي فيها لوح سليمة الشكل (الأطوال والأرقام في حدودها) قبل ما نرسمها.
/// حالة بايظة بتترمي (الشاشة بتفضل على آخر حالة سليمة).
class ViewGuard {
  ViewGuard._();

  static bool _list(Object? raw, int length, int min, int max) {
    if (raw is! List || raw.length != length) return false;
    for (final x in raw) {
      if (x is! num || x.toInt() != x || x < min || x > max) return false;
    }
    return true;
  }

  static bool _indexes(Object? raw, int max) {
    if (raw == null) return true;
    if (raw is! List || raw.length > 64) return false;
    return raw.every((x) => x is num && x >= 0 && x <= max);
  }

  static bool valid(GameKind kind, Map<String, dynamic> v) {
    final o = v['o'];
    if (o != null && (o is! List || o.length > kind.maxPlayers || o.any((x) => x is! String))) return false;
    final players = o is List ? o.length : kind.maxPlayers;
    switch (kind) {
      case GameKind.xo:
        return _list(v['b'], 9, -1, 1) && _indexes(v['line'], 8);
      case GameKind.connect4:
        final last = v['last'];
        return _list(v['b'], 42, -1, 1) && _indexes(v['line'], 41) && (last == null || (last is num && last >= 0 && last < 42));
      case GameKind.dots:
        final n = v['n'];
        if (n is! num || n < 2 || n > 8) return false;
        final s = n.toInt();
        return _list(v['h'], (s + 1) * s, -1, players - 1) &&
            _list(v['v'], s * (s + 1), -1, players - 1) &&
            _list(v['box'], s * s, -1, players - 1) &&
            _list(v['s'], players, 0, 1 << 20);
      case GameKind.memory:
        final c = v['c'];
        if (c is! List || c.length > 48 || c.length.isOdd) return false;
        return _list(c, c.length, -1, 23) &&
            _list(v['own'], c.length, -1, players - 1) &&
            _indexes(v['open'], c.length - 1) &&
            _list(v['s'], players, 0, 1 << 20);
      case GameKind.battleship:
        final shots = v['shots'];
        if (shots != null) {
          if (shots is! Map || shots.length > 2) return false;
          for (final m in shots.values) {
            if (m is! Map || m.length > 64) return false;
            for (final e in m.entries) {
              final i = int.tryParse('${e.key}');
              if (i == null || i < 0 || i > 63 || e.value is! num || (e.value as num) < -1 || (e.value as num) > 2) return false;
            }
          }
        }
        final revealed = v['revealed'];
        if (revealed != null && (revealed is! Map || revealed.values.any((b) => b is! String || b.length != 64))) return false;
        return true;
      default:
        return true;
    }
  }
}
