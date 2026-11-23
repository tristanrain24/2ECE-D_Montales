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

String moveNote(int move) => move == 0
    ? 'Tier held'
    : move > 0
    ? 'Rose +$move'
    : 'Fell $move';
