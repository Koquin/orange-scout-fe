import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gameScreen.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';

class SelectTeamsNStarters extends StatefulWidget {
  final String gameMode;
  final VoidCallback onBack;

  const SelectTeamsNStarters({Key? key, required this.gameMode, required this.onBack}) : super(key: key);

  @override
  _SelectTeamsNStartersState createState() => _SelectTeamsNStartersState();
}

class _SelectTeamsNStartersState extends State<SelectTeamsNStarters> {
  List<dynamic> teams = [];
  int team1Index = 0;
  int team2Index = 1;
  List<dynamic> playersTeam1 = [];
  List<dynamic> playersTeam2 = [];
  List<dynamic> selectedPlayersTeam1 = [];
  List<dynamic> selectedPlayersTeam2 = [];
  String endPointTeam = "http://192.168.18.31:8080/team";
  String endPointPlayer = "http://192.168.18.31:8080/player";

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    String? token = await loadToken();
    if (token == null) {
      print("Error: Token is null");
      return;
    }

    final response = await http.get(
      Uri.parse(endPointTeam),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("Requisition successful, status code = 200");
      setState(() {
        teams = jsonDecode(response.body);
      });

      if (teams.length >= 2) {
        fetchPlayers(teams[team1Index]['id'], isTeam1: true);
        fetchPlayers(teams[team2Index]['id'], isTeam1: false);
      }
    }
  }

  Future<void> fetchPlayers(int teamId, {required bool isTeam1}) async {
    String? token = await loadToken();
    if (token == null) {
      print("Error: Token is null");
      return;
    }
    final response = await http.get(
      Uri.parse('$endPointPlayer/$teamId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        List<dynamic> players = jsonDecode(response.body);
        if (isTeam1) {
          playersTeam1 = players;
          selectedPlayersTeam1 = players.length >= 5 ? players.sublist(0, 5) : List.from(players);
        } else {
          playersTeam2 = players;
          selectedPlayersTeam2 = players.length >= 5 ? players.sublist(0, 5) : List.from(players);
        }
      });
    }
  }

  void showPlayerSelectionDialog(int index, bool isTeam1, List<dynamic> availablePlayers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select player", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      title: Text(availablePlayers[i]['playerName'] ?? "Unknown player"),
                      subtitle: Text("Jersey: ${availablePlayers[i]['jerseyNumber']?.toString() ?? '-'}"),
                      onTap: () {
                        setState(() {
                          if (isTeam1) {
                            selectedPlayersTeam1[index] = availablePlayers[i];
                          } else {
                            selectedPlayersTeam2[index] = availablePlayers[i];
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void changeTeam(bool isNext, bool isTeam1) {
    setState(() {
      if (isTeam1) {
        do {
          team1Index = (team1Index + (isNext ? 1 : -1)) % teams.length;
          if (team1Index < 0) team1Index = teams.length - 1;
        } while (team1Index == team2Index);
        fetchPlayers(teams[team1Index]['id'], isTeam1: true);
      } else {
        do {
          team2Index = (team2Index + (isNext ? 1 : -1)) % teams.length;
          if (team2Index < 0) team2Index = teams.length - 1;
        } while (team2Index == team1Index);
        fetchPlayers(teams[team2Index]['id'], isTeam1: false);
      }
    });
  }

  Widget buildTeamSelection(bool isTeam1) {
    int teamIndex = isTeam1 ? team1Index : team2Index;
    List<dynamic> selectedPlayers = isTeam1 ? selectedPlayersTeam1 : selectedPlayersTeam2;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => changeTeam(false, isTeam1),
              child: Image.asset("assets/images/arrow_left.png", width: 30, height: 30),
            ),
            Column(
              children: [
                Text(
                  teams[teamIndex]['teamName'],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Image.asset("assets/images/TeamShieldIcon-cutout.png", width: 50, height: 50),
              ],
            ),
            GestureDetector(
              onTap: () => changeTeam(true, isTeam1),
              child: Image.asset("assets/images/arrow.png", width: 30, height: 30),
            ),
          ],
        ),
        SizedBox(height: 10),
        buildPlayersGrid(selectedPlayers, isTeam1),
      ],
    );
  }

  Widget buildPlayersGrid(List<dynamic> selectedPlayers, bool isTeam1) {
    int playerCount = widget.gameMode == "5x5" ? 5 : widget.gameMode == "3x3" ? 3 : 1;
    List<dynamic> availablePlayers = isTeam1 ? playersTeam1 : playersTeam2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        playerCount,
            (index) => GestureDetector(
          onTap: () => showPlayerSelectionDialog(index, isTeam1, availablePlayers),
          child: Container(
            margin: EdgeInsets.all(4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              selectedPlayers.length > index && selectedPlayers[index] != null
                  ? (selectedPlayers[index]['jerseyNumber']?.toString() ?? '-')
                  : '-',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  void startGame() {
    Map<int, Map<String, int>> playerStats = {};

    for (var player in selectedPlayersTeam1 + selectedPlayersTeam2) {
      playerStats[player.id] = {
        "three_pointer": 0,
        "two_pointer": 0,
        "one_pointer": 0,
        "missed_three_pointer": 0,
        "missed_two_pointer": 0,
        "missed_one_pointer": 0,
        "steal": 0,
        "turnover": 0,
        "block": 0,
        "assist": 0,
        "offensive_rebound": 0,
        "defensive_rebound": 0,
        "foul": 0,
      };
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          team1: teams[team1Index],
          team2: teams[team2Index],
          startersTeam1: selectedPlayersTeam1,
          startersTeam2: selectedPlayersTeam2,
          gameMode: widget.gameMode,
          playerStats: {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: teams.length < 2
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildTeamSelection(true),
          ElevatedButton(
            onPressed: (selectedPlayersTeam1.isNotEmpty && selectedPlayersTeam2.isNotEmpty)
                ? startGame
                : null,
            child: Text("START"),
          ),
          buildTeamSelection(false),
        ],
      ),
    );
  }
}
