import 'dart:math';
import 'package:flutter/material.dart';

class FactProvider extends ChangeNotifier {
  final List<String> _facts = [
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
    "Cats purr at frequencies that may help heal bones and tissues.",
    "Dogs can detect certain diseases, like some cancers, through smell.",
    "Pigs are highly social and can learn simple tricks similar to dogs.",
    "Horses sleep both standing up and lying down, depending on the need.",
    "Some turtles can absorb oxygen through their cloaca during hibernation.",
    "Parrots use vocal learning to mimic sounds and human speech.",
    "Hamsters have expandable cheek pouches to carry food back to their nests.",
    "Chinchillas have the densest fur of any land mammal to stay warm.",
    "Rats emit high-pitched chirps and may laugh when tickled.",
    "Goats have rectangular pupils that give them a wide field of vision.",
    "Certain dog breeds have more scent receptors, making them superior scent workers.",
    "Pigeons can navigate home over long distances using Earth's magnetic field.",
    "Some fish species can change their sex during their lifetime.",
    "Snakes 'taste' the air with their tongues to locate prey and mates.",
    "Ferrets were domesticated thousands of years ago for hunting small game.",
    "Horses can recognize human emotions and respond to facial expressions.",
    "Guinea pigs require dietary vitamin C because they cannot produce it themselves.",
    "Rabbits have nearly 360-degree vision with a small blind spot in front of their nose.",
    "Donkeys form strong social bonds and have excellent long-term memory.",
    "A curled tail in some dog breeds can indicate mood and help with balance.",
    "Cats spend around 30-50% of their day grooming themselves, which helps regulate their temperature and reduce stress.",
    "A dog's sense of hearing is about four times more sensitive than a human's and can detect higher frequency sounds.",
    "Not all dogs like water, but many breeds were specifically bred to swim and retrieve (e.g., Labradors, Newfoundlands).",
    "The average lifespan of domestic cats is 12-18 years, but indoor cats often live longer than outdoor cats.",
    "Senior pets still need regular dental care; periodontal disease is common and affects overall health.",
    "Microchipping your pet greatly increases the chance of reunion if they become lost.",
    "Some dogs are trained to perform 'seizure alert' or 'diabetes alert' tasks by detecting subtle scent changes.",
    "Cats have five toes on their front paws and four on their back paws, though polydactyl cats can have extra toes.",
    "Birds need mental stimulation; toys and social interaction prevent boredom-related behavior issues.",
    "Reptiles require precise temperature gradients in their enclosures to properly thermoregulate.",
    "A healthy fish tank requires biological filtration; sudden water changes can stress aquatic life.",
    "Regular exercise and play help prevent obesity in pets, which is a major health issue worldwide.",
    "Some breeds are more prone to specific health issues; responsible breeders screen for genetic conditions.",
    "Pet enrichment can include scent trails, puzzle feeders, and novel textures to explore.",
    "Training sessions should be short, consistent, and reward-based to build a strong bond with your pet.",
    "Introducing new pets slowly and under supervision reduces stress and improves long-term compatibility.",
    "Hydration is critical: cats often have a low thirst drive and may need wet food to maintain adequate water intake.",
    "Routine vet checks catch problems early; annual exams are recommended for younger pets, semi-annually for seniors."
  ];

  final Random _rng = Random();
  int _currentIndex = 0;

  FactProvider() {
    _currentIndex = _rng.nextInt(_facts.length);
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
