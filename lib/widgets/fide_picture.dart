import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';

/// Antwortbild wie im fide-Heft: schlichte Zeichnung ohne Text-Lösung.
///
/// `clock:18:30` Uhr (Zeiger + Digitalanzeige) · `cal:5,19` Monatskalender
/// (`cal:5,19@3` = Monat beginnt am Donnerstag) · `week:Di,Sa` Wochentage ·
/// `price:4.50` Preisschild · `text:500 g` Schild · `icon:cake` Gegenstand ·
/// `icons:cake,coffee` mehrere Gegenstände · `count:4:person` Anzahl.
class FidePictureView extends StatelessWidget {
  const FidePictureView(this.picture, {super.key, this.height = 150});

  final FidePicture picture;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = picture.value;
    return SizedBox(
      height: height,
      // In schmalen Karten verkleinern statt überlaufen.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: switch (picture.kind) {
          'clock' => _Clock(v, height: height),
          'cal' => _Calendar(v, height: height),
          'week' => _Week(v, height: height),
          'price' => _Tag('Fr. $v', height: height),
          'text' => _Tag(v, height: height, sign: true),
          'icon' => _icon(v, height * 0.62),
          'icons' => _icons(v.split(','), height),
          'count' => _count(v, height),
          _ => Text(v, style: serif(22)),
        },
      ),
    );
  }

  Widget _icon(String name, double size) => Icon(
    fideIcons[name.trim()] ?? Icons.help_outline_rounded,
    size: size,
    color: LeoColors.chocolate,
  );

  Widget _icons(List<String> names, double h) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final n in names) _icon(n, names.length > 2 ? h * 0.36 : h * 0.44),
    ],
  );

  Widget _count(String v, double h) {
    final i = v.indexOf(':');
    final n = int.tryParse(i < 0 ? v : v.substring(0, i)) ?? 1;
    final name = i < 0 ? 'person' : v.substring(i + 1);
    // Bis 3 in einer Reihe, sonst zwei Reihen – gut zu zählen.
    final rows = n <= 3 ? 1 : 2;
    final perRow = (n / rows).ceil();
    final size = rows == 1 ? h * 0.46 : h * 0.38;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var k = r * perRow; k < min(n, (r + 1) * perRow); k++)
                _icon(name, size),
            ],
          ),
      ],
    );
  }
}

/// Namen → Zeichen. Neue Gegenstände hier ergänzen.
const Map<String, IconData> fideIcons = {
  // Essen und Trinken
  'bread': Icons.bakery_dining_outlined,
  'toast': Icons.breakfast_dining_outlined,
  'cake': Icons.cake_outlined,
  'cookie': Icons.cookie_outlined,
  'icecream': Icons.icecream_outlined,
  'egg': Icons.egg_outlined,
  'pizza': Icons.local_pizza_outlined,
  'pasta': Icons.dinner_dining_outlined,
  'burger': Icons.lunch_dining_outlined,
  'soup': Icons.soup_kitchen_outlined,
  'ramen': Icons.ramen_dining_outlined,
  'rice': Icons.rice_bowl_outlined,
  'fish': Icons.set_meal_outlined,
  'salad': Icons.eco_outlined,
  'coffee': Icons.local_cafe_outlined,
  'tea': Icons.emoji_food_beverage_outlined,
  'water': Icons.local_drink_outlined,
  'wine': Icons.wine_bar_outlined,
  'beer': Icons.sports_bar_outlined,
  'takeaway': Icons.takeout_dining_outlined,
  'restaurant': Icons.restaurant_outlined,
  'grill': Icons.outdoor_grill_outlined,
  'fridge': Icons.kitchen_outlined,
  'nofood': Icons.no_food_outlined,
  // Einkaufen und Bezahlen
  'cart': Icons.shopping_cart_outlined,
  'basket': Icons.shopping_basket_outlined,
  'bag': Icons.shopping_bag_outlined,
  'shop': Icons.storefront_outlined,
  'cash': Icons.payments_outlined,
  'card': Icons.credit_card_outlined,
  'phone': Icons.smartphone_outlined,
  'call': Icons.phone_in_talk_outlined,
  'laptop': Icons.laptop_outlined,
  'mail': Icons.mail_outline_rounded,
  'receipt': Icons.receipt_long_outlined,
  'delivery': Icons.delivery_dining_outlined,
  'scale': Icons.scale_outlined,
  'gift': Icons.card_giftcard_outlined,
  // Orte und Menschen
  'person': Icons.person_outline_rounded,
  'family': Icons.family_restroom_outlined,
  'child': Icons.child_care_outlined,
  'home': Icons.home_outlined,
  'house': Icons.house_outlined,
  'building': Icons.apartment_outlined,
  'terrace': Icons.deck_outlined,
  'table': Icons.table_restaurant_outlined,
  'window': Icons.window_outlined,
  'bar': Icons.local_bar_outlined,
  'park': Icons.park_outlined,
  'party': Icons.celebration_outlined,
  'school': Icons.school_outlined,
  'work': Icons.work_outline_rounded,
  'doctor': Icons.medical_services_outlined,
  'pharmacy': Icons.local_pharmacy_outlined,
  'sick': Icons.sick_outlined,
  // Unterwegs und Wetter
  'bus': Icons.directions_bus_outlined,
  'train': Icons.train_outlined,
  'tram': Icons.tram_outlined,
  'bike': Icons.pedal_bike_outlined,
  'walk': Icons.directions_walk_outlined,
  'car': Icons.directions_car_outlined,
  'sun': Icons.wb_sunny_outlined,
  'rain': Icons.umbrella_outlined,
  'snow': Icons.ac_unit_outlined,
};

/// Uhr mit Zeigern und – wie im Heft – der Digitalanzeige darunter.
class _Clock extends StatelessWidget {
  const _Clock(this.value, {required this.height});

  final String value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final parts = value.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final d = height * 0.66;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size.square(d), painter: _ClockPainter(h, m)),
        SizedBox(height: height * 0.05),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: height * 0.06,
            vertical: height * 0.01,
          ),
          decoration: BoxDecoration(
            color: LeoColors.brightWhite,
            borderRadius: organicRadius(5, base: 6),
            border: Border.all(color: LeoColors.chocolate, width: 1.6),
          ),
          child: Text(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
            style: sans(height * 0.13, weight: 700, height: 1.1),
          ),
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.h, this.m);

  final int h;
  final int m;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final ink = Paint()
      ..color = LeoColors.chocolate
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, Paint()..color = LeoColors.brightWhite);
    canvas.drawCircle(c, r, ink..strokeWidth = 2.4);
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final long = i % 3 == 0;
      final dir = Offset(sin(a), -cos(a));
      canvas.drawLine(
        c + dir * (r * (long ? 0.78 : 0.84)),
        c + dir * (r * 0.93),
        ink..strokeWidth = long ? 2.4 : 1.6,
      );
    }
    final ha = ((h % 12) + m / 60) * pi / 6;
    final ma = m * pi / 30;
    canvas.drawLine(
      c,
      c + Offset(sin(ha), -cos(ha)) * (r * 0.5),
      ink..strokeWidth = 4.2,
    );
    canvas.drawLine(
      c,
      c + Offset(sin(ma), -cos(ma)) * (r * 0.76),
      ink..strokeWidth = 2.6,
    );
    canvas.drawCircle(c, 3.2, Paint()..color = LeoColors.chocolate);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.h != h || old.m != m;
}

const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Monatskalender mit markierten Tagen.
class _Calendar extends StatelessWidget {
  const _Calendar(this.value, {required this.height});

  final String value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final at = value.indexOf('@');
    final offset = at < 0 ? 1 : (int.tryParse(value.substring(at + 1)) ?? 1);
    final marked = {
      for (final d in (at < 0 ? value : value.substring(0, at)).split(','))
        ?int.tryParse(d.trim()),
    };
    final rows = ((offset + 31) / 7).ceil();
    final cell = min(height / (rows + 1.2), 30.0);
    Widget box(String label, {bool head = false, bool mark = false}) =>
        Container(
          width: cell,
          height: cell,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: mark
                ? LeoColors.lemonGrass
                : (head ? LeoColors.sand : LeoColors.brightWhite),
            border: Border.all(color: LeoColors.woodAsh, width: 0.8),
          ),
          child: Text(
            label,
            style: sans(
              cell * 0.42,
              weight: mark || head ? 720 : 480,
              height: 1,
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final d in _days) box(d, head: true)],
        ),
        for (var r = 0; r < rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < 7; c++)
                () {
                  final day = r * 7 + c - offset + 1;
                  return day < 1 || day > 31
                      ? box('')
                      : box('$day', mark: marked.contains(day));
                }(),
            ],
          ),
      ],
    );
  }
}

/// Wochentage Mo–So, die genannten markiert.
class _Week extends StatelessWidget {
  const _Week(this.value, {required this.height});

  final String value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final marked = {for (final d in value.split(',')) d.trim().toLowerCase()};
    final cell = min(height * 0.3, 40.0);
    Widget day(String d) {
      final on = marked.contains(d.toLowerCase());
      return Container(
        width: cell,
        height: cell * 1.1,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? LeoColors.lemonGrass : LeoColors.brightWhite,
          borderRadius: organicRadius(d.hashCode, base: 6),
          border: Border.all(color: LeoColors.chocolate, width: 1.2),
        ),
        child: Text(
          d,
          style: sans(cell * 0.4, weight: on ? 760 : 480, height: 1),
        ),
      );
    }

    // Zwei Reihen (Mo–Do, Fr–So): passt auch in schmale Karten.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final d in _days.take(4)) day(d)],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final d in _days.skip(4)) day(d)],
        ),
      ],
    );
  }
}

/// Preisschild (leicht schräg, mit Loch) oder ein einfaches Schild.
class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.height, this.sign = false});

  final String label;
  final double height;
  final bool sign;

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      padding: EdgeInsets.fromLTRB(
        sign ? height * 0.12 : height * 0.2,
        height * 0.08,
        height * 0.12,
        height * 0.08,
      ),
      decoration: BoxDecoration(
        color: sign ? LeoColors.brightWhite : LeoColors.vanillaIce,
        borderRadius: organicRadius(label.hashCode, base: 10),
        border: Border.all(color: LeoColors.chocolate, width: 1.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!sign) ...[
            Container(
              width: height * 0.07,
              height: height * 0.07,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LeoColors.coconutMilk,
                border: Border.all(color: LeoColors.chocolate, width: 1.4),
              ),
            ),
            SizedBox(width: height * 0.08),
          ],
          Text(label, style: serif(height * 0.2, weight: 560)),
        ],
      ),
    );
    return sign ? tag : Transform.rotate(angle: -0.08, child: tag);
  }
}
