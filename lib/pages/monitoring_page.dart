import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'MapScreen.dart';

void main() {
  runApp(MaterialApp(
    home: MonitoringPage(),
  ));
}

class Location {
  final String id;
  final String province;
  final String country;
  final int type;
  final Map<String, dynamic> polygon;
  final String client;
  final String? description;

  Location({
    required this.id,
    required this.province,
    required this.country,
    required this.type,
    required this.polygon,
    required this.client,
    this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'],
      province: json['province'],
      country: json['country'],
      type: json['type'],
      polygon: json['polygon'],
      client: json['client'],
      description: json['description'],
    );
  }
}

class MonitoringPage extends StatefulWidget {
  @override
  _MonitoringPageState createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  List<dynamic> _devices = [];
  List<dynamic> _filteredDevices = [];
  List<Location> _locations = [];
  bool _isLoading = true;
  String? _error;
  TextEditingController _searchController = TextEditingController();
  Timer? _timer;
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterDevices);
    _startTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchDevices();
    });
  }

  Future<void> _initializeData() async {
    _locations = [
      Location.fromJson({
        "_id": "67e64f7511935c5dd965bd67",
        "province": "Сехе, БНХАУ",
        "country": "БНХАУ",
        "type": 2,
        "polygon": {
          "type": "Polygon",
          "coordinates": [
            [
              [42.598293808870416, 101.21375866628124],
              [42.58843672319732, 101.26216717458202],
              [42.57301610407418, 101.33701153493358],
              [42.56214353983437, 101.390398223166],
              [42.47914627717769, 101.37306042409374],
              [42.47813343502383, 101.18491955495311],
              [42.598293808870416, 101.21375866628124]
            ]
          ]
        },
        "client": "p5Ha74qwPMjYOA9lJ4Zbs"
      }),
      Location.fromJson({
        "_id": "67e6507a11935c5dd965bd68",
        "province": "Гурван тэс, Өмнөговь",
        "country": "Монгол",
        "description": "",
        "type": 2,
        "polygon": {
          "type": "Polygon",
          "coordinates": [
            [
              [42.57307977099606, 101.34157109959996],
              [42.59620924585486, 101.22741628392613],
              [42.95852331771544, 100.78329585521898],
              [43.268296525644836, 100.89727900951586],
              [43.32826484111808, 101.5317394587346],
              [42.88444878934976, 101.78547119713602],
              [42.57307977099606, 101.34157109959996]
            ]
          ]
        },
        "client": "p5Ha74qwPMjYOA9lJ4Zbs"
      }),
      Location.fromJson({
        "_id": "67e64ec511935c5dd965bd66",
        "province": "Өмнөговь, Монгол",
        "country": "Монгол",
        "description": "",
        "type": 2,
        "polygon": {
          "type": "Polygon",
          "coordinates": [
            [
              [42.5697300993045, 101.3614508149732],
              [42.6048651823945, 101.18841614700445],
              [42.677350352520435, 100.84247534502886],
              [42.69034921280005, 100.31656915302545],
              [42.646804586597845, 100.26307507039702],
              [42.595017347107635, 99.64110277428081],
              [43.018549853653816, 99.57730900903523],
              [43.44316948254232, 99.4860494234771],
              [44.08385760825095, 99.46133018519585],
              [45.90742250950789, 100.0628316500396],
              [46.24276174792563, 105.4241597750396],
              [42.7653854163209, 109.9505269625396],
              [42.413035795911945, 107.660220871231],
              [42.411767582398134, 107.5693921459959],
              [42.456110654364565, 107.49496701067326],
              [42.4578835358346, 107.46221763881273],
              [42.403219316001454, 107.26157349721773],
              [42.36876739997673, 107.25051534243582],
              [42.30992765125979, 106.8137369728102],
              [42.12089175173922, 106.12131099430772],
              [41.68371482364212, 104.8902676310527],
              [41.69249596769587, 104.57051488891767],
              [41.9147658180561, 104.59018909214755],
              [41.824013688653984, 103.95181924974558],
              [41.92551045249488, 103.36288788390615],
              [42.160603852035024, 102.88815015222731],
              [42.22270042477866, 102.0924832826196],
              [42.508896713046354, 101.85246790277911],
              [42.5697300993045, 101.3614508149732]
            ]
          ]
        },
        "client": "p5Ha74qwPMjYOA9lJ4Zbs"
      }),
      Location.fromJson({
        "_id": "67e64dbf11935c5dd965bd65",
        "province": "Монгол",
        "country": "Монгол",
        "type": 2,
        "polygon": {
          "type": "Polygon",
          "coordinates": [
            [
              [42.12201067511495, 102.18601045651522],
              [42.5291501124278, 101.56047639889803],
              [42.594897044459245, 101.2343197826871],
              [42.67572122485941, 100.84224519772616],
              [42.83504053658692, 100.20847139401522],
              [42.93164207397759, 93.92429170651522],
              [48.421317363307445, 83.50925264401523],
              [53.480976759414546, 88.73874483151523],
              [55.124577102621856, 100.4002924401821],
              [52.9311040598097, 119.2528315026821],
              [48.04394884369533, 129.05263619018208],
              [42.51545034307183, 122.5487299401821],
              [42.36647304011487, 108.42717842651022],
              [42.41175157798173, 107.5892777879299],
              [42.41175157798173, 107.56824926925314],
              [42.43492496740157, 107.53084854674948],
              [42.47671993525788, 107.46432976318015],
              [42.20290109739468, 106.54439644408835],
              [41.5114712479767, 104.7838373620571],
              [41.78061276804302, 103.50140340147367],
              [42.12201067511495, 102.18601045651522]
            ]
          ]
        },
        "client": "p5Ha74qwPMjYOA9lJ4Zbs"
      })
    ];
    await _fetchDevices();
  }

  void _filterDevices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDevices = List.from(_devices);
      } else {
        _filteredDevices = _devices.where((device) {
          final name = device['name']?.toString().toLowerCase() ?? '';
          return name.contains(query);
        }).toList();
      }
      _filteredDevices.sort((a, b) {
        if (a['statusLabel'] == 'Running' && b['statusLabel'] != 'Running') {
          return -1;
        } else if (a['statusLabel'] != 'Running' && b['statusLabel'] == 'Running') {
          return 1;
        } else {
          return 0;
        }
      });
    });
  }

  bool isPointInPolygon(List<double> point, List<List<double>> polygonCoords) {
    final double lat = point[0];
    final double lng = point[1];
    bool isInside = false;
    for (int i = 0, j = polygonCoords.length - 1; i < polygonCoords.length; j = i++) {
      final double lat1 = polygonCoords[i][0];
      final double lng1 = polygonCoords[i][1];
      final double lat2 = polygonCoords[j][0];
      final double lng2 = polygonCoords[j][1];
      final bool intersect = ((lat1 > lat) != (lat2 > lat)) &&
          (lng < (lng2 - lng1) * (lat - lat1) / (lat2 - lat1) + lng1);
      if (intersect) isInside = !isInside;
    }
    return isInside;
  }

  List<Location> checkCoordinatesInPolygons(List<double> coordinate) {
    final List<Location> matchingLocations = [];
    for (var location in _locations) {
      final polygonCoords = (location.polygon['coordinates'][0] as List).cast<List<dynamic>>();
      final List<List<double>> coords = polygonCoords.map((coord) {
        return [coord[0] as double, coord[1] as double];
      }).toList();
      if (isPointInPolygon(coordinate, coords)) {
        matchingLocations.add(location);
      }
    }
    return matchingLocations;
  }

  String getLocationName(List<double>? coordinates) {
    if (coordinates == null || coordinates.length != 2) {
      return 'Unknown';
    }
    final List<Location> matchingLocations = checkCoordinatesInPolygons(coordinates);
    if (matchingLocations.isEmpty) {
      return 'Outside registered zones';
    }
    return matchingLocations.first.province;
  }

  String getStatusLabel(Map<String, dynamic> device, String mainTime) {
    if (device['coordinates'] != null && device['coordinates']['timestamp'] != null) {
      final String? timestampStr = device['coordinates']['timestamp'].toString();
      if (timestampStr != null) {
        try {
          final DateTime timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(timestampStr);
          final DateTime time = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(mainTime);
          final double speed = (device['coordinates']['speed'] as num?)?.toDouble() ?? 0.0;
          final int timeDifference = time.difference(timestamp).inSeconds.abs();
          if (timeDifference < 120 && speed > 0) {
            return 'Running';
          } else if (timeDifference >= 120 && timeDifference < 86400) {
            return 'Parked';
          } else {
            return 'Stopped';
          }
        } catch (e) {
          print('Error parsing dates: $e');
          return 'Stopped';
        }
      }
    }
    return 'Stopped';
  }

  Future<void> _fetchDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('igpstoken');
      if (token == null) {
        setState(() {
          _error = "Token not found. Please sign in again.";
          _isLoading = false;
        });
        return;
      }
      final url = Uri.parse('https://api.itsystem.mn/monitoring/vc');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final String mainTime = decoded['time'];
        final dataList = decoded['data'] ?? [];
        final processedDevices = dataList.map((device) {
          if (device['coordinates'] != null &&
              device['coordinates']['coordinates'] != null) {
            List<dynamic> coords = device['coordinates']['coordinates'];
            if (coords.length == 2) {
              List<double> coordinates = [
                coords[0] is double ? coords[0] : coords[0].toDouble(),
                coords[1] is double ? coords[1] : coords[1].toDouble()
              ];
              device['location'] = getLocationName(coordinates);
            } else {
              device['location'] = 'Invalid coordinates';
            }
          } else {
            device['location'] = 'No coordinates';
          }
          device['statusLabel'] = getStatusLabel(device, mainTime);
          return device;
        }).toList();
        processedDevices.sort((a, b) {
          if (a['statusLabel'] == 'Running' && b['statusLabel'] != 'Running') {
            return -1;
          } else if (a['statusLabel'] != 'Running' && b['statusLabel'] == 'Running') {
            return 1;
          } else {
            return 0;
          }
        });
        setState(() {
          _devices = processedDevices;
          _filteredDevices = processedDevices;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load data (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Please check internet connection!";
        _isLoading = false;
      });
    }
  }

  void _showDeviceDetailsDialog(Map<String, dynamic> device) {
    final coordinates = device['coordinates']?['coordinates'];
    final timestamp = device['coordinates']?['timestamp'];
    final satellite = device['coordinates']?['satellites'];
    final formattedTime = timestamp != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(timestamp))
        : 'N/A';

    if (coordinates != null) {
      _mapScreenKey.currentState?.updateMapCenter(coordinates[0], coordinates[1]);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Device Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Location: ${device['location'] ?? 'Unknown'}'),
              Text('Time: $formattedTime'),
              Text('Satellite: ${satellite ?? 'N/A'}'),
              Text('Coordinate: ${coordinates != null ? coordinates.join(', ') : 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MapScreen(key: _mapScreenKey),
          ),
          Expanded(
            flex: 2,
            child: _buildBottomSection(),
          ),
        ],
      ),
    );
  }

Widget _buildBottomSection() {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  } else if (_error != null) {
    return Center(child: Text(_error!));
  } else {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name',
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero, // Remove padding from ListView
            itemCount: _filteredDevices.length,
            itemBuilder: (context, index) {
              final item = _filteredDevices[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Reduced padding
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/car1.png',
                      width: 24,
                      height: 24,
                    ),
                    SizedBox(width: 8), // Reduced SizedBox width
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () {
                          final coordinates = item['coordinates']?['coordinates'];
                          if (coordinates != null) {
                            _mapScreenKey.currentState?.updateMapCenter(coordinates[0], coordinates[1]);
                          }
                        },
                        child: Text(
                          item['name']?.toString() ?? 'Unknown Vehicle',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            fontFamily: 'RobotoMono',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['location'] ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontFamily: 'RobotoMono',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero, // Remove padding from IconButton
                      constraints: BoxConstraints(), // Remove constraints
                      icon: Icon(Icons.info, size: 20),
                      onPressed: () => _showDeviceDetailsDialog(item),
                    ),
                    _getStatusImage(item['statusLabel']),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}




  Widget _getStatusImage(String? statusLabel) {
    switch (statusLabel) {
      case 'Running':
        return Image.asset(
          'assets/running.png',
          width: 24,
          height: 24,
        );
      case 'Parked':
        return Image.asset(
          'assets/parked.png',
          width: 24,
          height: 24,
        );
      case 'Stopped':
        return Image.asset(
          'assets/stopped.png',
          width: 24,
          height: 24,
        );
      default:
        return Container();
    }
  }
}
