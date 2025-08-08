import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> notification;
  const NotificationDetailPage({Key? key, required this.notification}) : super(key: key);

  @override
  _NotificationDetailPageState createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.notification['name']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _navigateToVehiclesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VehiclesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Detail'),
        backgroundColor: const Color(0xFF6902FC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _navigateToVehiclesPage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Show Vehicles',
                  style: TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.none,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehiclesPage extends StatefulWidget {
  @override
  _VehiclesPageState createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  List<dynamic> _vehicles = [];
  List<bool> _checked = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('igpstoken');
    if (token == null) {
      setState(() {
        _error = 'No token found';
        _loading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.itsystem.mn/monitoring/vehicles2'),
        headers: {'Content-Type': 'application/json', 'token': token},
      );

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesData = json.decode(response.body);
        setState(() {
          _vehicles = vehiclesData;
          _checked = List<bool>.filled(vehiclesData.length, true);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load vehicles: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _onCheckboxChanged(int index, bool? value) {
    if (value == null) return;
    setState(() {
      _checked[index] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        backgroundColor: const Color(0xFF6902FC),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return CheckboxListTile(
                      value: _checked[index],
                      onChanged: null,
                      title: Text(vehicle['name'] ?? 'Unknown'),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
    );
  }
}
