import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/view_model/auth_view_model.dart';
import '../model/patient.dart';
import '../view_model/patient_list_view_model.dart';

final class PatientListView
    extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() {
    return _PatientListViewState();
  }
}

final class _PatientListViewState
    extends State<PatientListView> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchKeyword = '';
  int _selectedTabIndex = 0;

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

  Future<void> _logout() async {
    final isSuccess =
        await context.read<AuthViewModel>().logout();

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      context.go('/login');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword =
          value.trim().toLowerCase();
    });
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

  void _selectPatient(Patient patient) {
    final patientId = patient.patientId.trim();

    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '환자 ID가 없어 상세정보를 조회할 수 없습니다.',
          ),
        ),
      );

      return;
    }

    context
        .read<PatientListViewModel>()
        .addRecentPatient(patient);

    context.pushNamed(
      'patientDetail',
      pathParameters: {
        'patientId': patientId,
      },
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<PatientListViewModel>(
        builder: (
          context,
          viewModel,
          child,
        ) {
          if (viewModel.isLoading &&
              viewModel.patients.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.errorMessage != null &&
              viewModel.patients.isEmpty) {
            return _PatientErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadPatients,
            );
          }

          final allPatients = _applySearch(
            viewModel.patients,
          );

          final recentPatients = _applySearch(
            viewModel.recentPatients,
          );

          final displayedPatients =
              _selectedTabIndex == 0
                  ? allPatients
                  : recentPatients;

          return RefreshIndicator(
            onRefresh: viewModel.refreshPatients,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24,
              ),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: '환자 이름 또는 ID 검색',
                    prefixIcon:
                        const Icon(Icons.search),
                    suffixIcon:
                        _searchKeyword.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController
                                      .clear();

                                  setState(() {
                                    _searchKeyword =
                                        '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                ),
                              )
                            : null,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  height: 50,
                  padding:
                      const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PatientTabButton(
                          title:
                              '전체 ${allPatients.length}',
                          selected:
                              _selectedTabIndex == 0,
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 0;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _PatientTabButton(
                          title:
                              '최근 본 환자 ${viewModel.recentPatients.length}',
                          selected:
                              _selectedTabIndex == 1,
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
                        _selectedTabIndex == 0
                            ? '전체 환자'
                            : '최근 본 환자',
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '총 ${displayedPatients.length}명',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (displayedPatients.isEmpty)
                  _EmptyPatientView(
                    isRecentTab:
                        _selectedTabIndex == 1,
                  )
                else
                  ...displayedPatients.map(
                    (patient) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _PatientCard(
                        patient: patient,
                        onTap: () {
                          _selectPatient(patient);
                        },
                      ),
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

final class _PatientTabButton
    extends StatelessWidget {
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
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.surface
          : Colors.transparent,
      borderRadius:
          BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(10),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface
                      .withOpacity(0.55),
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

final class _PatientCard
    extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor:
              colorScheme.primaryContainer,
          foregroundColor:
              colorScheme.onPrimaryContainer,
          child: Text(
            patient.patientName.isNotEmpty
                ? patient.patientName
                    .substring(0, 1)
                : '?',
          ),
        ),
        title: Text(
          patient.patientName.isEmpty
              ? '이름 미등록'
              : patient.patientName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '환자 ID: ${patient.patientId}',
              ),
              Text(
                '${patient.genderText} · ${patient.age}세',
              ),
              if (patient.chiefComplaint != null &&
                  patient
                      .chiefComplaint!
                      .isNotEmpty)
                Text(
                  '주호소: ${patient.chiefComplaint}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right),
      ),
    );
  }
}

final class _EmptyPatientView
    extends StatelessWidget {
  const _EmptyPatientView({
    required this.isRecentTab,
  });

  final bool isRecentTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(
            isRecentTab
                ? Icons.history
                : Icons.person_search_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            isRecentTab
                ? '최근 본 환자가 없습니다.'
                : '조건에 맞는 환자가 없습니다.',
          ),
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

final class _PatientErrorView
    extends StatelessWidget {
  const _PatientErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}