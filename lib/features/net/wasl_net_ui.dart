import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
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
            SecondaryButton(
              label: l.netStop,
              icon: Icons.portable_wifi_off_rounded,
              color: Colors.white,
              height: 46,
              onPressed: net.stopHosting,
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
        if (offers.isEmpty) return const SizedBox.shrink();
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
