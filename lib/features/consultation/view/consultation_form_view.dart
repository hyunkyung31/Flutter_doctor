import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../model/consultation_doctor.dart';
import '../view_model/consultation_view_model.dart';

final class ConsultationFormView extends StatefulWidget {
  const ConsultationFormView({super.key, required this.patient});

  final Patient patient;

  @override
  State<ConsultationFormView> createState() {
    return _ConsultationFormViewState();
  }
}

final class _ConsultationFormViewState extends State<ConsultationFormView> {
  final TextEditingController _reasonController = TextEditingController();

  final TextEditingController _memoController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDoctorId;

  String _selectedRiskLevel = 'normal';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ConsultationViewModel>().loadDoctors();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submitConsultation() async {
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수신 진료과를 선택해 주세요.')));
      return;
    }

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('협진 대상 의사를 선택해 주세요.')));
      return;
    }

    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('협진 요청 사유를 입력해 주세요.')));
      return;
    }

    final viewModel = context.read<ConsultationViewModel>();

    final success = await viewModel.createConsultation(
      patientId: widget.patient.patientId,
      receiverId: _selectedDoctorId!,
      reason: reason,
      priority: _selectedRiskLevel,
      memo: _memoController.text.trim(),
      referenceTypes: const [],
      examId: null,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? '협진 요청 전송에 실패했습니다.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('협진 요청을 전송했습니다.')));

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(title: const Text('협진 요청 작성'), centerTitle: true),
      body: SafeArea(
        child: Consumer<ConsultationViewModel>(
          builder: (context, viewModel, child) {
            final departments = viewModel.departments;

            final doctors = _selectedDepartment == null
                ? <ConsultationDoctor>[]
                : viewModel.doctorsByDepartment(_selectedDepartment!);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                Text(
                  '선택한 환자',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Text(
                          patient.patientName.isEmpty
                              ? '?'
                              : patient.patientName[0],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.patientName.isEmpty
                                  ? '이름 미등록'
                                  : patient.patientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('환자 ID: ${patient.patientId}'),
                            Text(
                              '${patient.genderText} · '
                              '${patient.age}세',
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: colorScheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '협진 대상',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (viewModel.isLoading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('의사 목록을 불러오는 중입니다.'),
                      ],
                    ),
                  )
                else if (viewModel.errorMessage != null &&
                    viewModel.doctors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: viewModel.loadDoctors,
                          icon: const Icon(Icons.refresh),
                          label: const Text('의사 목록 다시 불러오기'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDepartment,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '수신 진료과',
                      hintText: '진료과를 선택하세요.',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: departments.map((department) {
                      return DropdownMenuItem<String>(
                        value: department,
                        child: Text(
                          department,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: viewModel.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedDepartment = value;
                              _selectedDoctorId = null;
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDoctorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '협진 대상 의사',
                      hintText: '의사를 선택하세요.',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: doctors.map((doctor) {
                      final hospitalName = doctor.hospitalName.trim();

                      final label = hospitalName.isEmpty
                          ? doctor.doctorName
                          : '${doctor.doctorName} · '
                                '$hospitalName';

                      return DropdownMenuItem<String>(
                        value: doctor.doctorId,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged:
                        _selectedDepartment == null || viewModel.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedDoctorId = value;
                            });
                          },
                  ),
                  if (_selectedDepartment != null && doctors.isEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '선택한 진료과에 등록된 의사가 없습니다.',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ],
                const SizedBox(height: 28),
                Text(
                  '협진 요청 내용',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  minLines: 4,
                  maxLines: 7,
                  enabled: !viewModel.isSubmitting,
                  decoration: const InputDecoration(
                    labelText: '협진 요청 사유',
                    hintText: '협진이 필요한 이유와 검토가 필요한 내용을 입력하세요.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  '긴급도',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'normal',
                      label: Text('일반'),
                      icon: Icon(Icons.schedule_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'high',
                      label: Text('높음'),
                      icon: Icon(Icons.warning_amber_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'urgent',
                      label: Text('긴급'),
                      icon: Icon(Icons.priority_high),
                    ),
                  ],
                  selected: {_selectedRiskLevel},
                  onSelectionChanged: viewModel.isSubmitting
                      ? null
                      : (selection) {
                          setState(() {
                            _selectedRiskLevel = selection.first;
                          });
                        },
                ),
                const SizedBox(height: 28),
                Text(
                  '추가 메모',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _memoController,
                  minLines: 4,
                  maxLines: 8,
                  enabled: !viewModel.isSubmitting,
                  decoration: const InputDecoration(
                    labelText: '추가 메모 및 회신 요청 사항',
                    hintText: '검토가 필요한 부분이나 회신받고 싶은 내용을 입력하세요.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: viewModel.isLoading || viewModel.isSubmitting
                      ? null
                      : _submitConsultation,
                  icon: viewModel.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      viewModel.isSubmitting ? '전송 중...' : '협진 요청 보내기',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
