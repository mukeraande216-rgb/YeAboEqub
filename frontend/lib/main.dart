import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: EqubWheel(),
    ));

class EqubWheel extends StatefulWidget {
  @override
  _EqubWheelState createState() => _EqubWheelState();
}

class _EqubWheelState extends State<EqubWheel> {
  StreamController<int> selected = StreamController<int>();
  List members = [];
  bool isLoading = true;
  bool isSpinning = false;

  // YOUR PRODUCTION API URL
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
        setState(() {
          members = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching members: $e");
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
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (members.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🎉 Cycle Complete!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("All members have won."),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: resetCycle,
                icon: Icon(Icons.refresh),
                label: Text("Restart New Cycle"),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("YeAboEqub Digital Wheel"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text("Remaining Members: ${members.length}",
              style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: members.length > 1
                  ? FortuneWheel(
                      selected: selected.stream,
                      animateFirst: false,
                      items: [
                        for (var member in members)
                          FortuneItem(
                            child: Text(member['full_name'],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber, width: 2)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, size: 50, color: Colors.amber),
                            SizedBox(height: 10),
                            Text("Last Standing:",
                                style: TextStyle(fontSize: 16)),
                            Text("${members[0]['full_name']}",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSpinning ? Colors.grey : Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: Size(250, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: isSpinning
                  ? null
                  : () {
                      setState(() => isSpinning = true);
                      int winnerIndex = members.length > 1
                          ? Fortune.randomInt(0, members.length)
                          : 0;

                      if (members.length > 1) {
                        selected.add(winnerIndex);
                      }

                      Future.delayed(
                          Duration(seconds: members.length > 1 ? 5 : 1),
                          () async {
                        String winnerName = members[winnerIndex]['full_name'];
                        int winnerId = members[winnerIndex]['id'];

                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: Text("🎉 Congratulations!"),
                            content: Text("$winnerName has won the Equb!"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Continue"),
                              ),
                            ],
                          ),
                        );

                        await markWinner(winnerId);
                        await fetchMembers();
                        if (mounted) setState(() => isSpinning = false);
                      });
                    },
              child: Text(
                  isSpinning
                      ? "SPINNING..."
                      : (members.length > 1 ? "SPIN THE WHEEL" : "CLAIM FINAL WIN"),
                  style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }
}