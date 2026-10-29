import 'package:flutter/material.dart';
import 'prototype_icons.dart';

const ink = Color(0xff171714),
    charcoal = Color(0xff20201c),
    gold = Color(0xffc79517),
    primaryGold = Color(0xffb98200),
    paper = Color(0xfff7f6f2),
    muted = Color(0xff77736a),
    border = Color(0xffddd9d0);
typedef Data = Map<String, dynamic>;
String money(dynamic v) {
  final n = num.tryParse('$v') ?? 0;
  final fixed = n.toStringAsFixed(2).split('.');
  final a = fixed[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'S/ $a.${fixed[1]}';
}

String stateLabel(dynamic s) =>
    const {
      'DISPONIBLE': 'Disponible',
      'RESERVADO': 'Reservado',
      'VENDIDO': 'Vendido',
      'NO_DISPONIBLE': 'No disponible',
      'ACTIVA': 'Reservado',
      'ANULADA': 'Liberada',
      'CONFIRMADA': 'Vendido',
      'VENCIDA': 'Vencida',
    }[s] ??
    '$s';
Widget tx(
  String t, {
  double size = 14,
  Color color = ink,
  FontWeight weight = FontWeight.w400,
  double height = 1.5,
  TextAlign? align,
  int? maxLines,
  double? spacing,
}) => Text(
  t,
  textAlign: align,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
  ),
);
Widget ico(
  String n, {
  double size = 20,
  Color color = ink,
  double stroke = 2,
}) => LineIcon(n, size: size, color: color, stroke: stroke);
Widget space([double h = 12]) => SizedBox(height: h);
Widget uiBox(
  Widget child, {
  EdgeInsetsGeometry padding = const EdgeInsets.all(13),
  Color color = Colors.white,
  Color line = border,
  double radius = 13,
  BoxBorder? borders,
  List<BoxShadow>? shadow,
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: color,
    border: borders ?? Border.all(color: line),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadow,
  ),
  child: child,
);
Widget brand({bool compact = false}) => Container(
  width: compact ? 58 : 220,
  height: compact ? 44 : 132,
  padding: EdgeInsets.all(compact ? 3 : 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(compact ? 7 : 14),
  ),
  child: Image.asset(
    'assets/casa-vip-logo.png',
    fit: BoxFit.contain,
    semanticLabel: 'CASA VIP Inmobiliaria',
  ),
);
Widget eyebrow(String t, {bool golden = false}) => tx(
  t,
  size: 10.72,
  height: 1.35,
  color: golden ? const Color(0xffe8bf53) : const Color(0xff817d73),
  weight: FontWeight.w800,
  spacing: 1.28,
);
Widget sectionTitle(
  String title, {
  String? overline,
  String? action,
  VoidCallback? onAction,
  double top = 22,
}) => Padding(
  padding: EdgeInsets.only(top: top, bottom: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overline != null) ...[eyebrow(overline), space(3)],
            tx(title, size: 16.8, height: 1.5),
          ],
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: tx(
            action,
            size: 11.84,
            color: const Color(0xff9b7108),
            weight: FontWeight.w800,
          ),
        ),
    ],
  ),
);
Widget primary(
  String label,
  VoidCallback? onTap, {
  String? before,
  String? after,
  Color color = primaryGold,
  bool outline = false,
}) => Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(11),
    boxShadow: outline
        ? null
        : [
            BoxShadow(
              color: color.withValues(alpha: .22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
  ),
  child: FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: outline ? Colors.white : color,
      foregroundColor: outline ? const Color(0xff8e680a) : Colors.white,
      disabledBackgroundColor: color.withValues(alpha: .4),
      minimumSize: const Size.fromHeight(46),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: outline
            ? const BorderSide(color: Color(0xffc9a03d))
            : BorderSide.none,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (before != null) ...[
          ico(
            before,
            size: 18,
            color: outline ? const Color(0xff8e680a) : Colors.white,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: tx(
            label,
            size: 14,
            color: outline ? const Color(0xff8e680a) : Colors.white,
            weight: FontWeight.w800,
            align: TextAlign.center,
          ),
        ),
        if (after != null) ...[
          const SizedBox(width: 8),
          ico(after, size: 18, color: Colors.white),
        ],
      ],
    ),
  ),
);
Widget statusBadge(dynamic state) {
  final s = '$state';
  final colors = s == 'DISPONIBLE'
      ? [const Color(0xffe1f1e5), const Color(0xff24713b)]
      : ['RESERVADO', 'ACTIVA'].contains(s)
      ? [const Color(0xffe2edf8), const Color(0xff2a628f)]
      : ['VENDIDO', 'CONFIRMADA'].contains(s)
      ? [const Color(0xfff5e7d5), const Color(0xff985510)]
      : [const Color(0xffe5e5e1), const Color(0xff777771)];
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: colors[0],
      borderRadius: BorderRadius.circular(99),
    ),
    child: tx(
      stateLabel(s),
      size: 9.28,
      color: colors[1],
      weight: FontWeight.w800,
    ),
  );
}

Widget infoNote(
  String text, {
  String icon = 'shield-check',
  bool compact = false,
  bool dark = false,
}) => Container(
  margin: EdgeInsets.only(top: compact ? 0 : 18),
  padding: EdgeInsets.all(compact ? 11 : 13),
  decoration: BoxDecoration(
    color: dark ? charcoal : const Color(0xffeef4ef),
    border: Border.all(color: dark ? charcoal : const Color(0xffd6e5d8)),
    borderRadius: BorderRadius.circular(compact ? 10 : 12),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ico(
        icon,
        size: compact ? 18 : 19,
        color: dark ? gold : const Color(0xff396046),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: tx(
          text,
          size: compact ? 11.2 : 12,
          color: dark ? Colors.white : const Color(0xff356043),
          height: 1.45,
        ),
      ),
    ],
  ),
);
Widget lotNumber(Data l, {bool small = false}) => Container(
  width: small ? 47 : 55,
  height: small ? 52 : 62,
  decoration: BoxDecoration(
    color: charcoal,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      tx(
        'MZ ${l['manzana'] ?? 'B'}',
        size: 9.28,
        color: const Color(0xffd9b04b),
        weight: FontWeight.w800,
        spacing: .64,
      ),
      space(3),
      tx(
        '${l['codigo'] ?? l['lote'] ?? ''}'.padLeft(2, '0'),
        size: small ? 21 : 23.2,
        height: 1,
        color: Colors.white,
        weight: FontWeight.w800,
      ),
    ],
  ),
);
Widget avatar(String name, {double size = 38}) {
  final words = name.trim().split(RegExp(r'\s+'));
  final initials = words
      .take(2)
      .where((x) => x.isNotEmpty)
      .map((x) => x[0])
      .join()
      .toUpperCase();
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: gold,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xffe8cf85), width: 2),
    ),
    child: tx(initials, size: 12.48, weight: FontWeight.w800),
  );
}

/// Conserva los bordes laterales del CSS junto a sus esquinas redondeadas.
class PrototypeBorder extends Border {
  const PrototypeBorder({
    super.top = BorderSide.none,
    super.right = BorderSide.none,
    super.bottom = BorderSide.none,
    super.left = BorderSide.none,
  });
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    canvas.save();
    if (borderRadius != null) {
      canvas.clipRRect(borderRadius.toRRect(rect));
    }
    super.paint(
      canvas,
      rect,
      textDirection: textDirection,
      shape: shape,
      borderRadius: null,
    );
    canvas.restore();
  }
}
