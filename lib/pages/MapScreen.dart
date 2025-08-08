import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng _center = const LatLng(42.901464, 101.152526);
  Map<String, Marker> _markersMap = {};
  List<dynamic> _data = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start timer to fetch data periodically, but DO NOT fetch immediately here
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    // Delay initial fetch to avoid recreating view error
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fetchData();
      }
    });
  }

  void updateMapCenter(double latitude, double longitude) {
    if (_controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 17.0,
          ),
        ),
      );
    }
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('igpstoken');
      if (token == null) throw Exception("No token found");
      final url = Uri.parse('https://api.itsystem.mn/monitoring/vc');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to load data (${response.statusCode})");
      }
      final decoded = json.decode(response.body);
      final dataList = decoded is List ? decoded : (decoded['data'] ?? []);
      if (!mounted) return;
      setState(() {
        _data = dataList;
      });
      await _updateMarkers();
    } catch (e, stack) {
      print('Fetch data error: $e');
      print('Stack: $stack');
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(String text, double angleDegrees) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const double imageWidth = 200.0;
      const double imageHeight = 240.0;

      final ByteData imageData = await rootBundle.load('assets/car100.png');
      final ui.Codec codec = await ui.instantiateImageCodec(imageData.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      final Offset center = Offset(imageWidth / 2, imageHeight / 2);
      final double angleRadians = angleDegrees * pi / 180;

      final Paint backgroundPaint = Paint()..color = Colors.transparent;
      canvas.drawRect(Rect.fromLTWH(0, 0, imageWidth, imageHeight), backgroundPaint);

      canvas.translate(center.dx, center.dy);
      canvas.rotate(angleRadians);
      canvas.drawImage(
        image,
        Offset(-image.width / 2, -image.height / 2),
        Paint(),
      );
      canvas.rotate(-angleRadians);
      canvas.translate(-center.dx, -center.dy);

      final textStyle = TextStyle(
        color: Colors.red,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: imageWidth);
      final double textY = imageHeight - 40.0;
      textPainter.paint(canvas, Offset((imageWidth - textPainter.width) / 2, textY));

      final picture = pictureRecorder.endRecording();
      final img = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print("Marker creation error: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _updateMarkers() async {
    Map<String, Marker> newMarkersMap = Map.from(_markersMap);

    for (var item in _data) {
      if (item?["coordinates"] == null ||
          item["coordinates"]?["coordinates"] == null ||
          !(item["coordinates"]["coordinates"] is List) ||
          item["coordinates"]["coordinates"].length != 2) {
        continue;
      }

      final dynamic rawLat = item["coordinates"]["coordinates"][0];
      final dynamic rawLng = item["coordinates"]["coordinates"][1];
      if (rawLat == null || rawLng == null) continue;

      final double lat = rawLat.toDouble();
      final double lng = rawLng.toDouble();
      final String id = item["_id"]?.toString() ?? item["name"] ?? "unknown";

      double angle = 0.0;
      if (item["coordinates"].containsKey("angle")) {
        try {
          angle = (item["coordinates"]["angle"] is num)
              ? (item["coordinates"]["angle"] as num).toDouble()
              : double.parse(item["coordinates"]["angle"].toString());
        } catch (e) {
          angle = 0.0;
        }
      }

      final markerIcon = await _createCustomMarker(item["name"] ?? '', angle);

      if (newMarkersMap.containsKey(id)) {
        Marker oldMarker = newMarkersMap[id]!;
        newMarkersMap[id] = oldMarker.copyWith(
          positionParam: LatLng(lat, lng),
          iconParam: markerIcon,
          anchorParam: const Offset(0.5, 0.5),
        );
      } else {
        final newMarker = Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: item["name"] ?? '', snippet: 'Real Location'),
          icon: markerIcon,
          anchor: const Offset(0.5, 0.5),
        );
        newMarkersMap[id] = newMarker;
      }
    }

    final dataIds = _data.map((e) => e["_id"]?.toString() ?? e["name"]).toSet();
    newMarkersMap.removeWhere((key, _) => !dataIds.contains(key));

    if (!mounted) return;
    setState(() {
      _markersMap = newMarkersMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        key: const ValueKey("google_map"),
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 10.0,
        ),
        markers: Set<Marker>.of(_markersMap.values),
        mapType: MapType.hybrid,
      ),
    );
  }
}
