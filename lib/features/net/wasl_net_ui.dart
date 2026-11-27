import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../mesh/dual_link.dart';
import '../../mesh/mesh_router.dart';
import '../../widgets/feedback.dart';
import '../../widgets/identity.dart';
import '../../widgets/ui.dart';
import '../guide/guide_screen.dart';
import '../hub/chat_hub.dart';
import 'wasl_network.dart';

/// يفتح شبكة وصل ويقول للمستخدم لو فيه مشكلة.
Future<void> startWaslNetwork(BuildContext context) async {
  final err = await WaslNetwork.instance.host();
  if (err != null && context.mounted) showToast(context, err, error: true);
}

Future<void> joinWaslNetwork(BuildContext context, MeshNode node) async {
  final err = await WaslNetwork.instance.join(node);
  if (err != null && context.mounted) showToast(context, err, error: true);
}

/// كارت "شبكة وصل" في صفحة القريبين (في وضع الواي فاي أو الاتنين): افتحها / شغالة / إنت على شبكة حد.
class WaslNetCard extends StatefulWidget {
  const WaslNetCard({super.key});

  @override
  State<WaslNetCard> createState() => _WaslNetCardState();
}

class _WaslNetCardState extends State<WaslNetCard> {
  bool _showPass = false;

  @override
  Widget build(BuildContext context) {
    final net = WaslNetwork.instance;
    return ListenableBuilder(listenable: net, builder: (context, _) => _build(context, net));
  }

  Widget _build(BuildContext context, WaslNetwork net) {
    final p = context.palette;
    final l = context.l10n;
    final color = p.isDark ? const Color(0xFF2A3060) : p.ink;
    Widget header(String title, {Widget? trailing}) => Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: p.saffron, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.wifi_tethering_rounded, color: p.ink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            ?trailing,
            HelpButton(
              size: 32,
              onDark: true,
              label: l.guideNetTitle,
              onPressed: () => GuideScreen.open(context, section: GuideSection.connect),
            ),
          ],
        );

    final Widget body;
    switch (net.state) {
      case NetState.hosting:
        final o = net.hosted!;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(l.netHosting),
            const SizedBox(height: 8),
            Text(l.netHostingSub, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 13.5)),
            const SizedBox(height: 10),
            _Secret(label: l.netName, value: o.ssid),
            const SizedBox(height: 6),
            _Secret(
              label: l.netPassword,
              value: _showPass ? o.pass : '•' * o.pass.length.clamp(8, 12),
              copy: o.pass,
              trailing: _showPass
                  ? null
                  : TextButton(
                      onPressed: () => setState(() => _showPass = true),
                      style: TextButton.styleFrom(foregroundColor: p.saffron),
                      child: Text(l.netShowPass),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: l.netQr,
                    icon: Icons.qr_code_2_rounded,
                    color: Colors.white,
                    height: 46,
                    onPressed: () => showWifiQr(context, o),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: l.netStop,
                    icon: Icons.portable_wifi_off_rounded,
                    color: Colors.white,
                    height: 46,
                    onPressed: net.stopHosting,
                  ),
                ),
              ],
            ),
          ],
        );
      case NetState.joined:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(l.netJoined(net.joinedFrom ?? '')),
            const SizedBox(height: 8),
            Text(l.netJoinedSub, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 13.5)),
            const SizedBox(height: 12),
            SecondaryButton(label: l.netLeave, icon: Icons.logout_rounded, color: Colors.white, height: 46, onPressed: net.leave),
          ],
        );
      case NetState.starting || NetState.joining:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(l.netTitle),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.saffron)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    net.state == NetState.starting ? l.netStarting : l.netJoining,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        );
      case NetState.idle:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(l.netTitle),
            const SizedBox(height: 8),
            Text(l.netOpenSub, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 13.5)),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l.netOpen,
              icon: Icons.wifi_tethering_rounded,
              height: 48,
              onPressed: () => startWaslNetwork(context),
            ),
          ],
        );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: StitchedBox(
        color: color,
        pattern: true,
        radius: 22,
        stitch: p.saffron.withValues(alpha: 0.45),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: body,
      ),
    );
  }
}

/// كود QR للشبكة: أي موبايل يصوّره بالكاميرا يدخل الواي فاي (حتى من غير وصل أو على أندرويد قديم).
Future<void> showWifiQr(BuildContext context, WifiOffer offer) => showActionSheet<void>(
      context,
      builder: (ctx) {
        final l = ctx.l10n;
        final p = ctx.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.netQrTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Container(
                // الكود لازم يبقى أسود على أبيض في الوضعين (الكاميرات بتقراه كده)
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: WifiQr(data: offer.qrText, size: 220),
              ),
              const SizedBox(height: 10),
              Text(
                offer.ssid,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                l.netQrSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, height: 1.6, fontSize: 13.5),
              ),
            ],
          ),
        );
      },
    );

/// رسم كود QR (مكتبة qr — BSD).
class WifiQr extends StatelessWidget {
  const WifiQr({super.key, required this.data, this.size = 200});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final QrImage image;
    try {
      image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
    } catch (_) {
      return SizedBox.square(dimension: size);
    }
    return Semantics(
      label: context.l10n.netQr,
      image: true,
      child: SizedBox.square(dimension: size, child: CustomPaint(painter: _QrPainter(image))),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);
  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final cell = size.width / n;
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (image.isDark(r, c)) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell + 0.5, cell + 0.5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}

/// سطر "الاسم: …" أو "الباسورد: …" بنسخ.
class _Secret extends StatelessWidget {
  const _Secret({required this.label, required this.value, this.copy, this.trailing});
  final String label;
  final String value;
  final String? copy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = copy ?? value;
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Clipboard.setData(ClipboardData(text: text));
          showToast(context, l.netCopied);
        },
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 6, 8),
          child: Row(
            children: [
              Text('$label  ', style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
              Expanded(
                child: Text(
                  value,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
              ?trailing,
              const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// أنا أصلاً على واي فاي ومعايا ناس عليه: منزنّش بعرض شبكة تانية (الدخول هيقطعنا عنهم).
bool _onWifiWithPeople(ChatHub hub) {
  final link = hub.link;
  final router = hub.router;
  if (link is! DualLink || router == null) return false;
  for (final n in hub.people) {
    final l = router.linkOf(n.id);
    if (l != null && link.isWifi(l)) return true;
  }
  return false;
}

/// شريط فوق الصفحات: "فلان فاتح شبكة وصل جنبك — ادخلها".
class WaslNetOfferBanner extends StatelessWidget {
  const WaslNetOfferBanner({super.key, required this.kind});

  final TransportKind kind;

  @override
  Widget build(BuildContext context) {
    final net = WaslNetwork.instance;
    final hub = ChatHub.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([net, hub]),
      builder: (context, _) {
        final offers = net.offersFrom(hub.people);
        if (offers.isEmpty || _onWifiWithPeople(hub)) return const SizedBox.shrink();
        final node = offers.first;
        final p = context.palette;
        final l = context.l10n;
        final canJoin = kind == TransportKind.both;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: StitchedBox(
            color: p.isDark ? const Color(0xFF0E6F71) : p.teal,
            pattern: true,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_tethering_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.netOfferTitle(node.name),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  canJoin ? l.netOfferSub : l.netNeedBoth,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: l.netNotNow,
                        color: Colors.white,
                        height: 42,
                        onPressed: () => net.dismiss(node.wifi!.ssid),
                      ),
                    ),
                    if (canJoin) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: l.netJoin,
                          icon: Icons.login_rounded,
                          height: 42,
                          loading: net.state == NetState.joining,
                          onPressed: () => joinWaslNetwork(context, node),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// اللي جنبي مباشرة على البلوتوث بس (مش على الواي فاي).
List<String> _bluetoothNeighbours(ChatHub hub) {
  final link = hub.link;
  final router = hub.router;
  if (link is! DualLink || router == null) return const [];
  return [
    for (final n in hub.people)
      if (n.hops == 1)
        if (router.linkOf(n.id) case final l? when !link.isWifi(l)) n.id,
  ];
}

/// اقتراح: "ناس كتير حواليك على البلوتوث بس — افتح شبكة وصل". بيظهر لواحد بس (أصغر معرّف) في وضع "الاتنين".
class WaslNetSuggestBanner extends StatelessWidget {
  const WaslNetSuggestBanner({super.key, required this.kind});

  final TransportKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind != TransportKind.both) return const SizedBox.shrink();
    final net = WaslNetwork.instance;
    final hub = ChatHub.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([net, hub]),
      builder: (context, _) {
        final bt = _bluetoothNeighbours(hub);
        final show = WaslNetwork.suggestAmong(
          myId: hub.myId,
          bluetoothNeighbours: bt,
          anyOffer: hub.people.any((n) => n.wifi != null),
          state: net.state,
          dismissed: net.suggestDismissed,
        );
        if (!show) return const SizedBox.shrink();
        return WaslNetSuggestCard(count: bt.length);
      },
    );
  }
}

/// شكل الاقتراح نفسه (منفصل عشان صور الشاشات).
class WaslNetSuggestCard extends StatelessWidget {
  const WaslNetSuggestCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final net = WaslNetwork.instance;
    final p = context.palette;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: StitchedBox(
        color: p.isDark ? const Color(0xFF2A3060) : p.ink,
        pattern: true,
        radius: 20,
        stitch: p.saffron.withValues(alpha: 0.45),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_tethering_rounded, color: p.saffron),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.netSuggestTitle(count.toString()),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.netSuggestSub, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: l.netNotNow,
                    color: Colors.white,
                    height: 42,
                    onPressed: net.dismissSuggestion,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: l.netOpenShort,
                    icon: Icons.wifi_tethering_rounded,
                    height: 42,
                    loading: net.state == NetState.starting,
                    onPressed: () => startWaslNetwork(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
