import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poc/core/presentation/widgets/primary_button.dart';
import 'package:poc/core/presentation/widgets/secondary_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Spasticity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 200,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Image.asset(
                          'assets/logo_spasticity.png',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Démarrer une analyse',
                    height: 52,
                    onPressed: () {
                      context.push('/analyse');
                    },
                  ),

                  const SizedBox(height: 12),

                  SecondaryButton(
                    label: 'Trouver un patient',
                    height: 52,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à venir'),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFFEDEDED),
                    borderColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
