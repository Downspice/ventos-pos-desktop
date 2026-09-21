import 'package:flutter/material.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/appointments/appointments_month_calendar.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

Future<bool?> showNewAppointmentDrawer({
  required BuildContext context,
  required AppRepository app,
  required List<Map<String, dynamic>> customers,
  required List<Map<String, dynamic>> services,
  required List<Map<String, dynamic>> employees,
  String? defaultDateKey,
}) {
  final formKey = GlobalKey<_NewAppointmentFormBodyState>();
  return showVentosFormDrawer(
    context: context,
    title: 'New appointment',
    description: 'Schedule a service booking for a customer and assign staff.',
    submitLabel: 'Confirm booking',
    body: _NewAppointmentFormBody(
      key: formKey,
      customers: customers,
      services: services,
      employees: employees,
      initialDateKey: defaultDateKey ?? appointmentsDateKey(DateTime.now()),
    ),
    onSubmit: () async {
      final input = formKey.currentState!.validateAndBuild();
      await app.mutate(
        r'''
          mutation CreateAppt(
            $customerId: ID!
            $startAt: String!
            $endAt: String!
            $serviceIds: [ID!]!
            $assignedEmployeeIds: [ID!]!
          ) {
            createAppointment(
              customerId: $customerId
              startAt: $startAt
              endAt: $endAt
              serviceIds: $serviceIds
              assignedEmployeeIds: $assignedEmployeeIds
            ) {
              id
            }
          }
        ''',
        input,
      );
    },
  );
}

class _NewAppointmentFormBody extends StatefulWidget {
  const _NewAppointmentFormBody({
    super.key,
    required this.customers,
    required this.services,
    required this.employees,
    required this.initialDateKey,
  });

  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> employees;
  final String initialDateKey;

  @override
  State<_NewAppointmentFormBody> createState() => _NewAppointmentFormBodyState();
}

class _NewAppointmentFormBodyState extends State<_NewAppointmentFormBody> {
  late String _customerId;
  late String _serviceId;
  late String _employeeId;
  late final TextEditingController _dateController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  final _notesController = TextEditingController();
  final _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    _customerId = widget.customers.isNotEmpty ? widget.customers.first['id'] as String : '';
    _serviceId = widget.services.isNotEmpty ? widget.services.first['id'] as String : '';
    _employeeId = widget.employees.isNotEmpty ? widget.employees.first['id'] as String : '';
    _dateController = TextEditingController(text: widget.initialDateKey);
    _startController = TextEditingController(text: '09:00');
    _endController = TextEditingController(text: '10:00');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> validateAndBuild() {
    _errors.clear();
    if (_customerId.isEmpty) _errors['customerId'] = 'Customer is required';
    if (_serviceId.isEmpty) _errors['serviceId'] = 'Service is required';
    if (_employeeId.isEmpty) _errors['employeeId'] = 'Staff member is required';

    final date = _dateController.text.trim();
    final startTime = _startController.text.trim();
    final endTime = _endController.text.trim();
    if (date.isEmpty) _errors['date'] = 'Date is required';
    if (startTime.isEmpty) _errors['startTime'] = 'Start time is required';
    if (endTime.isEmpty) _errors['endTime'] = 'End time is required';

    DateTime? startAt;
    DateTime? endAt;
    if (date.isNotEmpty && startTime.isNotEmpty) {
      startAt = _parseLocalDateTime(date, startTime);
      if (startAt == null) _errors['startTime'] = 'Invalid start time';
    }
    if (date.isNotEmpty && endTime.isNotEmpty) {
      endAt = _parseLocalDateTime(date, endTime);
      if (endAt == null) _errors['endTime'] = 'Invalid end time';
    }
    if (startAt != null && endAt != null && !endAt.isAfter(startAt)) {
      _errors['endTime'] = 'End time must be after start time';
    }

    if (_errors.isNotEmpty) {
      setState(() {});
      throw StateError(_errors.values.first);
    }

    return {
      'customerId': _customerId,
      'startAt': startAt!.toUtc().toIso8601String(),
      'endAt': endAt!.toUtc().toIso8601String(),
      'serviceIds': [_serviceId],
      'assignedEmployeeIds': [_employeeId],
    };
  }

  DateTime? _parseLocalDateTime(String dateKey, String hhmm) {
    try {
      final dateParts = dateKey.split('-');
      if (dateParts.length != 3) return null;
      final timeParts = hhmm.split(':');
      if (timeParts.length < 2) return null;
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  String? _fieldError(String key) => _errors[key];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VentosSelect<String>(
          label: 'Customer',
          value: _customerId.isEmpty ? null : _customerId,
          hint: 'Select a customer',
          entries: [
            for (final c in widget.customers)
              VentosSelectEntry(
                value: c['id'] as String,
                label: '${c['firstName']} ${c['lastName']}'.trim(),
              ),
          ],
          onChanged: (v) => setState(() {
            if (v != null) _customerId = v;
            _errors.remove('customerId');
          }),
        ),
        if (_fieldError('customerId') != null)
          _errorText(_fieldError('customerId')!),
        const SizedBox(height: 12),
        VentosSelect<String>(
          label: 'Service',
          value: _serviceId.isEmpty ? null : _serviceId,
          hint: 'Select service',
          entries: [
            for (final s in widget.services)
              VentosSelectEntry(value: s['id'] as String, label: s['name'] as String? ?? ''),
          ],
          onChanged: (v) => setState(() {
            if (v != null) _serviceId = v;
            _errors.remove('serviceId');
          }),
        ),
        if (_fieldError('serviceId') != null) _errorText(_fieldError('serviceId')!),
        const SizedBox(height: 12),
        VentosSelect<String>(
          label: 'Assigned staff',
          value: _employeeId.isEmpty ? null : _employeeId,
          hint: 'Select staff member',
          entries: [
            for (final e in widget.employees)
              VentosSelectEntry(
                value: e['id'] as String,
                label: '${e['firstName']} ${e['lastName']}'.trim(),
              ),
          ],
          onChanged: (v) => setState(() {
            if (v != null) _employeeId = v;
            _errors.remove('employeeId');
          }),
        ),
        if (_fieldError('employeeId') != null) _errorText(_fieldError('employeeId')!),
        const SizedBox(height: 12),
        VentosTextField(
          label: 'Date',
          controller: _dateController,
          hintText: 'YYYY-MM-DD',
          onChanged: (_) => _errors.remove('date'),
        ),
        if (_fieldError('date') != null) _errorText(_fieldError('date')!),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: VentosTextField(
                label: 'Start time',
                controller: _startController,
                hintText: '09:00',
                onChanged: (_) => _errors.remove('startTime'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VentosTextField(
                label: 'End time',
                controller: _endController,
                hintText: '10:00',
                onChanged: (_) => _errors.remove('endTime'),
              ),
            ),
          ],
        ),
        if (_fieldError('startTime') != null) _errorText(_fieldError('startTime')!),
        if (_fieldError('endTime') != null) _errorText(_fieldError('endTime')!),
        const SizedBox(height: 12),
        VentosTextField(
          label: 'Notes',
          controller: _notesController,
          hintText: 'Optional details or preferences…',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(message, style: TextStyle(color: VentosColors.destructive, fontSize: 12)),
    );
  }
}
