import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:orangescoutfe/view/statScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> matches = [];
  String token = 'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiVVNFUiIsInN1YiI6Im5hb3NrZWN1dUBnbWFpbC5jb20iLCJpYXQiOjE3MzkyMjM0MTUsImV4cCI6MTczOTI1OTQxNX0.E_MEgoI3iL2dKWQLhS20kTWfY6Ue-F1Jii0E9A8G9Ww';
  InterstitialAd? _interstitialAd;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    print("🟢 initState iniciado");
    _loadToken();
    print("🟢 Após _loadToken chamado");
    fetchMatches();
  }

  void _loadToken() async {
    print("🔵 _loadToken chamado");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('antes do setstate');
    setState(() {
      token = prefs.getString('auth_token') ?? '';
      print('🔵 Token carregado: $token');
    });
  }

  Future<void> fetchMatches() async {
    print("🟡 fetchMatches chamado");
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      print('🔵 Fazendo requisição para /match/user');
      final response = await http.get(
        Uri.parse('http://192.168.1.16:8080/match/user'),//coloca de volta para localhost:8080
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔵 Token enviado na requisição: $token');
      print('🔵 Status Code da resposta: ${response.statusCode}');
      print('🔵 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        print('🟢 Requisição bem-sucedida, processando dados...');
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          
          matches = data.map((match) => {
            'id': match['id'],
            'team1': match['teamOne']['abbreviation'],
            'team2': match['teamTwo']['abbreviation'],
            'score': '${match['teamOneScore']} x ${match['teamTwoScore']}',
            'date': match['matchDate'],
            'team1Logo': match['teamOne']['logoPath'],
            'team2Logo': match['teamTwo']['logoPath'],
          }).toList();
          print('🟢 Dados processados com sucesso');
          print(matches);
          isLoading = false;
        });
        
      } else {
        print('🔴 Erro na requisição: Status Code ${response.statusCode}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('🔴 Erro na conexão: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<bool> checkPremiumStatus() async { //faz a verificação se o usuário é premium
    print("🟡 checkPremiumStatus chamado");
    try {
      final response = await http.get(
        Uri.parse('https://192.168.1.16:8080/user/premium'),//coloca de volta para localhost:8080
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('🔵 Status Code /user/premium: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🔴 Erro ao verificar status premium: $e');
      return false;
    }
  }

  Future<void> fetchMatchStats(String matchId) async {
    print("🟡 fetchMatchStats chamado para partida $matchId");
    try {
      final response = await http.get(
        Uri.parse('https://192.168.1.16:8080/stats/$matchId'),//coloca de volta para localhost:8080
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔵 Status Code /stats/$matchId: ${response.statusCode}');
      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        print('🟢 Stats recebidas: $stats');
      } else {
        print('🔴 Erro ao buscar stats da partida');
      }
    } catch (e) {
      print('🔴 Erro de conexão em fetchMatchStats: $e');
    }
  }

  void _showAdOrStats(String matchId) async { //configuração de anuncio
    print("🟡 _showAdOrStats chamado para partida $matchId");
    bool isPremium = await checkPremiumStatus();
    print("🔵 Usuário premium: $isPremium");

    if (isPremium) {
      fetchMatchStats(matchId);
    } else {
      if (_interstitialAd != null) {
        print("🟡 Exibindo anúncio");
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            print("🟢 Anúncio fechado, carregando stats");
            ad.dispose();
            fetchMatchStats(matchId);
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            print("🔴 Erro ao exibir anúncio: $error");
            ad.dispose();
            fetchMatchStats(matchId);
          },
        );
        _interstitialAd!.show();
      } else {
        print("🔴 Nenhum anúncio carregado, carregando stats diretamente");
        fetchMatchStats(matchId);
      }
    }
  }

  void _navigateToStats(String matchId) { //chama a página statsScreen e passa o id da match
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(matchId: matchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("🟡 build chamado");
    return Scaffold(

      appBar: AppBar(
        title: Text(
            'Histórico de Partidas',
            style: TextStyle(
              fontSize: 20
            ),
          ),
          backgroundColor: Color.fromARGB(255, 156, 62, 30),
        ),

        body: Container(
          width: double.infinity,
          height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 231, 148, 23),
              const Color.fromARGB(255, 202, 66, 56),
              const Color.fromARGB(255, 53, 33, 33),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? const Center(child: Text('Erro ao carregar partidas', style: TextStyle(color: Colors.red)))
              : ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
                  
                  return Card(
                    color: Colors.black54,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        
                          IconButton(
                            icon: Image.asset(
                              'assets/images/StatisticsIcon.png',
                              width: 50,
                              height: 50,
                            ),

                            onPressed: () {
                              print("🟢 Partida ${matches[index]['id']} selecionada");
                              
                              final matchId = matches[index]['id'];
                              if (matchId != null) {
                                _navigateToStats(matchId);
                              } else {
                                print("⚠️ Erro: ID da partida é null");
                              }
                            },

                          ),
                          
                          //Time 1
                          Row(
                            children: [
                                    Image.asset(
                                        'assets/images/TeamShieldIcon-cutout.png',
                                        width: 60,
                                        height: 60),
                                    const SizedBox(width: 10),
                            ],
                          ),
                        
                          Column(
                            children: [
                              Text(matches[index]['date'],
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                              Text(matches[index]['score'],
                                  style: const TextStyle(
                                      color: Colors.orange, fontSize: 20)),
                            ],
                          ),

                          //Time 2
                          Row(
                            children: [
                                    Image.asset(
                                        'assets/images/TeamShieldIcon-cutout.png',
                                        width: 60,
                                        height: 60),
                                    const SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
            },
          ),
        ),
    );
  }
}