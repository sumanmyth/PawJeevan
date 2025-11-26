import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<String?> showCountryCitySelector(BuildContext context, {String? initialLocation}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _CountryCitySelector(initialLocation: initialLocation),
    ),
  );
}

class _CountryCitySelector extends StatefulWidget {
  final String? initialLocation;
  const _CountryCitySelector({this.initialLocation});

  @override
  State<_CountryCitySelector> createState() => _CountryCitySelectorState();
}

class _CountryCitySelectorState extends State<_CountryCitySelector> {
  Map<String, List<String>> _data = {};
  List<String> _countries = [];
  List<String> _filteredCountries = [];
  List<String> _filteredCities = [];

  String? _selectedCountry;
  String? _selectedCity;

  final TextEditingController _countrySearch = TextEditingController();
  final TextEditingController _citySearch = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? _loadError;

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/data/countries_cities.json');
      final Map<String, dynamic> json = jsonDecode(raw);
      final Map<String, List<String>> map = {};
      json.forEach((k, v) {
        final List<String> cities = (v as List).map((e) => e.toString()).toList();
        map[k] = cities;
      });
      final countries = map.keys.toList()..sort();

      String? initialCountry;
      String? initialCity;
      if (widget.initialLocation != null && widget.initialLocation!.contains(',')) {
        final parts = widget.initialLocation!.split(',');
        if (parts.length >= 2) {
          initialCity = parts[0].trim();
          initialCountry = parts.sublist(1).join(',').trim();
        }
      }

      setState(() {
        _data = map;
        _countries = countries;
        _filteredCountries = List.from(_countries);
        _loading = false;
        _loadError = null;
        if (initialCountry != null && _data.containsKey(initialCountry)) {
          _selectedCountry = initialCountry;
          _filteredCities = List.from(_data[_selectedCountry!]!);
          if (initialCity != null && _filteredCities.contains(initialCity)) {
            _selectedCity = initialCity;
          }
        }
      });
      return;
    } catch (e) {
      _loadError = e.toString();
      setState(() {
        _loading = false;
      });
      return;
    }
  }

  void _filterCountries(String q) {
    setState(() {
      _filteredCountries = _countries.where((c) => c.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  void _filterCities(String q) {
    if (_selectedCountry == null) return;
    final all = _data[_selectedCountry!] ?? [];
    setState(() {
      _filteredCities = all.where((c) => c.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Location', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Country'),
              const SizedBox(height: 8),
              TextField(
                controller: _countrySearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search countries',
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterCountries,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_loadError != null)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Failed to load locations', style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _loading = true;
                                      _loadError = null;
                                    });
                                    _loadData();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredCountries.length,
                            itemBuilder: (context, index) {
                              final country = _filteredCountries[index];
                              final selected = country == _selectedCountry;
                              return ListTile(
                                title: Text(country),
                                trailing: selected ? const Icon(Icons.check) : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCountry = country;
                                    _selectedCity = null;
                                    _citySearch.clear();
                                    _filteredCities = List.from(_data[country] ?? []);
                                  });
                                },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 8),
              const Text('City'),
              const SizedBox(height: 8),
              TextField(
                controller: _citySearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search cities',
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterCities,
                enabled: _selectedCountry != null,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _selectedCountry == null
                    ? Center(child: Text('Select a country first', style: theme.textTheme.bodyLarge))
                    : ListView.builder(
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          final selected = city == _selectedCity;
                          return ListTile(
                            title: Text(city),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () {
                              setState(() {
                                _selectedCity = city;
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedCity != null && _selectedCountry != null
                          ? () => Navigator.of(context).pop('$_selectedCity, $_selectedCountry')
                          : null,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
