import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Member Search App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue[700]),
      ),
      themeMode: _themeMode,
      home: MemberSearchPage(
        onToggleTheme: _toggleThemeMode,
        themeMode: _themeMode,
      ),
    );
  }
}

class MemberSearchPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final ThemeMode themeMode;

  MemberSearchPage({this.onToggleTheme, this.themeMode = ThemeMode.system});

  @override
  _MemberSearchPageState createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender = '';
  String? _selectedDataTime = '20252';
  String? _selectedRank = '';
  bool _searched = false;

  final List<Map<String, String>> _genderList = [
    {'label': '', 'value': ''},
    {'label': '男性', 'value': '1'},
    {'label': '女性', 'value': '2'},
  ];
  final List<String> _dataTimeList = ['', '20252', '20251', '20242', '20021'];
  final List<String> _rankList = ['', 'A1', 'A2', 'B1', 'B2'];
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = []; // ←検索後保持用
  List<Map<String, dynamic>> _members = [];         // ←表示リスト

  // ページネーション用
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _loadedCount = 0;
  static const int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final raw = await rootBundle.loadString('assets/members.json');
    final List<dynamic> jsonList = json.decode(raw);
    setState(() {
      _allMembers = jsonList.cast<Map<String, dynamic>>();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore &&
        _searched) {
      _loadMoreMembers();
    }
  }

  void _searchMembers() {
    if (_allMembers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('データをロード中です。')));
      return;
    }
    if (_nameController.text.isEmpty &&
        _codeController.text.isEmpty &&
        (_selectedGender == null || _selectedGender!.isEmpty) &&
        (_selectedDataTime == null || _selectedDataTime!.isEmpty) &&
        (_selectedRank == null || _selectedRank!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('少なくとも1つの検索条件を入力してください')));
      return;
    }

    final filtered = _allMembers.where((member) {
      if (_nameController.text.isNotEmpty &&
          !(member['Kana3']?.toString() ?? '').contains(_nameController.text)) {
        return false;
      }
      if (_codeController.text.isNotEmpty &&
          !(member['Number']?.toString() ?? '').startsWith(_codeController.text)) {
        return false;
      }
      if (_selectedGender != null &&
          _selectedGender!.isNotEmpty &&
          (member['Sex']?.toString() ?? '') != _selectedGender) {
        return false;
      }
      if (_selectedDataTime != null &&
          _selectedDataTime!.isNotEmpty &&
          (member['DataTime']?.toString() ?? '') != _selectedDataTime) {
        return false;
      }
      if (_selectedRank != null &&
          _selectedRank!.isNotEmpty &&
          (member['Rank']?.toString() ?? '') != _selectedRank) {
        return false;
      }
      return true;
    }).toList();

    setState(() {
      _searched = true;
      _filteredMembers = filtered;
      _members = [];
      _loadedCount = 0;
      _hasMore = true;
    });
    _loadMoreMembers(initial: true);
  }

  /// ページング補助：初回（検索直後）と追加ロードの両方で使う
  void _loadMoreMembers({bool initial = false}) {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    int start = _loadedCount;
    int end = (_loadedCount + _pageSize < _filteredMembers.length)
        ? _loadedCount + _pageSize
        : _filteredMembers.length;
    final nextMembers = _filteredMembers.sublist(start, end);

    setState(() {
      if (initial) {
        _members = nextMembers;
      } else {
        _members.addAll(nextMembers);
      }
      _loadedCount = end;
      _hasMore = _loadedCount < _filteredMembers.length;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('選手検索'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip:
            widget.themeMode == ThemeMode.dark ? 'ライトモードに切替' : 'ダークモードに切替',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(labelText: '登録番号'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: '氏名（ひらがな）'),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: '期',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 6,
                      ),
                      isDense: true,
                    ),
                    value: _selectedDataTime,
                    items:
                    _dataTimeList.map((dt) {
                      return DropdownMenuItem(
                        value: dt,
                        child: Text(dt.isEmpty ? '' : formatDataTime(dt)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDataTime = value;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: '級別',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 6,
                      ),
                      isDense: true,
                    ),
                    value: _selectedRank,
                    items:
                    _rankList.map((rank) {
                      return DropdownMenuItem(
                        value: rank,
                        child: Text(rank),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRank = value;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: '性別',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 6,
                      ),
                      isDense: true,
                    ),
                    value: _selectedGender,
                    items:
                    _genderList.map((gender) {
                      return DropdownMenuItem(
                        value: gender['value'],
                        child: Text(gender['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searchMembers,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 14),
                ),
                child: Text('Search'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _members.length + ((_searched && _hasMore) ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _members.length) {
                  return _hasMore
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox();
                }
                final member = _members[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MemberDetailPage(
                            member: member,
                            allMembers: _allMembers,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  member['Number'] ?? 'No number',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text('${member['Name'] ?? 'No name'}'),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  member['WinPointRate'] ?? 'No Data',
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  member['Rank'] ?? 'No Data',
                                  style: TextStyle(
                                    fontWeight:
                                    (member['Rank'] == 'A1')
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(member['Sex'] == '2' ? '♀️' : ''),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(member['DataTime'] ?? 'No Data'),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text(member['Kana3'] ?? 'No Data'),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('${member['Age'] ?? 'No Data'}YO'),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${member['Weight'] ?? 'No Data'}kg',
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(member['Blanch'] ?? 'No Data'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- 以下は(省略部なしで)MemberDetailPage, _LegendItem, formatDataTime関数等を元通り使用してください ---
// 省略してよい場合は先のファイルのまま
// ※ MemberDetailPageは大きく変更不要です

// ...(MemberDetailPage以降はそのまま)...

// ここから下、wrap_20250716_161332.txtの member 詳細画面部分を Map<String, dynamic>ベースに修正
class MemberDetailPage extends StatefulWidget {
  final Map<String, dynamic> member;
  final List<Map<String, dynamic>> allMembers;

  MemberDetailPage({required this.member, required this.allMembers});

  @override
  _MemberDetailPageState createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  late Map<String, dynamic> _currentMember;
  late String _selectedDataTime;
  final List<String> _dataTimeList = ['20252', '20251', '20242', '20021'];

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
    _selectedDataTime = _currentMember['DataTime'];
  }

  void _switchDataTime(String newDataTime) {
    if (newDataTime == _selectedDataTime) return;
    final candidate = widget.allMembers.firstWhere(
      (m) =>
          m['Number'] == _currentMember['Number'] &&
          m['DataTime'] == newDataTime,
      orElse: () => {},
    );
    if (candidate.isNotEmpty) {
      setState(() {
        _currentMember = candidate;
        _selectedDataTime = newDataTime;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('この期のデータはありません')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 以下はwrap_20250716_161332.txtの詳細画面コードの「DocumentSnapshot → Map<String, dynamic>」換装で全対応
    // ...（本回答の字数制約のため一部省略しますが、ファイルに沿って適宜 member['XXX'] で実装してください）...
    return Scaffold(
      appBar: AppBar(title: Text('Member Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Text('期を選択: '),
                  DropdownButton<String>(
                    value: _selectedDataTime,
                    items:
                        _dataTimeList.map((dt) {
                          return DropdownMenuItem(
                            value: dt,
                            child: Text(formatDataTime(dt)),
                          );
                        }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        _switchDataTime(newValue);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Image.network(
                _currentMember['Photo'] ?? '',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              // --- 省略部も含めwrap_20250716_161332.txt の通りにtable・chart等を配置してください ---
              // ... 以降の詳細表示部は省略せず、添付ファイル通りに記述してください ...
              // ここから下は省略せず、元のコードを全て記述してください
              // （省略部分は、前回の添付ファイルの内容をそのままご利用ください）
              // --- ここに詳細テーブルやグラフ表示のコードが続きます ---
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 期  別：${formatDataTime('${_currentMember['DataTime']}')}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' ${_currentMember['DataTime']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 氏  名：${_currentMember['Name']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' ${_currentMember['Kana3']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 登  番：${_currentMember['Number']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(child: Text('', textAlign: TextAlign.left)),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 勝  率：${_currentMember['WinPointRate']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 複勝率：${(double.parse(_currentMember['WinRate12']) * 100).toStringAsFixed(2)}%',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 1着数：${_currentMember['1stPlaceCount']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 優勝数：${_currentMember['NumberOfWins']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 2着数：${_currentMember['2ndPlaceCount']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 優出数：${_currentMember['NumberOfFinals']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 平均ST：${_currentMember['StartTiming']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 出走数：${_currentMember['NumberOfRace']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 級  別：${_currentMember['Rank']} /${_currentMember['RankPast1']}/${_currentMember['RankPast2']}/${_currentMember['RankPast3']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(child: Text('', textAlign: TextAlign.left)),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 年  齢：${_currentMember['Age']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 誕生日：${_currentMember['GBirthday']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 身  長：${_currentMember['Height']}cm',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 血液型：${_currentMember['Blood']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 体  重：${_currentMember['Weight']}kg',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(child: Text('', textAlign: TextAlign.left)),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ' 支  部：${_currentMember['Blanch']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          ' 出身地：${_currentMember['Birthplace']}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(
                    children: [
                      TableCell(child: Text('F', textAlign: TextAlign.center)),
                      TableCell(child: Text('L0', textAlign: TextAlign.center)),
                      TableCell(child: Text('L1', textAlign: TextAlign.center)),
                      TableCell(child: Text('K0', textAlign: TextAlign.center)),
                      TableCell(child: Text('K1', textAlign: TextAlign.center)),
                      TableCell(child: Text('S0', textAlign: TextAlign.center)),
                      TableCell(child: Text('S1', textAlign: TextAlign.center)),
                      TableCell(child: Text('S2', textAlign: TextAlign.center)),
                    ],
                  ),
                  TableRow(
                    children: [
                      // F
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(_currentMember['FalseStart#1']) +
                                    safeParse(_currentMember['FalseStart#2']) +
                                    safeParse(_currentMember['FalseStart#3']) +
                                    safeParse(_currentMember['FalseStart#4']) +
                                    safeParse(_currentMember['FalseStart#5']) +
                                    safeParse(_currentMember['FalseStart#6']);

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'フライング失格回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'このセルはフライングによる失格回数の合計値を示しています。',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['FalseStart#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['FalseStart#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['FalseStart#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['FalseStart#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['FalseStart#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['FalseStart#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'フライングをした選手は、そのレースから除外され、該当艇に関する舟券はすべて返還となります。\n'
                                        'フフライング回数が多くなると、以下のような罰則があります。\n'
                                        ' 1回：30日間の斡旋停止（レース出場停止）\n'
                                        ' 2回：60日間の斡旋停止\n'
                                        ' 3回：90日間の斡旋停止\n'
                                        ' 4回：180日間の斡旋停止や引退勧告\n',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(_currentMember['FalseStart#1']) +
                                  safeParse(_currentMember['FalseStart#2']) +
                                  safeParse(_currentMember['FalseStart#3']) +
                                  safeParse(_currentMember['FalseStart#4']) +
                                  safeParse(_currentMember['FalseStart#5']) +
                                  safeParse(_currentMember['FalseStart#6']);
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // L0
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['LateStartNoResponsibility#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartNoResponsibility#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartNoResponsibility#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartNoResponsibility#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartNoResponsibility#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartNoResponsibility#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任外の出遅れ回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'スタートタイミングから1秒以上遅れてスタートラインを通過した場合に適用されます。\n'
                                        'L0は「選手責任外の出遅れ」を示し、例えばエンジントラブルなど選手自身の過失ではない理由で出遅れた場合に使われます',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['LateStartNoResponsibility#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['LateStartNoResponsibility#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['LateStartNoResponsibility#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['LateStartNoResponsibility#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['LateStartNoResponsibility#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['LateStartNoResponsibility#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'L0の場合、事故点は加算されず、勝率や事故率の計算でも出走回数としてカウントされません。\n'
                                        '一方、L1（選手責任の出遅れ）は事故点が加算され、級別審査にも影響します。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['LateStartNoResponsibility#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartNoResponsibility#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartNoResponsibility#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartNoResponsibility#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartNoResponsibility#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartNoResponsibility#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // L1
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['LateStartOnResponsibility#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartOnResponsibility#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartOnResponsibility#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartOnResponsibility#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartOnResponsibility#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['LateStartOnResponsibility#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任による出遅れ回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Lとはスタートタイミングから1秒以上遅れてスタートラインを通過した場合に適用されます。\n'
                                        'L0は「選手責任の出遅れ」を示します。',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['LateStartOnResponsibility#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['LateStartOnResponsibility#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['LateStartOnResponsibility#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['LateStartOnResponsibility#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['LateStartOnResponsibility#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['LateStartOnResponsibility#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '「L1」となった場合、その選手はそのレースを欠場扱いとなり、該当艇が絡む舟券は全額返還されます。\n'
                                        'また、選手には事故点が加算され、一定期間レースへの出場停止などの罰則が科されます。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['LateStartOnResponsibility#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartOnResponsibility#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartOnResponsibility#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartOnResponsibility#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartOnResponsibility#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['LateStartOnResponsibility#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // K0
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['WithdrawNoResponsibility#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawNoResponsibility#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawNoResponsibility#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawNoResponsibility#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawNoResponsibility#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawNoResponsibility#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任外の事前欠場回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '「K0」は選手の責任によらない理由（例：病気や怪我、不可抗力によるトラブルなど）でレースに出場できなくなった場合に使われます。',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['WithdrawNoResponsibility#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['WithdrawNoResponsibility#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['WithdrawNoResponsibility#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['WithdrawNoResponsibility#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['WithdrawNoResponsibility#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['WithdrawNoResponsibility#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'その艇が絡む舟券は全額返還となります。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['WithdrawNoResponsibility#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawNoResponsibility#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawNoResponsibility#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawNoResponsibility#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawNoResponsibility#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawNoResponsibility#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // K1
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['WithdrawOnResponsibility#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawOnResponsibility#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawOnResponsibility#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawOnResponsibility#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawOnResponsibility#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['WithdrawOnResponsibility#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任による事前欠場回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '「K」は欠場（レースに出場しないこと）を示し、\n'
                                        '「1」は「選手責任」を表し、選手自身のミスや過失など、選手の責任によってレース前に欠場した場合に使われます。',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['WithdrawOnResponsibility#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['WithdrawOnResponsibility#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['WithdrawOnResponsibility#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['WithdrawOnResponsibility#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['WithdrawOnResponsibility#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['WithdrawOnResponsibility#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'K1が記録されると、その選手には事故点（通常10点）が加算され、事故率や級別審査にも影響します。\n'
                                        'また、K1となった艇が絡む舟券は全額返還されます。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['WithdrawOnResponsibility#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawOnResponsibility#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawOnResponsibility#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawOnResponsibility#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawOnResponsibility#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['WithdrawOnResponsibility#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // S0
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任外の失格回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '「S」は失格（Disqualification）を示し\n'
                                        '「0」は「選手責任外」を表し、選手の責任によらない理由（例：機械的トラブル、他艇からのもらい事故、不可抗力など）で失格となった場合に使われます',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['InvalidNoResponsibility#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['InvalidNoResponsibility#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['InvalidNoResponsibility#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['InvalidNoResponsibility#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['InvalidNoResponsibility#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['InvalidNoResponsibility#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'この場合、事故点や制裁は加算されません。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // S1
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidNoResponsibility#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任による失格回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '「S1」は選手自身の過失やミスによって失格となった場合に使われます。\n'
                                        '具体的には、転覆、落水、沈没、周回誤認、危険行為など、選手の責任でレース続行ができなくなった場合が該当します。',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '１コース: ${_currentMember['InvalidNoResponsibility#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['InvalidNoResponsibility#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['InvalidNoResponsibility#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['InvalidNoResponsibility#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['InvalidNoResponsibility#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['InvalidNoResponsibility#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'S1が記録されると、その選手には事故点（通常10点）が加算され、\n'
                                        '事故率や級別審査にも影響します。また、舟券は全額返還されます。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidNoResponsibility#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // S2
                      TableCell(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                double safeParse(String? value) =>
                                    double.tryParse(value ?? '') ?? 0;
                                final total =
                                    safeParse(
                                      _currentMember['InvalidOnObstruction#1'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidOnObstruction#2'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidOnObstruction#3'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidOnObstruction#4'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidOnObstruction#5'],
                                    ) +
                                    safeParse(
                                      _currentMember['InvalidOnObstruction#6'],
                                    );

                                return AlertDialog(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '選手責任による妨害失格回数',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '他艇を妨害したことによる選手責任の失格に該当します。\n'
                                        'S2が記録されると、その選手には事故点が15点加算されます。\n'
                                        'S2による失格の場合、舟券の全額返還は行われません。',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '1コース: ${_currentMember['InvalidOnObstruction#1'] ?? '0'}',
                                      ),
                                      Text(
                                        '２コース: ${_currentMember['InvalidOnObstruction#2'] ?? '0'}',
                                      ),
                                      Text(
                                        '３コース: ${_currentMember['InvalidOnObstruction#3'] ?? '0'}',
                                      ),
                                      Text(
                                        '４コース: ${_currentMember['InvalidOnObstruction#4'] ?? '0'}',
                                      ),
                                      Text(
                                        '５コース: ${_currentMember['InvalidOnObstruction#5'] ?? '0'}',
                                      ),
                                      Text(
                                        '６コース: ${_currentMember['InvalidOnObstruction#6'] ?? '0'}',
                                      ),
                                      Divider(height: 20, thickness: 1),
                                      Text(
                                        'コメント：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'S2は、事故点も重くペナルティが大きい失格です。',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('閉じる'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            (() {
                              double safeParse(String? value) =>
                                  double.tryParse(value ?? '') ?? 0;
                              final total =
                                  safeParse(
                                    _currentMember['InvalidOnObstruction#1'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidOnObstruction#2'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidOnObstruction#3'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidOnObstruction#4'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidOnObstruction#5'],
                                  ) +
                                  safeParse(
                                    _currentMember['InvalidOnObstruction#6'],
                                  );
                              if (total == 0) {
                                return '';
                              } else {
                                return '${total.toStringAsFixed(0)}';
                              }
                            })(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              //
              //
              Text('コース別複勝率(%)'),
              Container(
                height: 220,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42.0,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    maxY: 100,
                    barGroups: [
                      for (int i = 1; i <= 6; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  double.parse(_currentMember['WinRate12#$i']) *
                                  100,
                              color: Colors.indigo.withOpacity(0.9),
                              width: 20,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        ),
                    ],
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white,
                        // 古いバージョンはこちら
                        // getTooltipColor: (_) => Colors.white, // 背景色
                        tooltipMargin: 0,
                        // tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipRoundedRadius: 8,
                        // 代わりにこちらを使用
                        tooltipPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final course = group.x;
                          final winRate = rod.toY.toStringAsFixed(1);

                          // 進入回数を整数で表示
                          final entriesRaw =
                              _currentMember['NumberOfEntries#$course'] ?? '0';
                          final entries =
                              double.tryParse(entriesRaw.toString())?.toInt() ??
                              0;

                          return BarTooltipItem(
                            'コース: $course\n'
                            '複勝率: $winRate%\n'
                            '進入回数: ${entries}回',
                            const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              //
              //
              Text('コース別１、２、３着回数'),
              SizedBox(height: 8),
              // --- 凡例を追加 ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // ここを追加
                children: [
                  _LegendItem(color: Colors.indigo, label: '1着'),
                  SizedBox(width: 16),
                  _LegendItem(color: Colors.blue, label: '2着'),
                  SizedBox(width: 16),
                  _LegendItem(color: Colors.lightBlueAccent, label: '3着'),
                ],
              ),
              Container(
                height: 220,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42.0,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}回');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    maxY: 50,
                    barGroups: [
                      for (int i = 1; i <= 6; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  double.parse(_currentMember['1stPlace#$i']) +
                                  double.parse(_currentMember['2ndPlace#$i']) +
                                  double.parse(_currentMember['3rdPlace#$i']),
                              width: 20,
                              borderRadius: BorderRadius.circular(5),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  double.parse(_currentMember['1stPlace#$i']),
                                  Colors.indigo, // 1着
                                ),
                                BarChartRodStackItem(
                                  double.parse(_currentMember['1stPlace#$i']),
                                  double.parse(_currentMember['1stPlace#$i']) +
                                      double.parse(
                                        _currentMember['2ndPlace#$i'],
                                      ),
                                  Colors.lightBlue, // 2着
                                ),
                                BarChartRodStackItem(
                                  double.parse(_currentMember['1stPlace#$i']) +
                                      double.parse(
                                        _currentMember['2ndPlace#$i'],
                                      ),
                                  double.parse(_currentMember['1stPlace#$i']) +
                                      double.parse(
                                        _currentMember['2ndPlace#$i'],
                                      ) +
                                      double.parse(
                                        _currentMember['3rdPlace#$i'],
                                      ),
                                  Colors.lightBlueAccent, // 3着
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white,
                        // 古いバージョンはこちら
                        // getTooltipColor: (_) => Colors.white, // 背景色
                        tooltipMargin: 0,
                        // tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipRoundedRadius: 8,
                        // 代わりにこちらを使用
                        tooltipPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final course = group.x;
                          final place123 = rod.toY.toStringAsFixed(0);

                          // 進入回数を整数で表示
                          final entriesRaw =
                              _currentMember['NumberOfEntries#$course'] ?? '0';
                          final entries =
                              double.tryParse(entriesRaw.toString())?.toInt() ??
                              0;

                          return BarTooltipItem(
                            'コース: $course\n'
                            '123着: ${place123}回\n'
                            '進入回数: ${entries}回',
                            const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              //
              //              Text('スタートタイミング/コース'),
              Text('スタートタイミング/コース'),
              SizedBox(height: 8),
              Container(
                height: 220,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42.0,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toDouble().toStringAsFixed(2)}',
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    maxY: 0,
                    minY: -0.4,
                    barGroups: [
                      for (int i = 1; i <= 6; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  double.parse(_currentMember['StartTime#$i']) *
                                  -1,
                              color: Colors.transparent,
                              width: 20,
                              borderRadius: BorderRadius.circular(0),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  double.parse(_currentMember['StartTime#$i']) *
                                      -1,
                                  Colors.transparent,
                                ),
                                BarChartRodStackItem(
                                  double.parse(_currentMember['StartTime#$i']) *
                                      -1,
                                  double.parse(_currentMember['StartTime#$i']) *
                                          -1 +
                                      0.02,
                                  Colors.red,
                                ),
                              ],
                            ),
                          ],
                          // showingTooltipIndicators: [0], // これでツールチップが有効
                        ),
                    ],
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white,
                        // 古いバージョンはこちら
                        // getTooltipColor: (_) => Colors.white, // 背景色
                        tooltipMargin: -120,
                        // tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipRoundedRadius: 8,
                        // 代わりにこちらを使用
                        tooltipPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final course = group.x;
                          final startTime = rod.toY.toStringAsFixed(2);

                          // 進入回数を整数で表示
                          final entriesRaw =
                              _currentMember['NumberOfEntries#$course'] ?? '0';
                          final entries =
                              double.tryParse(entriesRaw.toString())?.toInt() ??
                              0;

                          return BarTooltipItem(
                            'コース: $course\n'
                            'Sタイム: $startTime\n'
                            '進入回数: ${entries}回',
                            const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          );
                        },
                      ),
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

//
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}

String formatDataTime(String dataTime) {
  if (dataTime.length != 5) return '不正な形式';
  final year = dataTime.substring(0, 4);
  final term = dataTime.substring(4);
  String termLabel;
  switch (term) {
    case '1':
      termLabel = '前期';
      break;
    case '2':
      termLabel = '後期';
      break;
    default:
      return '不明な期';
  }
  return '$year年$termLabel';
}
