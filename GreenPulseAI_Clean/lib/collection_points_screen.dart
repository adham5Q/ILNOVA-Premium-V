import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'partner_service.dart';

class CollectionPointsScreen extends StatefulWidget {
  const CollectionPointsScreen({super.key});

  @override
  State<CollectionPointsScreen> createState() =>
      _CollectionPointsScreenState();
}

class _CollectionPointsScreenState
    extends State<CollectionPointsScreen> {
  static const green = Color(0xFF16865C);
  static const darkGreen = Color(0xFF103D2B);
  static const background = Color(0xFFF5F8F5);

  final MapController _mapController = MapController();
  final TextEditingController _searchController =
      TextEditingController();

  Position? _position;
  List<_CollectionPoint> _points = [];

  String _category = 'All';
  String _search = '';
  bool _loading = false;
  bool _locating = false;
  String? _error;
  int? _selectedId;

  static const List<String> _categories = [
    'All',
    'Plastic',
    'Paper',
    'Glass',
    'Metal',
    'Electronics',
    'Batteries',
  ];

  List<_CollectionPoint> get _filteredPoints {
    final query = _search.trim().toLowerCase();

    final results = _points.where((point) {
      final matchesCategory = _category == 'All' ||
          point.categories.contains(_category);

      final matchesSearch = query.isEmpty ||
          point.name.toLowerCase().contains(query) ||
          point.address.toLowerCase().contains(query) ||
          point.categories.any(
            (item) => item.toLowerCase().contains(query),
          );

      return matchesCategory && matchesSearch;
    }).toList();

    results.sort((a, b) {
      if (_position == null) {
        return a.name.compareTo(b.name);
      }
      return _distance(a).compareTo(_distance(b));
    });

    return results;
  }

  double _distance(_CollectionPoint point) {
    final position = _position;
    if (position == null) return double.infinity;

    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          point.location.latitude,
          point.location.longitude,
        ) /
        1000;
  }

  Future<void> _findMyLocation() async {
    if (_locating || _loading) return;

    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Turn on GPS/location services on your phone.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied. Allow it and try again.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception(
          'Enable location permission in app settings, then try again.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return;

      setState(() {
        _position = position;
      });

      debugPrint(
        'GREENPULSE GPS: lat=${position.latitude}, '
        'lon=${position.longitude}, '
        'accuracy=${position.accuracy} meters',
      );

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16,
      );

      await _loadRealPoints(position);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('TimeoutException')) {
      return 'The request took too long. Check your internet connection and try again.';
    }

    if (message.contains('SocketException') ||
        message.contains('HandshakeException') ||
        message.contains('HttpException')) {
      return 'Could not connect to the recycling map server. Details: $message';
    }

    return message.replaceFirst('Exception: ', '');
  }

  Future<void> _loadRealPoints(Position position) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    const radius = 8000;

    final overpassQuery = '''
[out:json][timeout:15];
(
  node["amenity"="recycling"](around:$radius,${position.latitude},${position.longitude});
  way["amenity"="recycling"](around:$radius,${position.latitude},${position.longitude});
  relation["amenity"="recycling"](around:$radius,${position.latitude},${position.longitude});
);
out center tags 50;
''';

    // List of public Overpass API mirrors
    const overpassServers = [
      'https://overpass-api.de/api/interpreter',
      'https://lz4.overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass.private.coffee/api/interpreter',
    ];

    var succeeded = false;
    final newFound = <_CollectionPoint>[];

    // 0. Load Approved Partner Company Branches
    try {
      final approvedCompanies = await PartnerService.instance.getAllApprovedCompanies();
      int partnerIdBase = 900000;
      for (final comp in approvedCompanies) {
        for (final branch in comp.branches) {
          newFound.add(
            _CollectionPoint(
              id: partnerIdBase++,
              name: 'شريك معتمد: ${comp.companyName} (${branch.branchName})',
              address: branch.address,
              categories: comp.acceptedWasteTypes,
              location: LatLng(branch.latitude, branch.longitude),
              sourceUrl: 'partner_company:${comp.companyId}',
              isPartner: true,
            ),
          );
        }
      }
      succeeded = true;
    } catch (e) {
      debugPrint('Error loading partner branches: $e');
    }

    final failures = <String>[];

    HttpClient? client;

    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);

      // 1. Primary Attempt: Overpass API Servers (Node, Way with Center, Relation with Center)
      for (final server in overpassServers) {
        try {
          final request = await client
              .postUrl(Uri.parse(server))
              .timeout(const Duration(seconds: 12));

          request.followRedirects = true;
          request.maxRedirects = 5;

          request.headers.set(
            HttpHeaders.userAgentHeader,
            'GreenPulseAI/1.0',
          );

          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/x-www-form-urlencoded; charset=UTF-8',
          );

          request.headers.set(
            HttpHeaders.acceptHeader,
            'application/json',
          );

          request.write(
            'data=${Uri.encodeQueryComponent(overpassQuery)}',
          );

          final response = await request
              .close()
              .timeout(const Duration(seconds: 12));

          final body = await utf8.decoder
              .bind(response)
              .join()
              .timeout(const Duration(seconds: 10));

          if (response.statusCode != 200) {
            throw HttpException(
              'HTTP ${response.statusCode} from $server',
            );
          }

          final decoded = jsonDecode(body);

          if (decoded is! Map<String, dynamic> ||
              decoded['elements'] is! List) {
            throw const FormatException(
              'Invalid response format from recycling server.',
            );
          }

          if (decoded['remark'] != null) {
            throw FormatException(
              'Overpass query remark: ${decoded['remark']}',
            );
          }

          final elements = decoded['elements'] as List;

          for (final item in elements) {
            if (item is! Map<String, dynamic>) continue;

            final rawTags = item['tags'];

            final tags = rawTags is Map
                ? Map<String, dynamic>.from(rawTags)
                : <String, dynamic>{};

            final rawCenter = item['center'];

            final center = rawCenter is Map
                ? Map<String, dynamic>.from(rawCenter)
                : <String, dynamic>{};

            // Support node (lat/lon) and way/relation (center lat/lon)
            final lat = item['lat'] ?? center['lat'];
            final lon = item['lon'] ?? center['lon'];
            final id = item['id'];

            if (lat is! num || lon is! num || id is! num) {
              continue;
            }

            final type = item['type']?.toString() ?? 'node';

            newFound.add(
              _CollectionPoint(
                id: id.toInt(),
                name: _pointName(tags),
                address: _pointAddress(tags),
                categories: _categoriesFromTags(tags),
                location: LatLng(
                  lat.toDouble(),
                  lon.toDouble(),
                ),
                sourceUrl:
                    'https://www.openstreetmap.org/$type/${id.toInt()}',
              ),
            );
          }

          succeeded = true;
          debugPrint(
            'GreenPulse Overpass: loaded ${newFound.length} points from $server',
          );
          break;
        } on TimeoutException {
          failures.add('$server: request timed out');
          debugPrint('GreenPulse Overpass timeout: $server');
        } catch (e) {
          failures.add('$server: $e');
          debugPrint('GreenPulse Overpass error: $server — $e');
        }
      }

      // 2. Secondary Fast Fallback: OpenStreetMap Nominatim API with extratags
      if (!succeeded || newFound.isEmpty) {
        try {
          final uri = Uri.parse(
            'https://nominatim.openstreetmap.org/search?amenity=recycling&format=json&extratags=1&addressdetails=1&lat=${position.latitude}&lon=${position.longitude}&limit=30',
          );

          final request = await client
              .getUrl(uri)
              .timeout(const Duration(seconds: 8));

          request.headers.set(
            HttpHeaders.userAgentHeader,
            'GreenPulseAI/1.0',
          );

          final response = await request
              .close()
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final body = await utf8.decoder
                .bind(response)
                .join()
                .timeout(const Duration(seconds: 6));

            final decoded = jsonDecode(body);

            if (decoded is List) {
              final existingIds = newFound.map((p) => p.id).toSet();

              for (final item in decoded) {
                if (item is! Map<String, dynamic>) continue;

                final lat = double.tryParse(item['lat']?.toString() ?? '');
                final lon = double.tryParse(item['lon']?.toString() ?? '');
                final id = item['osm_id'] ?? item['place_id'];

                if (lat == null || lon == null || id is! num) continue;

                final osmId = id.toInt();
                if (existingIds.contains(osmId)) continue;

                final type = item['osm_type']?.toString() ?? 'node';
                final rawTags = item['extratags'];
                final tags = rawTags is Map
                    ? Map<String, dynamic>.from(rawTags)
                    : <String, dynamic>{};

                final name = item['name']?.toString().trim();
                final displayName =
                    item['display_name']?.toString().trim() ??
                        'Recycling Center';

                newFound.add(
                  _CollectionPoint(
                    id: osmId,
                    name: (name != null && name.isNotEmpty)
                        ? name
                        : _pointName(tags),
                    address: displayName,
                    categories: _categoriesFromTags(tags),
                    location: LatLng(lat, lon),
                    sourceUrl:
                        'https://www.openstreetmap.org/$type/$osmId',
                  ),
                );
              }

              succeeded = true;
              debugPrint(
                'GreenPulse Nominatim: loaded ${newFound.length} total points',
              );
            }
          }
        } catch (e) {
          failures.add('Nominatim API: $e');
          debugPrint('GreenPulse Nominatim error: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        if (succeeded && newFound.isNotEmpty) {
          _points = newFound;
          _error = null;
        } else if (succeeded && newFound.isEmpty) {
          // Overpass / Nominatim succeeded but returned 0 mapped recycling points near this location.
          // Keep previous points if available.
          if (_points.isEmpty) {
            _error =
                'No mapped recycling points were found within 10 km of your current location. '
                'This means no OpenStreetMap recycling records exist in this area yet.';
          } else {
            _error =
                'No mapped recycling points found near this new location. Previous search results have been retained.';
          }
        } else {
          // Connection/server failed. Do NOT clear previous results! Keep _points intact.
          if (_points.isEmpty) {
            _error =
                'Could not connect to OpenStreetMap recycling servers. '
                'Please check your internet connection and try again.\n'
                '${failures.join('\n')}';
          } else {
            _error =
                'Could not retrieve new recycling data. Previous results have been kept.\n'
                '${failures.join('\n')}';
          }
        }
      });
    } catch (e) {
      if (mounted && _points.isEmpty) {
        setState(() {
          _error = 'Error loading recycling data: $e';
        });
      }
    } finally {
      client?.close(force: true);

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<String> _categoriesFromTags(
    Map<String, dynamic> tags,
  ) {
    final found = <String>[];

    void addIfPresent(String category, String key) {
      final value = tags[key]?.toString().toLowerCase();

      if (value != null &&
          value.isNotEmpty &&
          value != 'no' &&
          value != 'false') {
        found.add(category);
      }
    }

    addIfPresent('Plastic', 'recycling:plastic');
    addIfPresent('Paper', 'recycling:paper');
    addIfPresent('Glass', 'recycling:glass');
    addIfPresent('Metal', 'recycling:metal');

    addIfPresent(
      'Electronics',
      'recycling:electrical_appliances',
    );

    addIfPresent(
      'Electronics',
      'recycling:small_electrical_appliances',
    );

    addIfPresent('Batteries', 'recycling:batteries');
    addIfPresent('Batteries', 'recycling:low_voltage_batteries');

    if (found.isEmpty) {
      final general = tags['recycling']?.toString().toLowerCase();

      if (general != null && general.isNotEmpty) {
        if (general.contains('plastic')) found.add('Plastic');
        if (general.contains('paper') || general.contains('cardboard')) {
          found.add('Paper');
        }
        if (general.contains('glass')) found.add('Glass');
        if (general.contains('metal') ||
            general.contains('cans') ||
            general.contains('aluminium')) {
          found.add('Metal');
        }
        if (general.contains('battery') || general.contains('batteries')) {
          found.add('Batteries');
        }

        if (general.contains('electrical') ||
            general.contains('electronic') ||
            general.contains('appliances')) {
          found.add('Electronics');
        }
      }
    }

    return found.toSet().toList();
  }

  String _pointName(Map<String, dynamic> tags) {
    final name = tags['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final operatorName = tags['operator']?.toString().trim();

    if (operatorName != null && operatorName.isNotEmpty) {
      return operatorName;
    }

    return 'Recycling Center';
  }

  String _pointAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street']?.toString();
    final number = tags['addr:housenumber']?.toString();
    final city = tags['addr:city']?.toString();

    final parts = <String>[];

    if (street != null && street.isNotEmpty) {
      parts.add(
        number != null && number.isNotEmpty
            ? '$street $number'
            : street,
      );
    }

    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    final operatorName = tags['operator']?.toString();

    if (operatorName != null && operatorName.isNotEmpty) {
      return 'Operator: $operatorName';
    }

    return 'Address not provided in map data';
  }

  void _focusPoint(_CollectionPoint point) {
    setState(() {
      _selectedId = point.id;
    });

    _mapController.move(point.location, 16);
  }

  IconData _iconFor(_CollectionPoint point) {
    if (point.categories.contains('Electronics')) {
      return Icons.devices_rounded;
    }

    if (point.categories.contains('Batteries')) {
      return Icons.battery_charging_full_rounded;
    }

    if (point.categories.contains('Paper')) {
      return Icons.description_outlined;
    }

    if (point.categories.contains('Glass')) {
      return Icons.wine_bar_outlined;
    }

    return Icons.recycling_rounded;
  }

  void _showSourceDialog(_CollectionPoint point) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('OpenStreetMap Record'),
        content: SelectableText(point.sourceUrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Record link copied to clipboard.',
                  ),
                ),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _filteredPoints;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDF3E5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: green,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GreenPulse AI',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: darkGreen,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Real recycling map',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718276),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Find my location',
                          onPressed: _locating || _loading
                              ? null
                              : _findMyLocation,
                          icon: _locating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: green,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: green,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Recycle smarter.',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find mapped recycling points near you.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718276),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _locating || _loading
                            ? null
                            : _findMyLocation,
                        icon: const Icon(
                          Icons.location_searching_rounded,
                        ),
                        label: Text(
                          _locating
                              ? 'Finding your location...'
                              : _loading
                                  ? 'Loading map data...'
                                  : _position == null
                                      ? 'Find real points near me'
                                      : 'Refresh nearby points',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search name, address or waste type',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2EAE3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2EAE3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Waste categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 43,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _categories[index];
                          final selected = item == _category;

                          return ChoiceChip(
                            label: Text(item),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: darkGreen,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : darkGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _category = item;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Map',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: darkGreen,
                            ),
                          ),
                        ),
                        Text(
                          '${points.length} results',
                          style: const TextStyle(color: green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 310,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _position == null
                                ? const LatLng(26.8206, 30.8025)
                                : LatLng(
                                    _position!.latitude,
                                    _position!.longitude,
                                  ),
                            initialZoom: _position == null ? 5 : 13,
                            minZoom: 4,
                            maxZoom: 18,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.greenpulseai.app',
                            ),
                            MarkerLayer(
                              markers: [
                                ...points.map((point) {
                                  final selected =
                                      point.id == _selectedId;

                                  return Marker(
                                    point: point.location,
                                    width: 48,
                                    height: 55,
                                    child: GestureDetector(
                                      onTap: () => _focusPoint(point),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: selected ? 47 : 41,
                                            color: point.isPartner
                                                ? const Color(0xFFC8A96B)
                                                : (selected ? Colors.orange : green),
                                          ),
                                          if (point.isPartner)
                                            const Positioned(
                                              top: 2,
                                              child: Icon(Icons.star, size: 12, color: Colors.white),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                if (_position != null)
                                  Marker(
                                    point: LatLng(
                                      _position!.latitude,
                                      _position!.longitude,
                                    ),
                                    width: 42,
                                    height: 42,
                                    child: const Icon(
                                      Icons.my_location_rounded,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                              ],
                            ),
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  '© OpenStreetMap contributors',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Data source: OpenStreetMap via Overpass / Nominatim API. '
                      'Locations may be incomplete or outdated. '
                      'Official licensing and opening status are not verified.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Color(0xFF718276),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nearby collection points',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4DB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFF795500),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (_loading && _points.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (points.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    _loading
                        ? 'Searching for mapped recycling points...'
                        : 'No results to show. Find your location to search nearby.',
                    style: const TextStyle(
                      color: Color(0xFF718276),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final point = points[index];
                      final distance = _distance(point);

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: Color(0xFFE2EAE3),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _focusPoint(point),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDF3E5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _iconFor(point),
                                    color: green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point.name,
                                        style: const TextStyle(
                                          color: darkGreen,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        point.categories.isEmpty
                                            ? 'General recycling'
                                            : point.categories.join(', '),
                                        style: const TextStyle(
                                          color: Color(0xFF718276),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        point.address,
                                        style: const TextStyle(
                                          color: Color(0xFF718276),
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (distance.isFinite) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                          '${distance.toStringAsFixed(1)} km away',
                                          style: const TextStyle(
                                            color: green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 7),
                                      GestureDetector(
                                        onTap: () =>
                                            _showSourceDialog(point),
                                        child: const Text(
                                          'View data source',
                                          style: TextStyle(
                                            color: green,
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: points.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollectionPoint {
  final int id;
  final String name;
  final String address;
  final List<String> categories;
  final LatLng location;
  final String sourceUrl;
  final bool isPartner;

  const _CollectionPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.categories,
    required this.location,
    required this.sourceUrl,
    this.isPartner = false,
  });
}
