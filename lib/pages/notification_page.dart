import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'notificationdetail.dart';  // Import the separated detail page

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifications = [];
  List<dynamic> _vehicles = [];
  List<dynamic> _allNotificationsList = [];
  List<String> _vcNames = [];
  List<dynamic> _notificationListTab2 = [];

  List<dynamic> _filteredNotifications = [];
  String? _selectedVcName;
  String? _selectedNotificationId;

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool append = false}) async {
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

      await _fetchNotifications(token, append: append);
      await _fetchVehicles(token);
      await _fetchVcList(token);
      await _fetchAllNotifications(token);
      _matchVehiclesToNotifications();

      setState(() {
        _isLoading = false;
        _filteredNotifications = _notifications;
      });
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNotifications(String token, {bool append = false}) async {
    final url = Uri.parse('https://api.itsystem.mn/notifications/entries?page=$_currentPage');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'token': token});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final dataList = decoded is List ? decoded : (decoded['data'] ?? []);
      if (dataList.isEmpty) {
        _hasMore = false;
        return;
      }

      if (append) {
        _notifications.addAll(dataList);
      } else {
        _notifications = dataList;
      }
    } else {
      throw Exception("Failed to load notifications (${response.statusCode})");
    }
  }

  Future<void> _fetchVehicles(String token) async {
    final url = Uri.parse('https://api.itsystem.mn/monitoring/vehicles2');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'token': token});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final dataList = decoded is List ? decoded : (decoded['data'] ?? []);
      _vehicles = dataList;
    } else {
      throw Exception("Failed to load vehicles (${response.statusCode})");
    }
  }

  Future<void> _fetchVcList(String token) async {
    final url = Uri.parse('https://api.itsystem.mn/monitoring/vc');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'token': token});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final dataList = decoded is List ? decoded : (decoded['data'] ?? []);
      _vcNames = List<String>.from(dataList.map((item) => item['name'].toString()));
    } else {
      throw Exception("Failed to load VC names (${response.statusCode})");
    }
  }

  Future<void> _fetchAllNotifications(String token) async {
    final url = Uri.parse('https://api.itsystem.mn/notifications/get');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'token': token});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final dataList = decoded is List ? decoded : (decoded['data'] ?? []);
      _allNotificationsList = dataList;
      _notificationListTab2 = dataList;
    } else {
      throw Exception("Failed to load all notifications (${response.statusCode})");
    }
  }

  void _matchVehiclesToNotifications() {
    for (var notification in _notifications) {
      final imei = notification['imei']?.toString();
      final vehicle = _vehicles.firstWhere((v) => v['deviceimei']?.toString() == imei, orElse: () => null);

      notification['vehicleName'] = vehicle?['name'] ?? 'Unknown device';

      if (notification['type'] == 'speed') {
        notification['notificationMessage'] = '${notification['vehicleName']} хурд хэтрүүлсэн ${notification['speed']}km/h';
      } else if (notification['type'] == 'geofencein' || notification['type'] == 'geofenceout') {
        notification['notificationMessage'] = '${notification['vehicleName']} ${notification['notificationName']}';
      } else {
        notification['notificationMessage'] = '${notification['vehicleName']} received notification';
      }

      if (notification['timestamp'] != null) {
        DateTime timestamp = DateTime.parse(notification['timestamp']).add(Duration(hours: 8));
        notification['formattedTimestamp'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
      }
    }
  }

  void _filterNotifications() {
    setState(() {
      _filteredNotifications = _notifications.where((n) {
        final matchesVc = _selectedVcName == null || _selectedVcName!.isEmpty || (n['vehicleName']?.toLowerCase() == _selectedVcName!.toLowerCase());

        final matchesNotification = _selectedNotificationId == null || _selectedNotificationId!.isEmpty || (n['notificationName'] == _allNotificationsList.firstWhere(
              (notif) => notif['_id'] == _selectedNotificationId,
              orElse: () => {},
            )['name']);

        return matchesVc && matchesNotification;
      }).toList();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchData();
  }

  void _onScroll() {
    if (!_hasMore || _isFetchingMore) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      setState(() {
        _isFetchingMore = true;
        _currentPage++;
      });

      _fetchData(append: true).then((_) {
        setState(() {
          _isFetchingMore = false;
        });
      });
    }
  }

  Widget _iconForNotificationType(String? type) {
    switch (type) {
      case 'speed':
        return Icon(Icons.speed, color: Colors.redAccent);
      case 'geofencein':
        return Icon(Icons.login, color: Colors.green);
      case 'geofenceout':
        return Icon(Icons.logout, color: Colors.orange);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedVcName,
                  decoration: InputDecoration(
                    labelText: 'Vehicle',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text('All Vehicles')),
                    ..._vcNames.map((name) => DropdownMenuItem(value: name, child: Text(name))),
                  ],
                  onChanged: (value) => setState(() => _selectedVcName = value),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedNotificationId,
                  decoration: InputDecoration(
                    labelText: 'Notification',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notifications),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text('All Notifications')),
                    ..._allNotificationsList.map((notif) => DropdownMenuItem(
                          value: notif['_id'].toString(),
                          child: Text(notif['name'].toString()),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedNotificationId = value),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _filterNotifications,
                  child: Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _filteredNotifications.length + (_isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _filteredNotifications.length) {
                  return Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                final item = _filteredNotifications[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
                  ),
                  child: ListTile(
                    leading: _iconForNotificationType(item['type']),
                    title: Text(item['notificationMessage'] ?? 'Notification'),
                    subtitle: Text(item['formattedTimestamp'] ?? ''),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return ListView.builder(
      itemCount: _notificationListTab2.length,
      itemBuilder: (context, index) {
        final notif = _notificationListTab2[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
          ),
          child: ListTile(
            leading: Icon(Icons.notifications, color: Colors.blue),
            title: Text(notif['name'] ?? 'Unnamed'),
            subtitle: Text(notif['_id'] ?? ''),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationDetailPage(notification: notif)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Notifications'),
          backgroundColor: Color(0xFF6902FC),
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Notifications'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryTab(),
            _buildNotificationsTab(),
          ],
        ),
      ),
    );
  }
}
