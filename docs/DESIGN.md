# Ganbak design — "Khayamiya" identity

Ganbak is used when people gather somewhere with no network. Its look comes from **khayamiya**, the hand-stitched
appliqué cloth of Cairo's tent-makers (the tents of weddings, Ramadan and festivals): every message is passed from
phone to phone like a stitch through cloth. Keep that idea; don't drift back to a generic purple chat app.

## Colours

All colours come from `context.palette` (`lib/core/theme/app_theme.dart`). Never hard-code theme colours in screens.

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | saffron `#F4B400` | `#F6BE2C` | Filled things: primary buttons, my bubbles, FAB, badges. Text on it = `onAccent` (ink). |
| `accentInk` | `#8F5E00` | = accent | Brand colour **as text or icon** on bg/surface (saffron text on white is unreadable). |
| `second` | amber `#F08C00` | `#F59E0B` | End of `accentGradient` (bubbles, send button). |
| `ink` | `#1B1F3B` | `#1B1F3B` | Night ink: dark cards (transport "Bluetooth" card, toasts, help button). |
| `saffron` / `tentRed` / `teal` | | | Identity colours, the same whatever accent the user picked. Red = games and alerts, teal = connection and safety. |
| `bg` / `surface` / `surfaceAlt` | `#F5F6FA` / white / `#EBEDF5` | `#0F1226` / `#181C36` / `#232846` | Neutrals with a slight ink-blue bias. Dark mode is night ink, not black. |

The default accent is `wasl`. The other accents stay in settings; with them `accentInk == accent`.

## Signature elements (`lib/widgets/identity.dart`)

- **Stitch** (`StitchLine`, `StitchPainter`, `StitchBorderPainter`, `StitchedBox`): the dashed line = "connected".
  Use it between people (nearby strip), around invite / game cards, around empty-state icons. Not on every card.
- **Khayamiya pattern** (`KhayamiyaPainter`): geometric eight-point stars. Only on large coloured surfaces (transport
  cards, game tiles, memory card backs, help-page headers), at ~10% opacity. Never behind body text on plain screens.
- **Bunting** (`Bunting`, `celebrate(context)`): Ramadan triangle flags. Only when someone wins a game.
- **Help button** (`HelpButton`): `؟` in Arabic, `?` in English (`l10n.helpMark`). Opens a detailed help page.

## Rules

- Font: IBM Plex Sans Arabic (`Plex`), weights 400–700 only.
- RTL / LTR: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`; directional arrows flip.
- Contrast: body text ≥ 4.5:1. Check new colours with a contrast calculator before using them for text.
- Check every UI change with the screenshot tool (`flutter test tool/shots/shots_test.dart`, then
  `python3 tool/shots/sheet.py` for one image per screen with ar/en × light/dark) and look at the PNGs.
- Launcher icon: `python3 tool/generate_icon.py` (saffron bubble + mesh on night ink with a faint pattern).
