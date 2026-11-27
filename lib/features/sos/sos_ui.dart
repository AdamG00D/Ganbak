import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../mesh/mesh_router.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ui.dart';
import '../chat/chat_page.dart';
import '../hub/chat_hub.dart';

/// فوق الصفحات: استغاثات وصلت من حواليك + استغاثتي لو شغالة.
class SosBanner extends StatelessWidget {
  const SosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final hub = ChatHub.instance;
    return ListenableBuilder(
      listenable: hub,
      builder: (context, _) {
        final p = context.palette;
        final l = context.l10n;
        final list = [for (final n in hub.sosNodes) if (hub.sosDismissed[n.id] != n.sos) n];
        final mine = hub.mySos;
        if (list.isEmpty && mine == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Column(
            children: [
              if (mine != null)
                _RedBox(
                  child: Row(
                    children: [
                      const Text('🆘', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.sosActive, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      TextButton(
                        onPressed: hub.stopSos,
                        style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.white24),
                        child: Text(l.sosStop),
                      ),
                    ],
                  ),
                ),
              if (list.isNotEmpty) ...[
                if (mine != null) const SizedBox(height: 8),
                _Alert(node: list.first, more: list.length - 1),
              ],
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l.sosUnverified, style: TextStyle(color: p.textMuted, fontSize: 11.5)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RedBox extends StatelessWidget {
  const _RedBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(color: context.palette.tentRed, borderRadius: BorderRadius.circular(18)),
        child: child,
      );
}

class _Alert extends StatelessWidget {
  const _Alert({required this.node, required this.more});
  final MeshNode node;
  final int more;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hub = ChatHub.instance;
    final text = node.sos?.text ?? '';
    return _RedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(name: node.name, color: node.color, avatarHash: node.avatar, cartoon: node.cartoon, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🆘 ${l.sosFrom(node.name)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                    Text(
                      node.hops <= 1 ? l.sosNear : l.viaRelays(node.hops - 1),
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final c = hub.openDirect(node.id);
                    if (c != null) ChatPage.open(context, c);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: context.palette.tentRed),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(l.sosChat),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => hub.dismissSos(node),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  child: Text(more > 0 ? '${l.sosOk} (${l.sosMore('$more')})' : l.sosOk, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// في صفحة القريبين: "محتاج مساعدة؟".
class SosCard extends StatelessWidget {
  const SosCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final hub = ChatHub.instance;
    if (hub.mySos != null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.tentRed.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: const Text('🆘', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.sosAsk, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(l.sosAskSub, style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => showSosSheet(context),
              style: FilledButton.styleFrom(backgroundColor: p.tentRed, foregroundColor: Colors.white, minimumSize: const Size(0, 42)),
              child: Text(l.sosOpen),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة إرسال استغاثة (نص اختياري + تأكيد).
Future<void> showSosSheet(BuildContext context) async {
  final ctrl = TextEditingController();
  final sent = await showActionSheet<bool>(
    context,
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
    builder: (ctx) {
      final p = ctx.palette;
      final l = ctx.l10n;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('🆘 ${l.sosSheetTitle}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(l.sosSheetBody, style: TextStyle(color: p.textMuted, height: 1.6)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLength: SosSignal.maxLength,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(hintText: l.sosHint),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: l.sosSend,
              icon: Icons.campaign_rounded,
              color: p.tentRed,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
    },
  );
  final text = ctrl.text;
  ctrl.dispose();
  if (sent != true) return;
  HapticFeedback.heavyImpact();
  await ChatHub.instance.setSos(text);
}
