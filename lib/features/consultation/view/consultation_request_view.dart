import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patient/model/patient.dart';
import '../../patient/view_model/patient_list_view_model.dart';

enum _PatientTypeFilter {
  all,
  outpatient,
  inpatient,
}

enum _GenderFilter {
  all,
  male,
  female,
}

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

final class ConsultationRequestView extends StatefulWidget {
  const ConsultationRequestView({
    super.key,
  });

  @override
  State<ConsultationRequestView> createState() {
    return _ConsultationRequestViewState();
  }
}

final class _ConsultationRequestViewState
    extends State<ConsultationRequestView> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchKeyword = '';

  _PatientTypeFilter _selectedPatientType =
      _PatientTypeFilter.all;

  _GenderFilter _selectedGender =
      _GenderFilter.all;

  _AgeFilter _selectedAge =
      _AgeFilter.all;

  DateTimeRange? _selectedDateRange;

  Patient? _selectedPatient;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<PatientListViewModel>()
          .loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword =
          value.trim().toLowerCase();
    });
  }

  String _patientTypeLabel(
    _PatientTypeFilter filter,
  ) {
    switch (filter) {
      case _PatientTypeFilter.all:
        return '전체';

      case _PatientTypeFilter.outpatient:
        return '외래';

      case _PatientTypeFilter.inpatient:
        return '입원';
    }
  }

  String _genderLabel(
    _GenderFilter filter,
  ) {
    switch (filter) {
      case _GenderFilter.all:
        return '전체';

      case _GenderFilter.male:
        return '남성';

      case _GenderFilter.female:
        return '여성';
    }
  }

  String _ageLabel(
    _AgeFilter filter,
  ) {
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

    if (_selectedPatientType !=
        _PatientTypeFilter.all) {
      count++;
    }

    if (_selectedGender !=
        _GenderFilter.all) {
      count++;
    }

    if (_selectedAge !=
        _AgeFilter.all) {
      count++;
    }

    if (_selectedDateRange != null) {
      count++;
    }

    return count;
  }

  bool _matchesGender(Patient patient) {
    if (_selectedGender ==
        _GenderFilter.all) {
      return true;
    }

    final gender =
        patient.genderText.trim().toLowerCase();

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

  bool _matchesPatientType(
    Patient patient,
  ) {
    switch (_selectedPatientType) {
      case _PatientTypeFilter.all:
        return true;

      case _PatientTypeFilter.outpatient:
        // Patient 모델에 외래/입원 필드가
        // 추가되면 실제 조건으로 변경
        return true;

      case _PatientTypeFilter.inpatient:
        // Patient 모델에 외래/입원 필드가
        // 추가되면 실제 조건으로 변경
        return true;
    }
  }

  bool _matchesDate(Patient patient) {
    if (_selectedDateRange == null) {
      return true;
    }

    // Patient 모델에 방문일 또는 등록일이
    // 추가되면 실제 날짜 조건으로 변경
    return true;
  }

  List<Patient> _applyFilters(
    List<Patient> patients,
  ) {
    return patients.where((patient) {
      return _matchesPatientType(patient) &&
          _matchesGender(patient) &&
          _matchesAge(patient) &&
          _matchesDate(patient);
    }).toList();
  }

  List<Patient> _applySearch(
    List<Patient> patients,
  ) {
    if (_searchKeyword.isEmpty) {
      return patients;
    }

    return patients.where((patient) {
      final name =
          patient.patientName.toLowerCase();

      final id =
          patient.patientId.toLowerCase();

      return name.contains(_searchKeyword) ||
          id.contains(_searchKeyword);
    }).toList();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year.$month.$day';
  }

  Future<void> _showFilterBottomSheet() async {
    var temporaryPatientType =
        _selectedPatientType;

    var temporaryGender =
        _selectedGender;

    var temporaryAge =
        _selectedAge;

    DateTimeRange? temporaryDateRange =
        _selectedDateRange;

    final result =
        await showModalBottomSheet<
            _ConsultationFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            Future<void>
                selectDateRange() async {
              final now = DateTime.now();

              final picked =
                  await showDateRangePicker(
                context: context,
                firstDate:
                    DateTime(now.year - 10),
                lastDate:
                    DateTime(now.year + 1),
                initialDateRange:
                    temporaryDateRange,
                helpText: '환자 조회 날짜 선택',
                cancelText: '취소',
                confirmText: '선택',
                saveText: '선택',
              );

              if (picked == null) {
                return;
              }

              setModalState(() {
                temporaryDateRange =
                    picked;
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .outlineVariant,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
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
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              temporaryPatientType =
                                  _PatientTypeFilter
                                      .all;

                              temporaryGender =
                                  _GenderFilter
                                      .all;

                              temporaryAge =
                                  _AgeFilter.all;

                              temporaryDateRange =
                                  null;
                            });
                          },
                          child: const Text(
                            '초기화',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const _FilterTitle(
                      title: '환자 구분',
                      icon: Icons
                          .local_hospital_outlined,
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _PatientTypeFilter
                              .values
                              .map(
                        (filter) {
                          return ChoiceChip(
                            label: Text(
                              _patientTypeLabel(
                                filter,
                              ),
                            ),
                            selected:
                                temporaryPatientType ==
                                    filter,
                            onSelected: (_) {
                              setModalState(() {
                                temporaryPatientType =
                                    filter;
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FilterTitle(
                      title: '성별',
                      icon: Icons.wc_outlined,
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _GenderFilter
                          .values
                          .map(
                        (filter) {
                          return ChoiceChip(
                            label: Text(
                              _genderLabel(
                                filter,
                              ),
                            ),
                            selected:
                                temporaryGender ==
                                    filter,
                            onSelected: (_) {
                              setModalState(() {
                                temporaryGender =
                                    filter;
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FilterTitle(
                      title: '나이',
                      icon:
                          Icons.cake_outlined,
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _AgeFilter.values.map(
                        (filter) {
                          return ChoiceChip(
                            label: Text(
                              _ageLabel(
                                filter,
                              ),
                            ),
                            selected:
                                temporaryAge ==
                                    filter,
                            onSelected: (_) {
                              setModalState(() {
                                temporaryAge =
                                    filter;
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FilterTitle(
                      title: '날짜',
                      icon: Icons
                          .calendar_month_outlined,
                    ),

                    const SizedBox(height: 10),

                    InkWell(
                      onTap: selectDateRange,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration:
                            BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .outlineVariant,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .date_range_outlined,
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Text(
                                temporaryDateRange ==
                                        null
                                    ? '날짜 범위 선택'
                                    : '${_formatDate(temporaryDateRange!.start)}'
                                        ' ~ '
                                        '${_formatDate(temporaryDateRange!.end)}',
                              ),
                            ),

                            if (temporaryDateRange !=
                                null)
                              IconButton(
                                tooltip:
                                    '날짜 초기화',
                                onPressed: () {
                                  setModalState(
                                    () {
                                      temporaryDateRange =
                                          null;
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.close,
                                ),
                              )
                            else
                              const Icon(
                                Icons
                                    .chevron_right,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(
                            bottomSheetContext,
                          ).pop(
                            _ConsultationFilterResult(
                              patientType:
                                  temporaryPatientType,
                              gender:
                                  temporaryGender,
                              age:
                                  temporaryAge,
                              dateRange:
                                  temporaryDateRange,
                            ),
                          );
                        },
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          child:
                              Text('필터 적용'),
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
      _selectedPatientType =
          result.patientType;

      _selectedGender =
          result.gender;

      _selectedAge =
          result.age;

      _selectedDateRange =
          result.dateRange;
    });
  }

  void _selectPatient(Patient patient) {
    setState(() {
      _selectedPatient = patient;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '협진 요청',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child:
            Consumer<PatientListViewModel>(
          builder: (
            context,
            viewModel,
            child,
          ) {
            if (viewModel.isLoading &&
                viewModel.patients.isEmpty) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (viewModel.errorMessage != null &&
                viewModel.patients.isEmpty) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        viewModel
                            .errorMessage!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      FilledButton.icon(
                        onPressed:
                            viewModel
                                .loadPatients,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          '다시 시도',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final patients = _applySearch(
              _applyFilters(
                viewModel.patients,
              ),
            );

            return RefreshIndicator(
              onRefresh:
                  viewModel.refreshPatients,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: [
                  Text(
                    '환자 검색',
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              _searchController,
                          onChanged:
                              _onSearchChanged,
                          decoration:
                              InputDecoration(
                            hintText:
                                '환자 이름 또는 ID 검색',
                            prefixIcon:
                                const Icon(
                              Icons.search,
                            ),
                            suffixIcon:
                                _searchKeyword
                                        .isNotEmpty
                                    ? IconButton(
                                        onPressed:
                                            () {
                                          _searchController
                                              .clear();

                                          setState(
                                            () {
                                              _searchKeyword =
                                                  '';
                                            },
                                          );
                                        },
                                        icon:
                                            const Icon(
                                          Icons.close,
                                        ),
                                      )
                                    : null,
                            filled: true,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide
                                      .none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Badge(
                        isLabelVisible:
                            _activeFilterCount >
                                0,
                        label: Text(
                          '$_activeFilterCount',
                        ),
                        child:
                            IconButton.filledTonal(
                          onPressed:
                              _showFilterBottomSheet,
                          tooltip: '환자 필터',
                          icon: const Icon(
                            Icons.tune,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (_selectedPatient !=
                      null) ...[
                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color: colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .check_circle,
                            color: colorScheme
                                .primary,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  '선택된 환자',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  _selectedPatient!
                                      .patientName,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                Text(
                                  '환자 ID: '
                                  '${_selectedPatient!.patientId}',
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedPatient =
                                    null;
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],

                  if (patients.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 70,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons
                                .person_search_outlined,
                            size: 64,
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          const Text(
                            '조건에 맞는 환자가 없습니다.',
                          ),
                        ],
                      ),
                    )
                  else
                    ...patients.map(
                      (patient) {
                        final isSelected =
                            identical(
                              _selectedPatient,
                              patient,
                            ) ||
                            _selectedPatient
                                    ?.patientId ==
                                patient.patientId;

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ListTile(
                            onTap: () {
                              _selectPatient(
                                patient,
                              );
                            },
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading:
                                CircleAvatar(
                              backgroundColor:
                                  colorScheme
                                      .primaryContainer,
                              foregroundColor:
                                  colorScheme
                                      .onPrimaryContainer,
                              child: Text(
                                patient
                                        .patientName
                                        .isNotEmpty
                                    ? patient
                                        .patientName[0]
                                    : '?',
                              ),
                            ),
                            title: Text(
                              patient.patientName
                                      .isEmpty
                                  ? '이름 미등록'
                                  : patient
                                      .patientName,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 5,
                              ),
                              child: Text(
                                '환자 ID: '
                                '${patient.patientId}\n'
                                '${patient.genderText} · '
                                '${patient.age}세',
                              ),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons
                                      .check_circle
                                  : Icons
                                      .radio_button_unchecked,
                              color: isSelected
                                  ? colorScheme
                                      .primary
                                  : colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _ConsultationFilterResult {
  const _ConsultationFilterResult({
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

final class _FilterTitle
    extends StatelessWidget {
  const _FilterTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              Theme.of(context)
                  .colorScheme
                  .primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}