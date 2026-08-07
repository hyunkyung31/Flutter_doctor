import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/patient.dart';
import '../view_model/patient_list_view_model.dart';
import '../widgets/patient_profile_avatar.dart';

enum _PatientTypeFilter { all, outpatient, inpatient }

enum _GenderFilter { all, male, female }

enum _AgeFilter {
  all,
  under20,
  twenties,
  thirties,
  forties,
  fifties,
  sixties,
  seventies,
  eighties,
  over90,
}

final class PatientListView extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() {
    return _PatientListViewState();
  }
}

final class _PatientListViewState extends State<PatientListView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchKeyword = '';
  int _selectedTabIndex = 0;

  _PatientTypeFilter _selectedPatientType = _PatientTypeFilter.all;

  _GenderFilter _selectedGender = _GenderFilter.all;

  _AgeFilter _selectedAge = _AgeFilter.all;

  DateTimeRange? _selectedDateRange;

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

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value.trim().toLowerCase();
    });
  }

  String _patientTypeLabel(_PatientTypeFilter filter) {
    switch (filter) {
      case _PatientTypeFilter.all:
        return '전체';

      case _PatientTypeFilter.outpatient:
        return '외래';

      case _PatientTypeFilter.inpatient:
        return '입원';
    }
  }

  String _genderLabel(_GenderFilter filter) {
    switch (filter) {
      case _GenderFilter.all:
        return '전체';

      case _GenderFilter.male:
        return '남성';

      case _GenderFilter.female:
        return '여성';
    }
  }

  String _ageLabel(_AgeFilter filter) {
    switch (filter) {
      case _AgeFilter.all:
        return '전체';

      case _AgeFilter.under20:
        return '20세 미만';

      case _AgeFilter.twenties:
        return '20대';

      case _AgeFilter.thirties:
        return '30대';

      case _AgeFilter.forties:
        return '40대';

      case _AgeFilter.fifties:
        return '50대';

      case _AgeFilter.sixties:
        return '60대';

      case _AgeFilter.seventies:
        return '70대';

      case _AgeFilter.eighties:
        return '80대';

      case _AgeFilter.over90:
        return '90대 이상';
    }
  }

  int get _activeFilterCount {
    var count = 0;

    if (_selectedPatientType != _PatientTypeFilter.all) {
      count++;
    }

    if (_selectedGender != _GenderFilter.all) {
      count++;
    }

    if (_selectedAge != _AgeFilter.all) {
      count++;
    }

    if (_selectedDateRange != null) {
      count++;
    }

    return count;
  }

  bool _matchesGender(Patient patient) {
    if (_selectedGender == _GenderFilter.all) {
      return true;
    }

    final gender = patient.genderText.trim().toLowerCase();

    switch (_selectedGender) {
      case _GenderFilter.all:
        return true;

      case _GenderFilter.male:
        return gender == '남' ||
            gender == '남성' ||
            gender == 'male' ||
            gender == 'm';

      case _GenderFilter.female:
        return gender == '여' ||
            gender == '여성' ||
            gender == 'female' ||
            gender == 'f';
    }
  }

  bool _matchesAge(Patient patient) {
    final age = patient.age;

    switch (_selectedAge) {
      case _AgeFilter.all:
        return true;

      case _AgeFilter.under20:
        return age < 20;

      case _AgeFilter.twenties:
        return age >= 20 && age <= 29;

      case _AgeFilter.thirties:
        return age >= 30 && age <= 39;

      case _AgeFilter.forties:
        return age >= 40 && age <= 49;

      case _AgeFilter.fifties:
        return age >= 50 && age <= 59;

      case _AgeFilter.sixties:
        return age >= 60 && age <= 69;

      case _AgeFilter.seventies:
        return age >= 70 && age <= 79;

      case _AgeFilter.eighties:
        return age >= 80 && age <= 89;

      case _AgeFilter.over90:
        return age >= 90;
    }
  }

  bool _matchesPatientType(Patient patient) {
    switch (_selectedPatientType) {
      case _PatientTypeFilter.all:
        return true;

      case _PatientTypeFilter.outpatient:
        // TODO:
        // Patient 모델의 실제 외래/입원 필드가 확인되면 연결.
        //
        // 예:
        // return patient.patientType == '외래';

        return true;

      case _PatientTypeFilter.inpatient:
        // TODO:
        // Patient 모델의 실제 외래/입원 필드가 확인되면 연결.
        //
        // 예:
        // return patient.patientType == '입원';

        return true;
    }
  }

  bool _matchesDate(Patient patient) {
    if (_selectedDateRange == null) {
      return true;
    }

    // TODO:
    // Patient 모델의 실제 방문일 또는 등록일 필드가 확인되면 연결.
    //
    // 예:
    //
    // final visitDate = patient.visitDate;
    //
    // return !visitDate.isBefore(
    //   _selectedDateRange!.start,
    // ) &&
    //     !visitDate.isAfter(
    //       _selectedDateRange!.end,
    //     );

    return true;
  }

  List<Patient> _applyFilters(List<Patient> patients) {
    return patients.where((patient) {
      return _matchesPatientType(patient) &&
          _matchesGender(patient) &&
          _matchesAge(patient) &&
          _matchesDate(patient);
    }).toList();
  }

  List<Patient> _applySearch(List<Patient> patients) {
    if (_searchKeyword.isEmpty) {
      return patients;
    }

    return patients.where((patient) {
      final name = patient.patientName.toLowerCase();

      final id = patient.patientId.toLowerCase();

      return name.contains(_searchKeyword) || id.contains(_searchKeyword);
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedPatientType = _PatientTypeFilter.all;

      _selectedGender = _GenderFilter.all;

      _selectedAge = _AgeFilter.all;

      _selectedDateRange = null;
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year.$month.$day';
  }

  Future<void> _showFilterBottomSheet() async {
    var temporaryPatientType = _selectedPatientType;

    var temporaryGender = _selectedGender;

    var temporaryAge = _selectedAge;

    DateTimeRange? temporaryDateRange = _selectedDateRange;

    final result = await showModalBottomSheet<_PatientFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selectDateRange() async {
              final now = DateTime.now();

              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 1),
                initialDateRange: temporaryDateRange,
                helpText: '환자 조회 날짜 선택',
                cancelText: '취소',
                confirmText: '선택',
                saveText: '선택',
              );

              if (picked == null) {
                return;
              }

              setModalState(() {
                temporaryDateRange = picked;
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

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
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              temporaryPatientType = _PatientTypeFilter.all;

                              temporaryGender = _GenderFilter.all;

                              temporaryAge = _AgeFilter.all;

                              temporaryDateRange = null;
                            });
                          },
                          child: const Text('초기화'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const _FilterSectionTitle(
                      title: '환자 구분',
                      icon: Icons.local_hospital_outlined,
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _PatientTypeFilter.values.map((filter) {
                        return ChoiceChip(
                          label: Text(_patientTypeLabel(filter)),
                          selected: temporaryPatientType == filter,
                          onSelected: (_) {
                            setModalState(() {
                              temporaryPatientType = filter;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FilterSectionTitle(
                      title: '성별',
                      icon: Icons.wc_outlined,
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _GenderFilter.values.map((filter) {
                        return ChoiceChip(
                          label: Text(_genderLabel(filter)),
                          selected: temporaryGender == filter,
                          onSelected: (_) {
                            setModalState(() {
                              temporaryGender = filter;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FilterSectionTitle(
                      title: '나이',
                      icon: Icons.cake_outlined,
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _AgeFilter.values.map((filter) {
                        return ChoiceChip(
                          label: Text(_ageLabel(filter)),
                          selected: temporaryAge == filter,
                          onSelected: (_) {
                            setModalState(() {
                              temporaryAge = filter;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FilterSectionTitle(
                      title: '날짜',
                      icon: Icons.calendar_month_outlined,
                    ),

                    const SizedBox(height: 10),

                    InkWell(
                      onTap: selectDateRange,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_outlined),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                temporaryDateRange == null
                                    ? '날짜 범위 선택'
                                    : '${_formatDate(temporaryDateRange!.start)}'
                                          ' ~ '
                                          '${_formatDate(temporaryDateRange!.end)}',
                              ),
                            ),

                            if (temporaryDateRange != null)
                              IconButton(
                                tooltip: '날짜 초기화',
                                onPressed: () {
                                  setModalState(() {
                                    temporaryDateRange = null;
                                  });
                                },
                                icon: const Icon(Icons.close),
                              )
                            else
                              const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop(
                            _PatientFilterResult(
                              patientType: temporaryPatientType,
                              gender: temporaryGender,
                              age: temporaryAge,
                              dateRange: temporaryDateRange,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('필터 적용'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPatientType = result.patientType;

      _selectedGender = result.gender;

      _selectedAge = result.age;

      _selectedDateRange = result.dateRange;
    });
  }

  void _selectPatient(Patient patient) {
    final patientId = patient.patientId.trim();

    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 ID가 없어 상세정보를 조회할 수 없습니다.')),
      );

      return;
    }

    context.read<PatientListViewModel>().addRecentPatient(patient);

    context.pushNamed(
      'patientDetail',
      pathParameters: {'patientId': patientId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        title: const Text(
          '환자 목록',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<PatientListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.patients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.patients.isEmpty) {
            return _PatientErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadPatients,
            );
          }

          final allPatients = _applySearch(_applyFilters(viewModel.patients));

          final recentPatients = _applySearch(
            _applyFilters(viewModel.recentPatients),
          );

          final displayedPatients = _selectedTabIndex == 0
              ? allPatients
              : recentPatients;

          return RefreshIndicator(
            onRefresh: viewModel.refreshPatients,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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

                    SizedBox(
                      width: 54,
                      height: 54,
                      child: Badge(
                        isLabelVisible: _activeFilterCount > 0,
                        label: Text('$_activeFilterCount'),
                        child: IconButton.filledTonal(
                          tooltip: '환자 필터',
                          onPressed: _showFilterBottomSheet,
                          icon: const Icon(Icons.tune),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_activeFilterCount > 0) ...[
                  const SizedBox(height: 12),

                  _ActiveFilterChips(
                    patientTypeLabel:
                        _selectedPatientType == _PatientTypeFilter.all
                        ? null
                        : _patientTypeLabel(_selectedPatientType),
                    genderLabel: _selectedGender == _GenderFilter.all
                        ? null
                        : _genderLabel(_selectedGender),
                    ageLabel: _selectedAge == _AgeFilter.all
                        ? null
                        : _ageLabel(_selectedAge),
                    dateLabel: _selectedDateRange == null
                        ? null
                        : '${_formatDate(_selectedDateRange!.start)}'
                              ' ~ '
                              '${_formatDate(_selectedDateRange!.end)}',
                    onReset: _resetFilters,
                  ),
                ],

                const SizedBox(height: 14),

                Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PatientTabButton(
                          title: '전체 ${allPatients.length}',
                          selected: _selectedTabIndex == 0,
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 0;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _PatientTabButton(
                          title: '최근 본 환자 ${recentPatients.length}',
                          selected: _selectedTabIndex == 1,
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTabIndex == 0 ? '전체 환자' : '최근 본 환자',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('총 ${displayedPatients.length}명'),
                  ],
                ),

                const SizedBox(height: 12),

                if (displayedPatients.isEmpty)
                  _EmptyPatientView(isRecentTab: _selectedTabIndex == 1)
                else
                  ...displayedPatients.map((patient) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PatientCard(
                        patient: patient,
                        onTap: () {
                          _selectPatient(patient);
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _PatientFilterResult {
  const _PatientFilterResult({
    required this.patientType,
    required this.gender,
    required this.age,
    required this.dateRange,
  });

  final _PatientTypeFilter patientType;
  final _GenderFilter gender;
  final _AgeFilter age;
  final DateTimeRange? dateRange;
}

final class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

final class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.patientTypeLabel,
    required this.genderLabel,
    required this.ageLabel,
    required this.dateLabel,
    required this.onReset,
  });

  final String? patientTypeLabel;
  final String? genderLabel;
  final String? ageLabel;
  final String? dateLabel;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (patientTypeLabel != null) patientTypeLabel!,
      if (genderLabel != null) genderLabel!,
      if (ageLabel != null) ageLabel!,
      if (dateLabel != null) dateLabel!,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: labels.map((label) {
              return Chip(
                label: Text(label),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
        TextButton(onPressed: onReset, child: const Text('초기화')),
      ],
    );
  }
}

final class _PatientTabButton extends StatelessWidget {
  const _PatientTabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

final class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onTap});

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: const PatientProfileAvatar(radius: 22),
        title: Text(
          patient.patientName.isEmpty ? '이름 미등록' : patient.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}

final class _EmptyPatientView extends StatelessWidget {
  const _EmptyPatientView({required this.isRecentTab});

  final bool isRecentTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(
            isRecentTab ? Icons.history : Icons.person_search_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(isRecentTab ? '최근 본 환자가 없습니다.' : '조건에 맞는 환자가 없습니다.'),
          if (isRecentTab) ...[
            const SizedBox(height: 8),
            const Text(
              '환자 상세정보를 열면 최근 본 환자에 표시됩니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

final class _PatientErrorView extends StatelessWidget {
  const _PatientErrorView({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
