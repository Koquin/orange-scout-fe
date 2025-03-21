import 'package:flutter/material.dart';
import 'selectTeamsNStarters.dart';
import 'package:OrangeScoutFE/util/persistent_snackBar.dart';
import 'package:OrangeScoutFE/util/checks.dart';

class SelectGameScreen extends StatefulWidget {
  final Function(Widget) onNavigate; // Função para trocar de tela no MainScreen
  const SelectGameScreen({Key? key, required this.onNavigate}) : super(key: key);


  @override
  _SelectGameScreenState createState() => _SelectGameScreenState();
}

class _SelectGameScreenState extends State<SelectGameScreen> {
  Future<void> _handleNavigation(String gameMode) async {
    bool isValidated = await checkUserValidation();
    bool hasEnoughTeams = await checkUserTeams();

    if (!isValidated) {
      PersistentSnackbar.show(
        context: context,
        message: "You need to validate your email",
        actionTitle: "Validation Screen",
        navigation: "/validationScreen",
      );
    } else if (!hasEnoughTeams) {
      PersistentSnackbar.show(
        context: context,
        message: "You need at least two teams to start",
        actionTitle: "Create team",
        navigation: "/createTeam",
      );
    } else {
      widget.onNavigate(SelectTeamsNStarters(
        gameMode: gameMode,
        onBack: () => widget.onNavigate(SelectGameScreen(onNavigate: widget.onNavigate)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Color(0xFFFF4500),
            Color(0xFF84442E),
            Colors.black,
          ],
          stops: [0.0, 0.5, 0.9],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGameModeButton("5x5", "assets/images/5x5.png"),
            const SizedBox(height: 10),
            _buildGameModeButton("3x3", "assets/images/3x3.png"),
            const SizedBox(height: 10),
            _buildGameModeButton("1x1", "assets/images/1x1.png"),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeButton(String mode, String imagePath) {
    return GestureDetector(
      onTap: () => _handleNavigation(mode),
      child: Container(
        width: 300,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // Arredonda as bordas
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Faz a imagem seguir a borda do container
          child: Image.asset(
            imagePath,
            width: 300,
            height: 150,
            fit: BoxFit.cover, // Ajusta a imagem dentro do container
          ),
        ),
      ),
    );
  }

}
