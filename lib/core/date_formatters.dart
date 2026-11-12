import 'package:flutter/material.dart';

const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const _fullWeekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String apiTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}:00';

String displayTime(String? time) {
  if (time == null || time.isEmpty) {
    return 'Saat seçilmedi';
  }
  final parts = time.split(':');
  if (parts.length < 2) {
    return time;
  }
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

String weekdayShort(int weekday) =>
    weekday >= 1 && weekday <= 7 ? _weekdays[weekday - 1] : '—';

String weekdayName(int weekday) =>
    weekday >= 1 && weekday <= 7 ? _fullWeekdays[weekday - 1] : '—';

String monthName(int month) =>
    month >= 1 && month <= 12 ? _months[month - 1] : '';

String dateDayMonth(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}';

String weekRange(DateTime start) {
  final end = start.add(const Duration(days: 6));
  if (start.month == end.month) {
    return '${start.day} – ${end.day} ${monthName(end.month)}';
  }
  return '${start.day} ${monthName(start.month)} – '
      '${end.day} ${monthName(end.month)}';
}
