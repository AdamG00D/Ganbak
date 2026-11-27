import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/identity.dart';
import '../../widgets/ui.dart';
import '../net/wasl_net_ui.dart';
import '../net/wasl_network.dart';
import 'share_page.dart';
import 'share_server.dart';

/// "شارك وصل": صاحبك مفيهوش التطبيق — كود يدخل بيه شبكة موبايلك، وكود يفتح صفحة يحمّل منها التطبيق من
/// موبايلك على طول (سيرفر صغير جوه التطبيق، شغال بس طول ما الشاشة دي مفتوحة).
class ShareAppScreen extends StatefulWidget {
  const ShareAppScreen({super.key, this.testApk, this.testUrl});

  /// لصور الشاشات بس: من غير سيرفر ولا قناة أندرويد.
  final ApkInfo? testApk;
  final String? testUrl;

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShareAppScreen()));

  @override
  State<ShareAppScreen> createState() => _ShareAppScreenState();
}

class _ShareAppScreenState extends State<ShareAppScreen> {
  ApkInfo? _apk;
  bool _failed = false;
  ShareServer? _server;
  String? _url;
  Timer? _poll;

  bool get _testing => widget.testApk != null;

  @override
  void initState() {
    super.initState();
    if (_testing) {
      _apk = widget.testApk;
      _url = widget.testUrl;
      return;
    }
    _prepare();
  }

  Future<void> _prepare() async {
    final apk = await ApkInfo.load();
    if (!mounted) return;
    if (apk == null) {
      setState(() => _failed = true);
      return;
    }
    _apk = apk;
    if (!apk.split) {
      final s = ShareServer(apk: apk);
      if (await s.start()) {
        if (!mounted) {
          await s.stop();
          return;
        }
        _server = s;
        s.served.addListener(_changed);
        await _refreshUrl();
        // العنوان بيتغير لما الشبكة تتفتح أو الواي فاي يتغير
        _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refreshUrl());
      } else {
        _failed = true;
      }
    }
    if (mounted) setState(() {});
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshUrl() async {
    final s = _server;
    if (s == null) return;
    final ip = await ShareServer.localAddress(hosting: WaslNetwork.instance.state == NetState.hosting);
    final url = ip == null ? null : 'http://$ip${s.port == 80 ? '' : ':${s.port}'}/';
    if (mounted && url != _url) setState(() => _url = url);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _server?.served.removeListener(_changed);
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l.shareApp)),
      body: ListenableBuilder(
        listenable: WaslNetwork.instance,
        builder: (context, _) {
          final net = WaslNetwork.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              StitchedBox(
                color: p.isDark ? const Color(0xFF2A3060) : p.ink,
                pattern: true,
                radius: 22,
                stitch: p.saffron.withValues(alpha: 0.45),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: p.saffron, borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.ios_share_rounded, color: p.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.shareIntro,
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Step(number: 1, title: l.shareStep1, child: _network(context, net)),
              const SizedBox(height: 14),
              _Step(number: 2, title: l.shareStep2, child: _download(context)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: p.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.shareWhileOpen, style: TextStyle(color: p.textMuted, fontSize: 13))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _network(BuildContext context, WaslNetwork net) {
    final l = context.l10n;
    final p = context.palette;
    final muted = TextStyle(color: p.textMuted, height: 1.6, fontSize: 14);
    final offer = net.hosted;
    if (net.state == NetState.hosting && offer != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _QrBox(data: offer.qrText)),
          const SizedBox(height: 12),
          _CopyRow(label: l.netName, value: offer.ssid),
          const SizedBox(height: 6),
          _CopyRow(label: l.netPassword, value: offer.pass),
          const SizedBox(height: 10),
          Text(l.shareStep1Scan, style: muted),
          const SizedBox(height: 10),
          SecondaryButton(
            label: l.netStop,
            icon: Icons.portable_wifi_off_rounded,
            height: 44,
            onPressed: net.stopHosting,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.shareStep1Idle, style: muted),
        const SizedBox(height: 12),
        PrimaryButton(
          label: l.netOpen,
          icon: Icons.wifi_tethering_rounded,
          height: 48,
          loading: net.state == NetState.starting,
          onPressed: net.busy ? null : () => startWaslNetwork(context),
        ),
        const SizedBox(height: 10),
        Text(l.shareSameWifi, style: muted.copyWith(fontSize: 13)),
      ],
    );
  }

  Widget _download(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final muted = TextStyle(color: p.textMuted, height: 1.6, fontSize: 14);
    final apk = _apk;
    if (_failed) return Text(l.shareFailed, style: muted.copyWith(color: p.danger));
    if (apk == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6))),
      );
    }
    if (apk.split) return Text(l.shareSplit, style: muted.copyWith(color: p.danger));
    final url = _url;
    if (url == null) return Text(l.shareNeedNet, style: muted);
    final served = _server?.served.value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _QrBox(data: url)),
        const SizedBox(height: 12),
        _CopyRow(label: '', value: url),
        const SizedBox(height: 10),
        Text(l.shareStep2Scan, style: muted),
        const SizedBox(height: 10),
        Text(l.shareFingerprint, style: TextStyle(color: p.textMuted, fontSize: 12.5)),
        const SizedBox(height: 4),
        Text(
          SharePage.groups(apk.sha256),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: p.textMuted,
            wordSpacing: 3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (served > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.download_done_rounded, color: p.success, size: 18),
              const SizedBox(width: 6),
              Text(l.shareServed('$served'), style: TextStyle(color: p.success, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ],
    );
  }
}

/// كارت خطوة مترقّمة.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.child});

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.isDark ? p.saffron : p.ink, shape: BoxShape.circle),
                child: Text(
                  '$number',
                  style: TextStyle(color: p.isDark ? p.ink : p.saffron, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// كود QR أسود على أبيض في الوضعين (الكاميرات بتقراه كده).
class _QrBox extends StatelessWidget {
  const _QrBox({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: WifiQr(data: data, size: 190),
    );
  }
}

/// سطر قيمة بنسخ (اسم الشبكة، الباسورد، اللينك).
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.isDark ? Colors.white.withValues(alpha: 0.06) : p.ink.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          showToast(context, context.l10n.netCopied);
        },
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
          child: Row(
            children: [
              if (label.isNotEmpty) Text('$label  ', style: TextStyle(color: p.textMuted, fontSize: 13)),
              // الاسم والباسورد لازم يبانوا كاملين: بنصغّر الخط بدل ما نقصّهم
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
                  ),
                ),
              ),
              Icon(Icons.copy_rounded, color: p.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
