import 'package:flutter/material.dart';

class PatientListView extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<PatientListView> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedGender = '전체';
  RangeValues _selectedAgeRange = const RangeValues(0, 100);

  // 날짜 필터가 선택되지 않았으면 null
  String? _selectedDateFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    String tempGender = _selectedGender;
    RangeValues tempAgeRange = _selectedAgeRange;
    String? tempDateFilter = _selectedDateFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 필터 제목
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '환자 필터',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
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

                      const SizedBox(height: 20),

                      // 성별 필터
                      const Text(
                        '성별',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text('전체'),
                            selected: tempGender == '전체',
                            onSelected: (_) {
                              setModalState(() {
                                tempGender = '전체';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('남성'),
                            selected: tempGender == '남성',
                            onSelected: (_) {
                              setModalState(() {
                                tempGender = '남성';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('여성'),
                            selected: tempGender == '여성',
                            onSelected: (_) {
                              setModalState(() {
                                tempGender = '여성';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // 나이 필터
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '나이',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${tempAgeRange.start.round()}세 ~ '
                            '${tempAgeRange.end.round()}세',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
                        onChanged: (RangeValues values) {
                          setModalState(() {
                            tempAgeRange = values;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // 검사 날짜 필터
                      const Text(
                        '검사 날짜',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text('오늘 검사'),
                            selected: tempDateFilter == '오늘 검사',
                            onSelected: (selected) {
                              setModalState(() {
                                tempDateFilter =
                                    selected ? '오늘 검사' : null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('최근 7일'),
                            selected: tempDateFilter == '최근 7일',
                            onSelected: (selected) {
                              setModalState(() {
                                tempDateFilter =
                                    selected ? '최근 7일' : null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('최근 30일'),
                            selected: tempDateFilter == '최근 30일',
                            onSelected: (selected) {
                              setModalState(() {
                                tempDateFilter =
                                    selected ? '최근 30일' : null;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 초기화 및 적용 버튼
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempGender = '전체';
                                  tempAgeRange =
                                      const RangeValues(0, 100);
                                  tempDateFilter = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('초기화'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedGender = tempGender;
                                  _selectedAgeRange = tempAgeRange;
                                  _selectedDateFilter = tempDateFilter;
                                });

                                Navigator.pop(bottomSheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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

  void _clearAllFilters() {
    setState(() {
      _selectedGender = '전체';
      _selectedAgeRange = const RangeValues(0, 100);
      _selectedDateFilter = null;
    });
  }

  bool get _hasActiveFilter {
    return _selectedGender != '전체' ||
        _selectedAgeRange.start != 0 ||
        _selectedAgeRange.end != 100 ||
        _selectedDateFilter != null;
  }

  String get _filterSummary {
    final List<String> filters = [];

    if (_selectedGender != '전체') {
      filters.add('성별: $_selectedGender');
    }

    if (_selectedAgeRange.start != 0 ||
        _selectedAgeRange.end != 100) {
      filters.add(
        '나이: ${_selectedAgeRange.start.round()}'
        '~${_selectedAgeRange.end.round()}세',
      );
    }

    if (_selectedDateFilter != null) {
      filters.add(_selectedDateFilter!);
    }

    return filters.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 목록'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 검색창과 필터 버튼
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: '환자 이름 또는 환자번호 검색',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 필터 버튼
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _showFilterBottomSheet,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.filter_list),
                        ),
                      ),

                      // 필터 적용 표시
                      if (_hasActiveFilter)
                        const Positioned(
                          right: -2,
                          top: -2,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // 적용된 필터 표시
              if (_hasActiveFilter) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _filterSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearAllFilters,
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              const Expanded(
                child: Center(
                  child: Text(
                    '등록된 환자가 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}