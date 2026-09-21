import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Local calendar date key `YYYY-MM-DD`.
String appointmentsDateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class AppointmentsCalendarDayCell {
  const AppointmentsCalendarDayCell({
    required this.day,
    required this.date,
    required this.dateKey,
    required this.isCurrentMonth,
  });

  final int day;
  final DateTime date;
  final String dateKey;
  final bool isCurrentMonth;
}

List<AppointmentsCalendarDayCell> buildAppointmentsCalendarDays(DateTime month) {
  final year = month.year;
  final m = month.month;
  final firstDay = DateTime(year, m, 1);
  final daysInMonth = DateTime(year, m + 1, 0).day;
  final startingDayOfWeek = firstDay.weekday % 7; // Sun=0 … Sat=6

  final cells = <AppointmentsCalendarDayCell>[];

  final prevMonthDays = DateTime(year, m, 0).day;
  for (var i = startingDayOfWeek - 1; i >= 0; i--) {
    final dayNum = prevMonthDays - i;
    final date = DateTime(year, m - 1, dayNum);
    cells.add(
      AppointmentsCalendarDayCell(
        day: dayNum,
        date: date,
        dateKey: appointmentsDateKey(date),
        isCurrentMonth: false,
      ),
    );
  }

  for (var day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, m, day);
    cells.add(
      AppointmentsCalendarDayCell(
        day: day,
        date: date,
        dateKey: appointmentsDateKey(date),
        isCurrentMonth: true,
      ),
    );
  }

  var nextMonthDay = 1;
  while (cells.length < 42) {
    final date = DateTime(year, m + 1, nextMonthDay++);
    cells.add(
      AppointmentsCalendarDayCell(
        day: date.day,
        date: date,
        dateKey: appointmentsDateKey(date),
        isCurrentMonth: false,
      ),
    );
  }

  return cells;
}

typedef AppointmentCalendarEntry = ({
  String id,
  String startAt,
  String status,
  String customerLabel,
  String? serviceLabel,
});

class AppointmentsMonthCalendar extends StatelessWidget {
  const AppointmentsMonthCalendar({
    super.key,
    required this.month,
    required this.appointmentsByDate,
    required this.onDayTap,
    required this.onAppointmentTap,
  });

  final DateTime month;
  final Map<String, List<AppointmentCalendarEntry>> appointmentsByDate;
  final ValueChanged<String> onDayTap;
  final void Function(AppointmentCalendarEntry appt) onAppointmentTap;

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final todayKey = appointmentsDateKey(DateTime.now());
    final cells = buildAppointmentsCalendarDays(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final day in _weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    day.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: VentosColors.mutedForeground,
                        ),
                  ),
                ),
              ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: 108,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) {
            final cell = cells[index];
            final isToday = cell.dateKey == todayKey;
            final dayAppts = appointmentsByDate[cell.dateKey] ?? const [];

            return _CalendarDayCell(
              cell: cell,
              isToday: isToday,
              appointments: dayAppts,
              onDayTap: () => onDayTap(cell.dateKey),
              onAppointmentTap: onAppointmentTap,
            );
          },
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.cell,
    required this.isToday,
    required this.appointments,
    required this.onDayTap,
    required this.onAppointmentTap,
  });

  final AppointmentsCalendarDayCell cell;
  final bool isToday;
  final List<AppointmentCalendarEntry> appointments;
  final VoidCallback onDayTap;
  final void Function(AppointmentCalendarEntry appt) onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final inMonth = cell.isCurrentMonth;
    final borderColor = isToday ? VentosColors.primary : VentosColors.strokeSoft;

    return Material(
      color: inMonth ? VentosColors.cardOpaque : VentosColors.bgWeak50.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: borderColor,
          width: isToday ? 2 : 1,
          style: inMonth ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDayTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? VentosColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cell.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? VentosColors.onPrimary
                            : (inMonth ? VentosColors.textStrong : VentosColors.textSoft),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (appointments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VentosColors.secondary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${appointments.length}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final appt in appointments.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _ApptChip(
                          appt: appt,
                          onTap: () => onAppointmentTap(appt),
                        ),
                      ),
                    if (appointments.length > 3)
                      Text(
                        '+${appointments.length - 3} more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: VentosColors.mutedForeground,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApptChip extends StatelessWidget {
  const _ApptChip({required this.appt, required this.onTap});

  final AppointmentCalendarEntry appt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(appt.status);
    String timeLabel = '';
    try {
      timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(DateTime.parse(appt.startAt).toLocal()),
        alwaysUse24HourFormat: false,
      );
    } catch (_) {}

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeLabel.isEmpty ? appt.customerLabel : '$timeLabel ${appt.customerLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                  height: 1.2,
                ),
              ),
              if (appt.serviceLabel != null && appt.serviceLabel!.isNotEmpty)
                Text(
                  appt.serviceLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: colors.foreground.withValues(alpha: 0.85)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

({Color background, Color border, Color foreground}) _statusColors(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return (
        background: const Color(0xFFD1FAE5),
        border: const Color(0xFFA7F3D0),
        foreground: const Color(0xFF065F46),
      );
    case 'SCHEDULED':
      return (
        background: const Color(0xFFDBEAFE),
        border: const Color(0xFFBFDBFE),
        foreground: const Color(0xFF1E40AF),
      );
    case 'CANCELLED':
      return (
        background: const Color(0xFFFFE4E6),
        border: const Color(0xFFFECDD3),
        foreground: const Color(0xFF9F1239),
      );
    case 'NO_SHOW':
      return (
        background: const Color(0xFFFEF3C7),
        border: const Color(0xFFFDE68A),
        foreground: const Color(0xFF92400E),
      );
    default:
      return (
        background: VentosColors.secondary,
        border: VentosColors.strokeSoft,
        foreground: VentosColors.textStrong,
      );
  }
}

/// Calendar month jump controls (matches web appointments toolbar).
class AppointmentsCalendarNav extends StatelessWidget {
  const AppointmentsCalendarNav({
    super.key,
    required this.onFirstMonth,
    required this.onPreviousMonth,
    required this.onToday,
    required this.onNextMonth,
    required this.onLastMonth,
  });

  final VoidCallback onFirstMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onToday;
  final VoidCallback onNextMonth;
  final VoidCallback onLastMonth;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        VentosOutlineIconButton(onPressed: onFirstMonth, icon: LucideIcons.chevrons_left),
        VentosOutlineIconButton(onPressed: onPreviousMonth, icon: LucideIcons.chevron_left),
        VentosButton(
          variant: VentosButtonVariant.outline,
          size: VentosButtonSize.sm,
          onPressed: onToday,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar_arrow_down, size: 14),
              SizedBox(width: 6),
              Text('Today'),
            ],
          ),
        ),
        VentosOutlineIconButton(onPressed: onNextMonth, icon: LucideIcons.chevron_right),
        VentosOutlineIconButton(onPressed: onLastMonth, icon: LucideIcons.chevrons_right),
      ],
    );
  }
}
