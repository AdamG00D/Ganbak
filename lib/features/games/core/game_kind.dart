/// الألعاب الموجودة. [id] هو اللي بيتبعت في الشبكة — متغيّروش.
enum GameKind {
  xo('xo', 2, 2, direct: true, group: false),
  connect4('c4', 2, 2, direct: true, group: false),
  battleship('bs', 2, 2, direct: true, group: false),
  rps('rps', 2, 2, direct: true, group: false),
  dots('dots', 2, 4, direct: true, group: true),
  memory('mem', 2, 6, direct: true, group: true),
  spy('spy', 3, 12, direct: false, group: true),
  quiz('quiz', 2, 15, direct: false, group: true),
  mafia('mafia', 5, 15, direct: false, group: true);

  const GameKind(this.id, this.minPlayers, this.maxPlayers, {required this.direct, required this.group});

  final String id;
  final int minPlayers;
  final int maxPlayers;

  /// بتتلعب في الشات الخاص (لاعبين اتنين).
  final bool direct;

  /// بتتلعب في الجروبات.
  final bool group;

  /// لعبة فيها أسرار عند صاحب الغرفة (أدوار، كلمة، إجابات) — حركات اللاعبين بتروحله مقفولة.
  bool get secretMoves => this == spy || this == quiz || this == mafia;

  static GameKind? byId(Object? id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }

  static List<GameKind> forChat({required bool group}) =>
      [for (final k in values) if (group ? k.group : k.direct) k];
}
