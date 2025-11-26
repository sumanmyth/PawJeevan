import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class FactProvider extends ChangeNotifier {
  List<String> _facts = [
    // kept as fallback in case asset load fails
    "A dog's nose print is unique, much like a human's fingerprint.",
    "Cats have over 20 muscles that control their ears.",
    "Goldfish can recognize faces and remember things for months.",
    "Dogs can learn more than 1000 different words and gestures.",
    "Rabbits can't vomit — their digestion is very sensitive.",
    "A group of kittens is called a kindle.",
    "Dogs sweat through their paws, not their skin.",
    "Some parrots can live for over 80 years in captivity.",
    "Ferrets sleep for up to 18 hours a day.",
    "Guinea pigs communicate using various wheeks and purrs.",
  ];

  final Random _rng = Random();
  int _currentIndex = 0;

  FactProvider() {
    _currentIndex = _rng.nextInt(_facts.length);
    _loadFromAsset();
  }

  Future<void> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/data/facts.json');
      final List<dynamic> json = jsonDecode(raw);
      final List<String> loaded = json.map((e) => e.toString()).toList();
      if (loaded.isNotEmpty) {
        _facts = loaded;
        _currentIndex = _rng.nextInt(_facts.length);
        notifyListeners();
      }
    } catch (_) {
      // keep fallback facts; no-op
    }
  }

  String get currentFact => _facts[_currentIndex];
  int get currentIndex => _currentIndex;

  /// Pick the next random fact (different from current if possible)
  void nextFact() {
    if (_facts.isEmpty) return;
    int next = _rng.nextInt(_facts.length);
    if (_facts.length > 1) {
      while (next == _currentIndex) {
        next = _rng.nextInt(_facts.length);
      }
    }
    _currentIndex = next;
    notifyListeners();
  }

  /// Force a new random fact (alias)
  void refresh() => nextFact();
}
