import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'brand.dart';
import 'models.dart';
import 'services.dart';
import 'theme.dart';

class StudiaryMascot extends StatefulWidget {
  const StudiaryMascot({
    super.key,
    this.size = 64,
    this.pose = MascotPose.encourage,
    this.animate = true,
  });

  final double size;
  final MascotPose pose;
  final bool animate;

  @override
  State<StudiaryMascot> createState() => _StudiaryMascotState();
}

class _StudiaryMascotState extends State<StudiaryMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant StudiaryMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate == widget.animate) return;
    if (widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      child: Semantics(
        label: 'Studi, la mascota de Studiary',
        image: true,
        child: Image.asset(
          widget.pose.asset,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
      builder: (context, child) {
        final wave = math.sin(_motion.value * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, wave * widget.size * .035),
          child: Transform.rotate(angle: wave * .025, child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }
}

class StudiaryLogo extends StatelessWidget {
  const StudiaryLogo({super.key, this.width = 240, this.height});

  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Studiary. Planifica. Estudia. Avanza.',
      image: true,
      child: SizedBox(
        width: width,
        height: height ?? 80,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(BrandAssets.appIcon, width: 72, height: 72),
              ),
              const SizedBox(width: 14),
              Text(
                'Studiary',
                style: TextStyle(
                  fontSize: 38,
                  letterSpacing: -1.5,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudiaryMark extends StatelessWidget {
  const StudiaryMark({super.key, this.size = 44, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark
            ? scheme.primary.withValues(alpha: .18)
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * .05),
        child: Image.asset(
          BrandAssets.appIcon,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.tint,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Theme.of(context).colorScheme.primary;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class EventTypeBadge extends StatelessWidget {
  const EventTypeBadge({super.key, required this.type});

  final EventType type;

  @override
  Widget build(BuildContext context) {
    final color = eventTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color eventTypeColor(EventType type) {
  switch (type) {
    case EventType.practicas:
      return const Color(0xFF789DE5);
    case EventType.estudio:
      return const Color(0xFF59B997);
    case EventType.examen:
      return const Color(0xFFE8788F);
    case EventType.personal:
      return const Color(0xFFA58AD9);
  }
}

class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.event,
    required this.onTap,
    this.subjectName,
  });

  final PlannerEvent event;
  final VoidCallback onTap;
  final String? subjectName;

  @override
  Widget build(BuildContext context) {
    final color = eventTypeColor(event.type);
    final time = event.isAllDay
        ? 'Todo el día'
        : '${_twoDigits(event.startDate.hour)}:${_twoDigits(event.startDate.minute)}';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 55,
              child: Text(
                time,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (subjectName != null && subjectName!.isNotEmpty)
                    Text(
                      subjectName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            EventTypeBadge(type: event.type),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.mascotPose = MascotPose.encourage,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final MascotPose mascotPose;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              StudiaryMascot(size: 92, pose: mascotPose),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.visible});

  final bool visible;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    MonetizationService.adConsent.addListener(_consentChanged);
    _loadAdIfNeeded();
  }

  void _consentChanged() {
    if (!MonetizationService.canRequestAds) {
      _retry?.cancel();
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _loaded = false);
    } else {
      _loadAdIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible && !widget.visible) {
      _retry?.cancel();
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      return;
    }
    if (!oldWidget.visible && widget.visible) _loadAdIfNeeded();
  }

  void _loadAdIfNeeded() {
    if (kIsWeb ||
        _ad != null ||
        !widget.visible ||
        !MonetizationService.canRequestAds) {
      return;
    }
    _ad = MonetizationService.createBanner(
      onLoaded: (ad) {
        if (mounted && identical(_ad, ad)) {
          setState(() => _loaded = true);
        }
      },
      onFailed: (ad, error) {
        ad.dispose();
        if (!mounted || !identical(_ad, ad)) return;
        setState(() {
          _ad = null;
          _loaded = false;
        });
        debugPrint('Banner no disponible (código ${error.code}).');
        _retry?.cancel();
        _retry = Timer(const Duration(seconds: 60), _loadAdIfNeeded);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }

  @override
  void dispose() {
    MonetizationService.adConsent.removeListener(_consentChanged);
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

Color colorFromHex(String hex) {
  final value = hex.replaceAll('#', '');
  final normalized = value.length == 6 ? 'FF$value' : value;
  return Color(int.tryParse(normalized, radix: 16) ?? coral.toARGB32());
}
