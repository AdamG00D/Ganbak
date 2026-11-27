import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fingerprint.dart';
import '../../widgets/ui.dart';
import '../groups/group_ui.dart';
import '../hub/chat_hub.dart';

/// "عنه": بصمة الشخص، موثّق ولا لأ، والاسم اللي سمّيته بيه عندك.
Future<void> showPersonSheet(BuildContext context, DirectChat chat, {VoidCallback? onVerify}) =>
    showActionSheet<void>(
      context,
      builder: (ctx) => ListenableBuilder(
        listenable: chat.session,
        builder: (ctx, _) {
          final l = ctx.l10n;
          final p = ctx.palette;
          final verified = chat.session.verified;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Avatar(
                    name: chat.title,
                    color: chat.color,
                    avatarHash: chat.avatar,
                    cartoon: chat.cartoon,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chat.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                if (chat.nickname != null)
                  Text(
                    l.theirName(chat.ownName),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted, fontSize: 13),
                  ),
                if (verified) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, color: p.success, size: 18),
                      const SizedBox(width: 6),
                      Text(l.encryptedVerified, style: TextStyle(color: p.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                AppCard(
                  child: Row(
                    children: [
                      Fingerprint(id: chat.peerId, size: 88),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.fingerprintTitle(chat.title),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                            ),
                            const SizedBox(height: 6),
                            Text(l.fingerprintBody, style: TextStyle(color: p.textMuted, height: 1.6, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit_rounded, color: p.accentInk),
                        title: Text(l.nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: chat.nickname == null ? null : Text(l.nicknameSet(chat.nickname!)),
                        onTap: () async {
                          final name = await promptText(
                            ctx,
                            title: l.nicknameTitle,
                            initial: chat.nickname ?? chat.ownName,
                          );
                          if (name == null) return;
                          await ChatHub.instance.setNickname(chat, name.trim() == chat.ownName ? null : name);
                        },
                        trailing: chat.nickname == null
                            ? null
                            : IconButton(
                                tooltip: l.nicknameNone,
                                icon: Icon(Icons.close_rounded, color: p.textMuted),
                                onPressed: () => ChatHub.instance.setNickname(chat, null),
                              ),
                      ),
                      if (onVerify != null && !verified)
                        ListTile(
                          leading: Icon(Icons.verified_user_outlined, color: p.accentInk),
                          title: Text(l.safetyCodeOptional, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.pop(ctx);
                            onVerify();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
