import '../data/models.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtCents(int cents) {
  final whole = (cents ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return '\$$whole.${(cents % 100).toString().padLeft(2, '0')}';
}

const annualDiscount = 0.20;

/// Amount due per billing period for a plan, in cents.
/// Null when the plan is priced on request.
int? dueCents(Plan plan, Billing billing, int seats) {
  final unit = plan.monthlyCents;
  if (unit == null) return null;
  final n = plan.perSeat ? seats : 1;
  if (billing == Billing.monthly) return unit * n;
  return (unit * n * 12 * (1 - annualDiscount)).round();
}

String periodLabel(Billing b) => b == Billing.monthly ? 'mo' : 'yr';

DateTime nextRenewal(DateTime from, Billing b) {
  if (b == Billing.annual) return DateTime(from.year + 1, from.month, from.day);
  // Clamp so 31 Jan renews on the last day of February, not in March.
  final y = from.month == 12 ? from.year + 1 : from.year;
  final m = from.month == 12 ? 1 : from.month + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, from.day > lastDay ? lastDay : from.day);
}

String moveNote(int move) => move == 0
    ? 'Tier held'
    : move > 0
    ? 'Rose +$move'
    : 'Fell $move';
