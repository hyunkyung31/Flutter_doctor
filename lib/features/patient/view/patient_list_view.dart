import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/view_model/auth_view_model.dart';
import '../model/patient.dart';
import '../view_model/patient_list_view_model.dart';

final class PatientListView extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() => _PatientListViewState();
}

final class _PatientListViewState extends State<PatientListView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchKeyword = '';
  String _selectedGender = '전체';
  RangeValues _selectedAgeRange = const RangeValues(0, 100);
  String? _selectedDateFilter;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<PatientListViewModel>().loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final isSuccess = await context.read<AuthViewModel>().logout();

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      context.go('/login');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value.trim().toLowerCase();
    });
  }

  List<Patient> _applyFilters(List<Patient> patients) {
    return patients.where((patient) {
      final patientName = patient.patientName.toLowerCase();
      final patientId = patient.patientId.toLowerCase();

      final matchesSearch =
          _searchKeyword.isEmpty ||
          patientName.contains(_searchKeyword) ||
          patientId.contains(_searchKeyword);

      final matchesGender =
          _selectedGender == '전체' ||
          patient.genderText == _selectedGender;

      final matchesAge =
          patient.age >= _selectedAgeRange.start.round() &&
          patient.age <= _selectedAgeRange.end.round();

      return matchesSearch && matchesGender && matchesAge;
    }).toList();
  }

  Future<void> _showFilterBottomSheet() async {
    String tempGender = _selectedGender;
    RangeValues tempAgeRange = _selectedAgeRange;
    String? tempDateFilter = _selectedDateFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '환자 필터',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(bottomSheetContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        '성별',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        children: [
                          _GenderFilterChip(
                            label: '전체',
                            selected: tempGender == '전체',
                            onSelected: () {
                              setModalState(() {
                                tempGender = '전체';
                              });
                            },
                          ),
                          _GenderFilterChip(
                            label: '남성',
                            selected: tempGender == '남성',
                            onSelected: () {
                              setModalState(() {
                                tempGender = '남성';
                              });
                            },
                          ),
                          _GenderFilterChip(
                            label: '여성',
                            selected: tempGender == '여성',
                            onSelected: () {
                              setModalState(() {
                                tempGender = '여성';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '나이',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${tempAgeRange.start.round()}세 - '
                            '${tempAgeRange.end.round()}세',
                          ),
                        ],
                      ),

                      RangeSlider(
                        values: tempAgeRange,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        labels: RangeLabels(
                          '${tempAgeRange.start.round()}세',
                          '${tempAgeRange.end.round()}세',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            tempAgeRange = values;
                          });
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        '등록일',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DateFilterChip(
                            label: '오늘',
                            selected: tempDateFilter == '오늘',
                            onSelected: () {
                              setModalState(() {
                                tempDateFilter =
                                    tempDateFilter == '오늘' ? null : '오늘';
                              });
                            },
                          ),
                          _DateFilterChip(
                            label: '최근 7일',
                            selected: tempDateFilter == '최근 7일',
                            onSelected: () {
                              setModalState(() {
                                tempDateFilter =
                                    tempDateFilter == '최근 7일'
                                        ? null
                                        : '최근 7일';
                              });
                            },
                          ),
                          _DateFilterChip(
                            label: '최근 30일',
                            selected: tempDateFilter == '최근 30일',
                            onSelected: () {
                              setModalState(() {
                                tempDateFilter =
                                    tempDateFilter == '최근 30일'
                                        ? null
                                        : '최근 30일';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempGender = '전체';
                                  tempAgeRange = const RangeValues(0, 100);
                                  tempDateFilter = null;
                                });
                              },
                              child: const Text('초기화'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedGender = tempGender;
                                  _selectedAgeRange = tempAgeRange;
                                  _selectedDateFilter = tempDateFilter;
                                });

                                Navigator.pop(bottomSheetContext);
                              },
                              child: const Text('적용'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasActiveFilter {
    return _selectedGender != '전체' ||
        _selectedAgeRange.start != 0 ||
        _selectedAgeRange.end != 100 ||
        _selectedDateFilter != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('환자 목록'),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<PatientListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.errorMessage != null) {
            return _ErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadPatients,
            );
          }

          final filteredPatients = _applyFilters(viewModel.patients);

          return RefreshIndicator(
            onRefresh: viewModel.refreshPatients,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: '환자 이름 또는 ID 검색',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchKeyword.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();

                                    setState(() {
                                      _searchKeyword = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: _hasActiveFilter,
                      child: IconButton.filledTonal(
                        onPressed: _showFilterBottomSheet,
                        tooltip: '필터',
                        icon: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),

                if (_hasActiveFilter) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedGender != '전체')
                        _ActiveFilterChip(
                          label: _selectedGender,
                          onDeleted: () {
                            setState(() {
                              _selectedGender = '전체';
                            });
                          },
                        ),
                      if (_selectedAgeRange.start != 0 ||
                          _selectedAgeRange.end != 100)
                        _ActiveFilterChip(
                          label:
                              '${_selectedAgeRange.start.round()}-'
                              '${_selectedAgeRange.end.round()}세',
                          onDeleted: () {
                            setState(() {
                              _selectedAgeRange =
                                  const RangeValues(0, 100);
                            });
                          },
                        ),
                      if (_selectedDateFilter != null)
                        _ActiveFilterChip(
                          label: _selectedDateFilter!,
                          onDeleted: () {
                            setState(() {
                              _selectedDateFilter = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 18),

                Text(
                  '총 ${filteredPatients.length}명',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                if (filteredPatients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 72,
                        ),
                        SizedBox(height: 16),
                        Text('조건에 맞는 환자가 없습니다.'),
                      ],
                    ),
                  )
                else
                  ...filteredPatients.map(
                    (patient) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PatientCard(patient: patient),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: CircleAvatar(
          child: Text(
            patient.patientName.isNotEmpty
                ? patient.patientName.substring(0, 1)
                : '?',
          ),
        ),
        title: Text(
          patient.patientName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('환자 ID: ${patient.patientId}'),
              Text('${patient.genderText} · ${patient.age}세'),
              if (patient.chiefComplaint != null &&
                  patient.chiefComplaint!.isNotEmpty)
                Text(
                  '주호소: ${patient.chiefComplaint}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          debugPrint('선택한 환자 ID: ${patient.patientId}');
        },
      ),
    );
  }
}

final class _GenderFilterChip extends StatelessWidget {
  const _GenderFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }
}

final class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }
}

final class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onDeleted,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
    );
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}