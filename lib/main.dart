import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:rubydevs_hub/screens/homework.dart';
import 'package:rubydevs_hub/screens/school_countdown.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const App());
}

class App extends StatelessWidget {
  static var lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.red,
    ).copyWith(
      secondary: Colors.redAccent[400],
    ),
  );
  static var darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.red,
    ).copyWith(
      secondary: Colors.redAccent[400],
    ),
  );

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RubyDevs Hub',
      theme: App.lightTheme,
      darkTheme: App.darkTheme,
      home: const HomePage(title: 'Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<GridItem> items = [
    GridItem(
      header: 'Homework',
      description: 'Manage Homework',
      page: HomeworkPage(
        url: dotenv.get('URL'),
        token: dotenv.get('TOKEN'),
      ),
    ),
    GridItem(
      header: 'School Countdown',
      description: 'Counts down to the end of the school day',
      page: SchoolCountdownPage(),
    ),
    GridItem(
      header: 'Item 3',
      description: 'This is the description for item 3',
      page: ItemPage(
        header: 'Item 3',
        description: 'This is the page for item 3',
      ),
    ),
    GridItem(
      header: 'Item 4',
      description: 'This is the description for item 4',
      page: ItemPage(
        header: 'Item 4',
        description: 'This is the page for item 4',
      ),
    ),
  ];

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 4;
    } else if (screenWidth > 800) {
      return 3;
    } else if (screenWidth > 600) {
      return 2;
    } else {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item.page),
              );
            },
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    item.header,
                    style: TextStyle(fontSize: 32),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class GridItem {
  final String header;
  final String description;
  final Widget page;

  GridItem({
    required this.header,
    required this.description,
    required this.page,
  });
}

class ItemPage extends StatelessWidget {
  final String header;
  final String description;

  ItemPage({
    required this.header,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(header),
      ),
      body: Center(
        child: Text(description),
      ),
    );
  }
}
