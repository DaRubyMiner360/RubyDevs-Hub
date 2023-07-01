import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multiselect/multiselect.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key, required this.url, required this.token});

  final String url;
  final String token;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  static List<int> _possiblePriorities = List<int>.generate(7, (i) => i + 1);
  static List<String> _possibleStatuses = [
    "done",
    "working_on",
    "todo",
    "maybe_todo",
    "need_help"
  ];

  static SharedPreferences? _prefs;

  List<dynamic> _dataList = [];
  List<dynamic> _sortedDataList = [];
  int? _sortBy = 2;
  bool _reversed = false;

  bool _adding = false;
  String _addingName = "";
  String _addingClass = "";
  String _addingStatus = "todo";
  int _addingPriority = 2;

  Future<void> fetchData() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      this._sortBy = _prefs?.getInt('sortBy') ?? this._sortBy;
      this._reversed = _prefs?.getBool('reversed') ?? this._reversed;
      _HomeworkSettingsPageState._showStatuses =
          _prefs?.getStringList('showStatuses') ??
              _HomeworkSettingsPageState._showStatuses;
    }

    final response = await http.post(
      Uri.parse(widget.url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': widget.token,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _dataList = json.decode(response.body)['all'];
        sortValues();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  static String getStatusText(String internalName) {
    if (internalName == "need_help") {
      return "Needs Help";
    } else if (internalName == "todo") {
      return "Todo";
    } else if (internalName == "maybe_todo") {
      return "Maybe Todo";
    } else if (internalName == "working_on") {
      return "Working On";
    } else if (internalName == "done") {
      return "Done";
    }
    return internalName;
  }

  static String getStatusValue(String displayName) {
    if (displayName == "Needs Help") {
      return "need_help";
    } else if (displayName == "Todo") {
      return "todo";
    } else if (displayName == "Maybe Todo") {
      return "maybe_todo";
    } else if (displayName == "Working On") {
      return "working_on";
    } else if (displayName == "Done") {
      return "done";
    }
    return displayName;
  }

  void sortValues() {
    _sortedDataList = new List<dynamic>.from(_dataList);
    if (_sortBy != 0) {
      String sortBy = "";
      switch (_sortBy) {
        case 1:
          sortBy = "name";
          break;
        case 2:
          sortBy = "class";
          break;
        case 3:
          sortBy = "priority";
          break;
        case 4:
          sortBy = "status";
          break;
        default:
          break;
      }
      _sortedDataList.sort((a, b) => a["name"].compareTo(b["name"]));
      _sortedDataList.sort((a, b) => a["status"].compareTo(b["status"]));
      _sortedDataList.sort((a, b) => a["priority"].compareTo(b["priority"]));
      _sortedDataList.sort((a, b) => a["class"].compareTo(b["class"]));
      _sortedDataList.sort((a, b) => a[sortBy].compareTo(b[sortBy]));
    }
    if (_reversed) {
      _sortedDataList = _sortedDataList.reversed.toList();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Homework"),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Tooltip(
              message: "Options",
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkSettingsPage(),
                    ),
                  );
                  fetchData();
                },
                child: Icon(Icons.settings),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Tooltip(
              message: "Clear",
              child: GestureDetector(
                onTap: () async {
                  await http.post(
                    Uri.parse(widget.url + "/homework/clear"),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, String>{
                      'token': widget.token,
                    }),
                  );
                  fetchData();
                },
                child: Icon(Icons.delete_forever),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: () {
            return fetchData();
          },
          child: ListView.builder(
            itemCount: _dataList.length +
                (_dataList.length > 0 ? 2 : 1) +
                (_adding ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0 && _dataList.length > 0) {
                if (_dataList
                        .where((e) => _HomeworkSettingsPageState._showStatuses
                            .contains(e["status"]))
                        .toList()
                        .length ==
                    0) {
                  return Container();
                }
                return Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Tooltip(
                        message: "Sort By",
                        child: DropdownButton(
                          value: _sortBy,
                          items: [
                            DropdownMenuItem(
                              child: Text("None"),
                              value: 0,
                            ),
                            DropdownMenuItem(
                              child: Text("Name"),
                              value: 1,
                            ),
                            DropdownMenuItem(
                              child: Text("Class"),
                              value: 2,
                            ),
                            DropdownMenuItem(child: Text("Priority"), value: 3),
                            DropdownMenuItem(child: Text("Status"), value: 4)
                          ],
                          onChanged: (value) async {
                            setState(() {
                              _sortBy = value;
                              sortValues();
                            });
                            await _prefs?.setInt('sortBy', _sortBy ?? 2);
                          },
                        ),
                      ),
                      Tooltip(
                        message: "Reverse",
                        child: Switch.adaptive(
                          value: _reversed,
                          onChanged: (bool value) async {
                            setState(() {
                              _reversed = value;
                              sortValues();
                            });
                            await _prefs?.setBool('reversed', _reversed);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (_adding && index == _dataList.length + 1) {
                return ListTile(
                  title: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 10.0, bottom: -10.0),
                      border: InputBorder.none,
                      hintText: 'Assignment Name',
                    ),
                    onChanged: (text) {
                      setState(() {
                        _addingName = text;
                      });
                    },
                  ),
                  subtitle: DropdownButton(
                    underline: Container(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color),
                    value: _addingStatus,
                    onChanged: (String? newValue) {
                      setState(() {
                        _addingStatus = newValue ?? "todo";
                      });
                    },
                    items: _possibleStatuses.map((e) {
                      return DropdownMenuItem(
                          value: e, child: Text(getStatusText(e)));
                    }).toList(),
                  ),
                  trailing: SizedBox(
                    height: 100,
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextField(
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.only(top: 0.0, bottom: 0.0),
                              border: InputBorder.none,
                              hintText: 'Class',
                            ),
                            onChanged: (text) {
                              setState(() {
                                _addingClass = text;
                              });
                            },
                          ),
                        ),
                        Flexible(
                          child: DropdownButton(
                            underline: Container(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                            value: _addingPriority,
                            onChanged: (int? newValue) {
                              setState(() {
                                _addingPriority = newValue ?? 2;
                              });
                            },
                            items: _possiblePriorities.map((e) {
                              return DropdownMenuItem(
                                  value: e, child: Text(e.toString()));
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (index == _dataList.length + (_adding ? 2 : 1) ||
                  _dataList.length == 0) {
                return Padding(
                  padding:
                      EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
                  child: Row(children: [
                    _adding
                        ? Expanded(
                            child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red[400],
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: () {
                              setState(() {
                                _adding = false;
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 24),
                            ),
                          ))
                        : Container(),
                    _adding ? SizedBox(width: 10) : Container(),
                    Expanded(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: _adding ? Colors.green[300] : Colors.red[400],
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        setState(() {
                          if (_adding) {
                            fetchData();
                          }
                          _adding = !_adding;
                          return;
                        });

                        await http.post(
                          Uri.parse(widget.url +
                              "/homework/add?priority=" +
                              _addingPriority.toString() +
                              "&status=" +
                              Uri.encodeComponent(_addingStatus) +
                              "&class=" +
                              Uri.encodeComponent(_addingClass) +
                              "&name=" +
                              Uri.encodeComponent(_addingName)),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, String>{
                            'token': widget.token,
                          }),
                        );
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 24),
                      ),
                    )),
                  ]),
                );
              }
              if (!_HomeworkSettingsPageState._showStatuses
                  .contains(_sortedDataList[index - 1]["status"])) {
                return Container();
              }
              return ListTile(
                title: Text(_sortedDataList[index - 1]['name']),
                subtitle:
                    Text(getStatusText(_sortedDataList[index - 1]['status'])),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                      child: Text(_sortedDataList[index - 1]['class']),
                    ),
                    Text(_sortedDataList[index - 1]['priority'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentPage(
                        assignment: _sortedDataList[index - 1],
                        url: widget.url,
                        token: widget.token,
                      ),
                    ),
                  );
                  fetchData();
                },
              );
            },
          )),
    );
  }
}

class AssignmentPage extends StatefulWidget {
  const AssignmentPage(
      {super.key,
      required this.assignment,
      required this.url,
      required this.token});

  final dynamic assignment;
  final String url;
  final String token;

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  String _name = "";
  String _class = "";
  String _status = "todo";
  int _priority = 2;

  @override
  void initState() {
    super.initState();
    _name = widget.assignment['name'];
    _class = widget.assignment['class'];
    _status = widget.assignment['status'];
    _priority = int.parse(widget.assignment['priority']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment["name"]),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Tooltip(
              message: "Remove",
              child: GestureDetector(
                onTap: () async {
                  await http.post(
                    Uri.parse(widget.url +
                        "/homework/remove?name=" +
                        Uri.encodeComponent(widget.assignment["name"]) +
                        "&class=" +
                        Uri.encodeComponent(widget.assignment["class"]) +
                        "&status=" +
                        Uri.encodeComponent(widget.assignment["status"]) +
                        "&priority=" +
                        Uri.encodeComponent(widget.assignment["priority"])),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, String>{
                      'token': widget.token,
                    }),
                  );
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.delete),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top: 10.0, bottom: -10.0),
                    border: UnderlineInputBorder(),
                    hintText: 'Assignment Name',
                  ),
                  onChanged: (text) {
                    setState(() {
                      _name = text;
                    });
                  },
                ),
                Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: TextFormField(
                      initialValue: _class,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.only(top: 10.0, bottom: -10.0),
                        border: UnderlineInputBorder(),
                        hintText: 'Class Name',
                      ),
                      onChanged: (text) {
                        setState(() {
                          _class = text;
                        });
                      },
                    )),
                Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: DropdownButton(
                    isExpanded: true,
                    value: _status,
                    onChanged: (String? newValue) {
                      setState(() {
                        _status = newValue ?? "todo";
                      });
                    },
                    items: _HomeworkPageState._possibleStatuses.map((e) {
                      return DropdownMenuItem(
                          value: e,
                          child: Text(_HomeworkPageState.getStatusText(e)));
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: DropdownButton(
                    isExpanded: true,
                    value: _priority,
                    onChanged: (int? newValue) {
                      setState(() {
                        _priority = newValue ?? 2;
                      });
                    },
                    items: _HomeworkPageState._possiblePriorities.map((e) {
                      return DropdownMenuItem(
                          value: e, child: Text(e.toString()));
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 10),
                  child: Row(children: [
                    Expanded(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red[400],
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        await http.post(
                          Uri.parse(widget.url +
                              "/homework/modify?oldName=" +
                              Uri.encodeComponent(widget.assignment["name"]) +
                              "&newPriority=" +
                              _priority.toString() +
                              "&newStatus=" +
                              Uri.encodeComponent(_status) +
                              "&newClass=" +
                              Uri.encodeComponent(_class) +
                              "&newName=" +
                              Uri.encodeComponent(_name)),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, String>{
                            'token': widget.token,
                          }),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 24),
                      ),
                    ))
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeworkSettingsPage extends StatefulWidget {
  const HomeworkSettingsPage({super.key});

  @override
  State<HomeworkSettingsPage> createState() => _HomeworkSettingsPageState();
}

class _HomeworkSettingsPageState extends State<HomeworkSettingsPage> {
  static List<String> _showStatuses = [
    "done",
    "working_on",
    "todo",
    "maybe_todo",
    "need_help"
  ];

  @override
  void initState() {
    super.initState();
    _showStatuses = _HomeworkPageState._prefs?.getStringList('showStatuses') ??
        _showStatuses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: SafeArea(
        child: Form(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: DropDownMultiSelect(
                    options: _HomeworkPageState._possibleStatuses.map((e) {
                      return _HomeworkPageState.getStatusText(e);
                    }).toList(),
                    selectedValues: _showStatuses.map((e) {
                      return _HomeworkPageState.getStatusText(e);
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _showStatuses = value.map((e) {
                          return _HomeworkPageState.getStatusValue(e);
                        }).toList();
                      });
                      await _HomeworkPageState._prefs
                          ?.setStringList('showStatuses', _showStatuses);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
