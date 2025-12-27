import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      debugShowCheckedModeBanner: false,
      home: EqubAppHome(),
    ));

// --- MAIN NAVIGATION HOLDER ---
class EqubAppHome extends StatefulWidget {
  @override
  _EqubAppHomeState createState() => _EqubAppHomeState();
}

class _EqubAppHomeState extends State<EqubAppHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    EqubWheelPage(),
    EqubHistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Wheel"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Management"),
        ],
      ),
    );
  }
}

// --- PAGE 1: THE WHEEL ---
class EqubWheelPage extends StatefulWidget {
  @override
  _EqubWheelPageState createState() => _EqubWheelPageState();
}

class _EqubWheelPageState extends State<EqubWheelPage> {
  StreamController<int> selected = StreamController<int>();
  List members = [];
  bool isLoading = true;
  bool isSpinning = false;
  final String baseUrl = "https://yeabo-backend.onrender.com";

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/members'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            members = json.decode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> markWinner(int id) async {
    await http.post(
      Uri.parse('$baseUrl/mark-winner'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );
  }

  Future<void> resetCycle() async {
    setState(() => isLoading = true);
    await http.post(Uri.parse('$baseUrl/reset-cycle'));
    await fetchMembers();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    if (members.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🎉 Cycle Complete!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: resetCycle,
                icon: Icon(Icons.refresh),
                label: Text("Restart New Cycle"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("YeAboEqub Wheel"), centerTitle: true),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text("Remaining: ${members.length}", style: TextStyle(fontSize: 18)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: members.length > 1
                  ? FortuneWheel(
                      selected: selected.stream,
                      animateFirst: false,
                      items: [
                        for (var m in members)
                          FortuneItem(child: Text(m['full_name'], style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    )
                  : Center(child: Text("Last Member: ${members[0]['full_name']}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 60)),
              onPressed: isSpinning ? null : () {
                setState(() => isSpinning = true);
                int winnerIndex = members.length > 1 ? Fortune.randomInt(0, members.length) : 0;
                if (members.length > 1) selected.add(winnerIndex);

                Future.delayed(Duration(seconds: members.length > 1 ? 5 : 1), () async {
                  String name = members[winnerIndex]['full_name'];
                  int id = members[winnerIndex]['id'];

                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Winner!"),
                      content: Text("$name won!"),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                    ),
                  );

                  await markWinner(id);
                  await fetchMembers();
                  if (mounted) setState(() => isSpinning = false);
                });
              },
              child: Text(isSpinning ? "SPINNING..." : "SPIN"),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAGE 2: HISTORY & MEMBER MANAGEMENT ---
class EqubHistoryPage extends StatefulWidget {
  @override
  _EqubHistoryPageState createState() => _EqubHistoryPageState();
}

class _EqubHistoryPageState extends State<EqubHistoryPage> {
  final String baseUrl = "https://yeabo-backend.onrender.com";
  List winners = [];
  List activeMembers = [];
  bool loading = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() => loading = true);
    try {
      final winRes = await http.get(Uri.parse('$baseUrl/winners'));
      final memRes = await http.get(Uri.parse('$baseUrl/members'));
      
      if (mounted) {
        setState(() {
          winners = json.decode(winRes.body);
          activeMembers = json.decode(memRes.body);
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing data: $e");
    }
  }

  Future<void> addMember(String name) async {
    if (name.isEmpty) return;
    await http.post(
      Uri.parse('$baseUrl/add-member'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"full_name": name}),
    );
    _nameController.clear();
    refreshData();
  }

  Future<void> deleteMember(int id) async {
    await http.delete(Uri.parse('$baseUrl/delete-member/$id'));
    refreshData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Member deleted")));
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Member"),
        content: TextField(controller: _nameController, decoration: InputDecoration(hintText: "Enter full name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              addMember(_nameController.text);
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Management"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Active"),
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
          ),
        ),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Active Members (with Delete)
                  activeMembers.isEmpty
                      ? Center(child: Text("No active members"))
                      : ListView.builder(
                          itemCount: activeMembers.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: CircleAvatar(child: Text(activeMembers[index]['full_name'][0])),
                              title: Text(activeMembers[index]['full_name']),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteMember(activeMembers[index]['id']),
                              ),
                            );
                          },
                        ),
                  // Tab 2: Winner History
                  winners.isEmpty
                      ? Center(child: Text("No winners yet!"))
                      : ListView.builder(
                          itemCount: winners.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(Icons.stars, color: Colors.amber),
                              title: Text(winners[index]['full_name']),
                              subtitle: Text("Won: ${winners[index]['draw_date']?.substring(0, 10) ?? 'N/A'}"),
                            );
                          },
                        ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMemberDialog,
          child: Icon(Icons.person_add),
        ),
      ),
    );
  }
}