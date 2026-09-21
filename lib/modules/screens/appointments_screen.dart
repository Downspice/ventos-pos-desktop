import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/appointments/appointments_month_calendar.dart';
import 'package:ventos_pos/widgets/appointments/show_new_appointment_drawer.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_table.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

List<String> _stringIdList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _search = '';
  String _statusTab = 'all';
  String? _employeeFilter;
  String? _serviceFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    const document = r'''
      query AppointmentsPage {
        appointments {
          id customerId startAt endAt status notes
          assignedEmployeeIds serviceIds
        }
        customers { id firstName lastName }
        services { id name }
        employees { id firstName lastName }
      }
    ''';
    return widget.app.query(document);
  }

  List<Map<String, dynamic>> _filterAppointments(_ApptData data) {
    final q = _search.trim().toLowerCase();
    return data.appointments.where((appt) {
      final status = (appt['status'] as String? ?? '').toUpperCase();
      if (_statusTab != 'all' && status != _statusTab.toUpperCase()) return false;

      final employeeIds = _stringIdList(appt['assignedEmployeeIds']);
      if (_employeeFilter != null && !employeeIds.contains(_employeeFilter)) return false;

      final serviceIds = _stringIdList(appt['serviceIds']);
      if (_serviceFilter != null && !serviceIds.contains(_serviceFilter)) return false;

      if (q.isNotEmpty) {
        final customer = data.customerNames[appt['customerId'] as String?] ?? '';
        final services = serviceIds.map((id) => data.serviceNames[id] ?? '').join(' ');
        final staff = employeeIds
            .map((id) => data.employeeNames[id] ?? '')
            .join(' ');
        final haystack = '$customer $services $staff ${appt['status']}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<AppointmentCalendarEntry>> _byDate(
    List<Map<String, dynamic>> appointments,
    _ApptData data,
  ) {
    final map = <String, List<AppointmentCalendarEntry>>{};
    for (final appt in appointments) {
      final startRaw = appt['startAt'] as String?;
      if (startRaw == null) continue;
      DateTime start;
      try {
        start = DateTime.parse(startRaw).toLocal();
      } catch (_) {
        continue;
      }
      final key = appointmentsDateKey(start);
      final serviceIds = _stringIdList(appt['serviceIds']);
      final serviceLabel = serviceIds.isEmpty ? null : data.serviceNames[serviceIds.first];
      map.putIfAbsent(key, () => []).add(
            (
              id: appt['id'] as String,
              startAt: startRaw,
              status: appt['status'] as String? ?? '',
              customerLabel: data.customerNames[appt['customerId'] as String?] ?? 'Client',
              serviceLabel: serviceLabel,
            ),
          );
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }
    return map;
  }

  void _showAppointmentDetail(Map<String, dynamic> appt, _ApptData data) {
    final customer = data.customerNames[appt['customerId'] as String?] ?? '—';
    final services = _stringIdList(appt['serviceIds'])
        .map((id) => data.serviceNames[id] ?? id)
        .join(', ');
    final staff = _stringIdList(appt['assignedEmployeeIds'])
        .map((id) => data.employeeNames[id] ?? id)
        .join(', ');

    showVentosDialog<void>(
      context: context,
      title: 'Appointment',
      description: customer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _detailRow('Status', appt['status'] as String? ?? '—'),
          _detailRow('Start', moduleFormatDateTime(appt['startAt'] as String? ?? '')),
          _detailRow('End', moduleFormatDateTime(appt['endAt'] as String? ?? '')),
          _detailRow('Services', services.isEmpty ? '—' : services),
          _detailRow('Staff', staff.isEmpty ? '—' : staff),
          _detailRow('Notes', (appt['notes'] as String?)?.trim().isNotEmpty == true ? appt['notes'] as String : '—'),
        ],
      ),
      actions: [
        VentosButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findApptById(String id, _ApptData data) {
    for (final a in data.appointments) {
      if (a['id'] == id) return a;
    }
    return null;
  }

  Future<void> _openBooking(_ApptData data, VoidCallback reload, {String? dateKey}) async {
    if (data.customers.isEmpty || data.services.isEmpty || data.employees.isEmpty) {
      await showVentosDialog<void>(
        context: context,
        title: 'Cannot book yet',
        description: 'Add at least one customer, service, and employee first.',
        body: const SizedBox.shrink(),
        actions: [
          VentosButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      );
      return;
    }
    final saved = await showNewAppointmentDrawer(
      context: context,
      app: widget.app,
      customers: data.customers,
      services: data.services,
      employees: data.employees,
      defaultDateKey: dateKey,
    );
    if (saved == true) reload();
  }

  void _goToMonth(int year, int month) => setState(() => _month = DateTime(year, month));

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<dynamic>(
      key: const ValueKey('appointments-page-v3'),
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, raw, reload) {
        if (raw is! Map<String, dynamic>) {
          WidgetsBinding.instance.addPostFrameCallback((_) => reload());
          return const Center(child: CircularProgressIndicator());
        }
        final data = _ApptData.fromJson(raw);
        final filtered = _filterAppointments(data);
        final byDate = _byDate(filtered, data);
        final todayKey = appointmentsDateKey(DateTime.now());
        final todays = byDate[todayKey] ?? const <AppointmentCalendarEntry>[];

        final total = data.appointments.length;
        int countStatus(String s) =>
            data.appointments.where((a) => (a['status'] as String? ?? '').toUpperCase() == s).length;

        return VentosPageBody(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              final monthTitle = DateFormat.yMMMM().format(_month);
              final calendarSection = _CalendarSection(
                month: _month,
                filteredCount: filtered.length,
                byDate: byDate,
                onDayTap: (dateKey) => _openBooking(data, reload, dateKey: dateKey),
                onAppointmentTap: (entry) {
                  final appt = _findApptById(entry.id, data);
                  if (appt != null) _showAppointmentDetail(appt, data);
                },
              );

              final sidebar = _Sidebar(
                month: _month,
                onPickMonth: (y, m) => setState(() => _month = DateTime(y, m)),
                todays: todays,
                scheduledCount: countStatus('SCHEDULED'),
                onAppointmentTap: (entry) {
                  final appt = _findApptById(entry.id, data);
                  if (appt != null) _showAppointmentDetail(appt, data);
                },
              );

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      title: monthTitle,
                      description: 'Manage client appointments, staff schedule, and booking requests.',
                      actions: VentosNewButton(
                        label: 'Book appointment',
                        onPressed: () => _openBooking(
                          data,
                          reload,
                          dateKey: todayKey,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          label: 'All',
                          count: total,
                          selected: _statusTab == 'all',
                          onTap: () => setState(() => _statusTab = 'all'),
                        ),
                        _StatusChip(
                          label: 'Scheduled',
                          count: countStatus('SCHEDULED'),
                          selected: _statusTab == 'SCHEDULED',
                          onTap: () => setState(() => _statusTab = 'SCHEDULED'),
                        ),
                        _StatusChip(
                          label: 'Completed',
                          count: countStatus('COMPLETED'),
                          selected: _statusTab == 'COMPLETED',
                          onTap: () => setState(() => _statusTab = 'COMPLETED'),
                        ),
                        _StatusChip(
                          label: 'Cancelled',
                          count: countStatus('CANCELLED'),
                          selected: _statusTab == 'CANCELLED',
                          onTap: () => setState(() => _statusTab = 'CANCELLED'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    VentosTableToolbar(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 260,
                                child: VentosTextField(
                                  controller: _searchController,
                                  hintText: 'Search by customer or service…',
                                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                                  onChanged: (v) => setState(() => _search = v),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: VentosSelect<String>(
                                  value: _employeeFilter ?? _allFilter,
                                  hint: 'Staff',
                                  entries: [
                                    const VentosSelectEntry(value: _allFilter, label: 'All staff'),
                                    for (final e in data.employees)
                                      VentosSelectEntry(
                                        value: e['id'] as String,
                                        label: data.employeeNames[e['id'] as String] ?? '',
                                      ),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _employeeFilter = v == null || v == _allFilter ? null : v;
                                  }),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: VentosSelect<String>(
                                  value: _serviceFilter ?? _allFilter,
                                  hint: 'Service',
                                  entries: [
                                    const VentosSelectEntry(value: _allFilter, label: 'All services'),
                                    for (final s in data.services)
                                      VentosSelectEntry(
                                        value: s['id'] as String,
                                        label: data.serviceNames[s['id'] as String] ?? '',
                                      ),
                                  ],
                                  onChanged: (v) => setState(() {
                                    _serviceFilter = v == null || v == _allFilter ? null : v;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          AppointmentsCalendarNav(
                            onFirstMonth: () => _goToMonth(_month.year, 1),
                            onPreviousMonth: () => _goToMonth(_month.year, _month.month - 1),
                            onToday: () {
                              final now = DateTime.now();
                              _goToMonth(now.year, now.month);
                            },
                            onNextMonth: () => _goToMonth(_month.year, _month.month + 1),
                            onLastMonth: () => _goToMonth(_month.year, 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: calendarSection),
                          const SizedBox(width: 16),
                          SizedBox(width: 260, child: sidebar),
                        ],
                      )
                    else ...[
                      calendarSection,
                      const SizedBox(height: 16),
                      sidebar,
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static const _allFilter = '';
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.month,
    required this.filteredCount,
    required this.byDate,
    required this.onDayTap,
    required this.onAppointmentTap,
  });

  final DateTime month;
  final int filteredCount;
  final Map<String, List<AppointmentCalendarEntry>> byDate;
  final ValueChanged<String> onDayTap;
  final void Function(AppointmentCalendarEntry appt) onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(month);
    return VentosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: VentosColors.bgWeak50,
              border: Border(bottom: BorderSide(color: VentosColors.strokeSoft)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 18, color: VentosColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule view — $monthLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$filteredCount appointment${filteredCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppointmentsMonthCalendar(
              month: month,
              appointmentsByDate: byDate,
              onDayTap: onDayTap,
              onAppointmentTap: onAppointmentTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.month,
    required this.onPickMonth,
    required this.todays,
    required this.scheduledCount,
    required this.onAppointmentTap,
  });

  final DateTime month;
  final void Function(int year, int month) onPickMonth;
  final List<AppointmentCalendarEntry> todays;
  final int scheduledCount;
  final void Function(AppointmentCalendarEntry appt) onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final quickMonths = _quickNavMonths(month);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VentosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: VentosColors.strokeSoft)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quick navigation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    VentosBadge(label: '13-month', variant: VentosBadgeVariant.gray, dense: true),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final m in quickMonths)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: VentosButton(
                          variant: m.isCurrent ? VentosButtonVariant.primary : VentosButtonVariant.outline,
                          size: VentosButtonSize.sm,
                          onPressed: () => onPickMonth(m.year, m.month),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${DateFormat.MMM().format(DateTime(m.year, m.month))} ${m.year}'),
                              if (m.isCurrent)
                                const Text('Current', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        VentosCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: VentosColors.primary),
                  SizedBox(width: 6),
                  Text("Today's overview", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(value: '${todays.length}', label: "Today's bookings"),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(value: '$scheduledCount', label: 'Scheduled'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Today's appointments", style: TextStyle(fontSize: 11, color: VentosColors.mutedForeground)),
              if (todays.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No bookings scheduled for today.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                )
              else
                for (final a in todays)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.customerLabel, style: const TextStyle(fontSize: 12)),
                    subtitle: a.serviceLabel != null ? Text(a.serviceLabel!, style: const TextStyle(fontSize: 11)) : null,
                    onTap: () => onAppointmentTap(a),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VentosColors.bgWeak50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VentosColors.strokeSoft),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: VentosColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VentosButton(
      variant: selected ? VentosButtonVariant.primary : VentosButtonVariant.outline,
      size: VentosButtonSize.sm,
      onPressed: onTap,
      child: Text('$label ($count)'),
    );
  }
}

class _QuickMonth {
  _QuickMonth({required this.year, required this.month, required this.isCurrent});

  final int year;
  final int month;
  final bool isCurrent;
}

List<_QuickMonth> _quickNavMonths(DateTime anchor) {
  return List.generate(13, (i) {
    final offset = i - 6;
    final d = DateTime(anchor.year, anchor.month + offset);
    return _QuickMonth(year: d.year, month: d.month, isCurrent: offset == 0);
  });
}

class _ApptData {
  _ApptData({
    required this.appointments,
    required this.customers,
    required this.services,
    required this.employees,
    required this.customerNames,
    required this.serviceNames,
    required this.employeeNames,
  });

  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> employees;
  final Map<String, String> customerNames;
  final Map<String, String> serviceNames;
  final Map<String, String> employeeNames;

  factory _ApptData.fromJson(Map<String, dynamic> data) {
    final customers = (data['customers'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final services = (data['services'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final employees = (data['employees'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final customerNames = <String, String>{
      for (final c in customers)
        c['id'] as String: '${c['firstName']} ${c['lastName']}'.trim(),
    };
    final serviceNames = <String, String>{
      for (final s in services) s['id'] as String: s['name'] as String? ?? '',
    };
    final employeeNames = <String, String>{
      for (final e in employees)
        e['id'] as String: '${e['firstName']} ${e['lastName']}'.trim(),
    };

    return _ApptData(
      appointments: (data['appointments'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      customers: customers,
      services: services,
      employees: employees,
      customerNames: customerNames,
      serviceNames: serviceNames,
      employeeNames: employeeNames,
    );
  }
}
