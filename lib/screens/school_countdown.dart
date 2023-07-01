import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';
import 'package:intl/intl.dart';

class SchoolCountdownPage extends StatefulWidget {
  const SchoolCountdownPage({super.key});

  @override
  State<SchoolCountdownPage> createState() => _SchoolCountdownPageState();
}

class _SchoolCountdownPageState extends State<SchoolCountdownPage> {
  static SharedPreferences? _prefs;

  DateTime? _endOfDay;
  DateTime? _endOfYear;

  Duration? _timeUntilEOD;
  Duration? _timeUntilEOY;

  Future<void> fetchPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    DateTime now = DateTime.now();

    _endOfDay = DateTime.tryParse(_prefs?.getString('endOfDay') ?? "") ??
        DateTime(now.year, now.month, now.day, 15, 0, 0);
    if (now.isAfter(_endOfDay!)) {
      _endOfDay = _endOfDay!.add(Duration(days: 1));
    }

    DateTime endOfYear =
        DateTime.tryParse(_prefs?.getString('endOfYear') ?? "") ?? _endOfDay!;
    _endOfYear = DateTime(endOfYear.year, endOfYear.month, endOfYear.day,
        _endOfDay!.hour, _endOfDay!.minute, _endOfDay!.second);
    if (now.isAfter(_endOfYear!)) {
      _endOfYear = _endOfYear!.add(Duration(days: 365));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPrefs();

    _calculateTime();
    Timer.periodic(Duration(seconds: 1), (timer) {
      _calculateTime();
    });
  }

  void _calculateTime() {
    if (_endOfDay == null || _endOfYear == null) {
      return;
    }

    DateTime now = DateTime.now();
    setState(() {
      _timeUntilEOD = _endOfDay!.difference(now);
      _timeUntilEOY = _endOfYear!.difference(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    String hoursUntilEOD = _timeUntilEOD?.inHours.toString() ?? '00';
    String minutesUntilEOD = ((_timeUntilEOD?.inMinutes ?? 0 % 60) -
                (_timeUntilEOD?.inHours ?? 0) * 60 ??
            '00')
        .toString()
        .padLeft(2, '0');
    String secondsUntilEOD = ((_timeUntilEOD?.inSeconds ?? 0 % 60) -
                (_timeUntilEOD?.inMinutes ?? 0) * 60 ??
            '00')
        .toString()
        .padLeft(2, '0');

    String daysUntilEOY = (_timeUntilEOY?.inDays ?? '00').toString();
    String hoursUntilEOY = ((_timeUntilEOY?.inHours ?? 0 % 24) -
                (_timeUntilEOY?.inDays ?? 0) * 24 ??
            '00')
        .toString()
        .padLeft(2, '0');
    String minutesUntilEOY = ((_timeUntilEOY?.inMinutes ?? 0 % 60) -
                (_timeUntilEOY?.inHours ?? 0) * 60 ??
            '00')
        .toString()
        .padLeft(2, '0');
    String secondsUntilEOY = ((_timeUntilEOY?.inSeconds ?? 0 % 60) -
                (_timeUntilEOY?.inMinutes ?? 0) * 60 ??
            '00')
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text('Countdown to 3:00 PM'),
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
                      builder: (context) => SchoolCountdownSettingsPage(),
                    ),
                  );
                  fetchPrefs();
                },
                child: Icon(Icons.settings),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Time until End of Day:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '$hoursUntilEOD:$minutesUntilEOD:$secondsUntilEOD',
              style: TextStyle(fontSize: 40.0),
            ),
            SizedBox(height: 40.0),
            Text(
              'Time until End of Year:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '$daysUntilEOY ${daysUntilEOY != 1 ? "Days" : "Day"}, $hoursUntilEOY:$minutesUntilEOY:$secondsUntilEOY',
              style: TextStyle(fontSize: 40.0),
            ),
          ],
        ),
      ),
    );
  }
}

class SchoolCountdownSettingsPage extends StatefulWidget {
  const SchoolCountdownSettingsPage({super.key});

  @override
  State<SchoolCountdownSettingsPage> createState() =>
      _SchoolCountdownSettingsPageState();
}

class _SchoolCountdownSettingsPageState
    extends State<SchoolCountdownSettingsPage> {
  double _height = 0;
  double _width = 0;

  String _setTime = "", _setDate = "";

  String _hour = "00", _minute = "00", _time = "00";

  String dateTime = "";

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        initialDatePickerMode: DatePickerMode.day,
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 1));
    if (picked != null)
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat.yMd().format(selectedDate);
      });
    await _SchoolCountdownPageState._prefs!
        .setString("endOfYear", selectedDate.toString());
  }

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      DateTime now = new DateTime.now();
      setState(() {
        selectedTime = picked;
        _hour = selectedTime.hour.toString();
        _minute = selectedTime.minute.toString();
        _time = _hour + ' : ' + _minute;
        _timeController.text = _time;
        _timeController.text = formatDate(
            DateTime(now.year, now.month, now.day, selectedTime.hour,
                selectedTime.minute),
            [hh, ':', nn, " ", am]).toString();
      });
      await _SchoolCountdownPageState._prefs!
          .setString("endOfDay", selectedTime.toString());
    }
  }

  @override
  void initState() {
    super.initState();

    DateTime now = new DateTime.now();
    _dateController.text = DateFormat.yMd().format(now);
    _timeController.text = formatDate(
        DateTime(now.year, now.month, now.day, now.hour, now.minute),
        [hh, ':', nn, " ", am]).toString();
  }

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
    dateTime = DateFormat.yMd().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Container(
        width: _width,
        height: _height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              children: <Widget>[
                Text(
                  'Choose Date',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
                InkWell(
                  onTap: () {
                    _selectDate(context);
                  },
                  child: Container(
                    width: _width / 1.7,
                    height: _height / 9,
                    margin: EdgeInsets.only(top: 30),
                    alignment: Alignment.center,
                    //decoration: BoxDecoration(color: Colors.grey[200]),
                    child: TextFormField(
                      style: TextStyle(fontSize: 40),
                      textAlign: TextAlign.center,
                      enabled: false,
                      keyboardType: TextInputType.text,
                      controller: _dateController,
                      onSaved: (String? val) {
                        _setDate = val!;
                      },
                      decoration: InputDecoration(
                          disabledBorder:
                              UnderlineInputBorder(borderSide: BorderSide.none),
                          // labelText: 'Time',
                          contentPadding: EdgeInsets.only(top: 0.0)),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                Text(
                  'Choose Time',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
                InkWell(
                  onTap: () {
                    _selectTime(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 30),
                    width: _width / 1.7,
                    height: _height / 9,
                    alignment: Alignment.center,
                    //decoration: BoxDecoration(color: Colors.grey[200]),
                    child: TextFormField(
                      style: TextStyle(fontSize: 40),
                      textAlign: TextAlign.center,
                      onSaved: (String? val) {
                        _setTime = val!;
                      },
                      enabled: false,
                      keyboardType: TextInputType.text,
                      controller: _timeController,
                      decoration: InputDecoration(
                          disabledBorder:
                              UnderlineInputBorder(borderSide: BorderSide.none),
                          // labelText: 'Time',
                          contentPadding: EdgeInsets.all(5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
