import 'package:flutter/material.dart';
import 'app_theme.dart';

class GymLogo extends StatelessWidget {
  final double size;
  final bool withName;
  const GymLogo({super.key, this.size = 132, this.withName = false});
  @override
  Widget build(BuildContext context) => Image.asset(
    withName ? 'assets/images/fitaccess_logo_completo.png' : 'assets/images/fitaccess_icono.png',
    width: size, height: size, fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );
}

class GymCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const GymCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color ?? GymColors.surface,
      border: Border.all(color: const Color(0xFF30313A)),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 7))],
    ),
    padding: padding,
    child: child,
  );
}

class GymSectionTitle extends StatelessWidget {
  final String overline;
  final String title;
  final String? subtitle;
  const GymSectionTitle({super.key, required this.overline, required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(overline.toUpperCase(), style: const TextStyle(color: GymColors.gold, fontSize: 11, letterSpacing: 2.2, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ],
  );
}

class GymStatus extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const GymStatus({super.key, required this.text, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 15), const SizedBox(width: 6),
      Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
    ]),
  );
}

/// Entrada animada ligera sin crear estados ni dependencias adicionales.
class GymEnter extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const GymEnter({super.key, required this.child, this.delay = Duration.zero});
  @override
  State<GymEnter> createState() => _GymEnterState();
}

class _GymEnterState extends State<GymEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(begin: const Offset(0, .065), end: Offset.zero).animate(curve);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
}
