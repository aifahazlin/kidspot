import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exception}');
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationPage(isParent: true),
    );
  }
}

class LocationPage extends StatefulWidget {
  final bool isParent;

  const LocationPage({Key? key, required this.isParent}) : super(key: key);

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  // final Location location = Location();
  LatLng? currentLocation; // Default to SF coordinates

  bool _isLoading = true;

  String currentLocationName = "Fetching location...";
  Marker? locationMarker;
  final List<String> childrenNames = ['Alice', 'Bob', 'Charlie'];
  List<String> filteredChildrenNames = [];
  late GoogleMapController googleMapController;

  @override
  void initState() {
    super.initState();
    _getLocation();
    filteredChildrenNames = childrenNames;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

  void _getLocation() async {
    try {
      // bool _serviceEnabled;
      // PermissionStatus _permissionGranted;
      //
      // _serviceEnabled = await location.serviceEnabled();
      // if (!_serviceEnabled) {
      //   _serviceEnabled = await location.requestService();
      //   if (!_serviceEnabled) {
      //     return;
      //   }
      // }
      //
      // _permissionGranted = await location.hasPermission();
      // if (_permissionGranted == PermissionStatus.denied) {
      //   _permissionGranted = await location.requestPermission();
      //   if (_permissionGranted != PermissionStatus.granted) {
      //     return;
      //   }
      // }
      Position position = await _determinePosition();
      _updateLocationAndName(position);
    } catch (e) {
      debugPrint('Error in _getLocation: $e');
    }
  }

  Future<void> _updateLocationAndName(Position locationData) async {
    try {
      final latitude = locationData.latitude;
      final longitude = locationData.longitude;

      if (latitude != null && longitude != null) {
        setState(() {
          currentLocation = LatLng(latitude, longitude);
          currentLocationName = "Fetching location...";
          _isLoading = false;
        });

        _updateMarker(latitude, longitude);

        final String geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyCkWR77D06D7dsSjPGSEybqaAbGVBYDrSs';

        final response = await http.get(Uri.parse(geocodingUrl));
        final responseJson = json.decode(response.body);

        if (responseJson['results'] != null && responseJson['results'].length > 0) {
          setState(() {
            currentLocationName = responseJson['results'][0]['formatted_address'];
          });
        } else {
          setState(() {
            currentLocationName = "No address available";
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _updateLocationAndName: $e');
    }
  }

  void _updateMarker(double latitude, double longitude) {
    setState(() {
      locationMarker = Marker(
        markerId: MarkerId('currentLocation'),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(title: 'My Current Location'),
      );
    });
  }

  void _searchChild(String enteredKeyword) {
    List<String> results = [];
    if (enteredKeyword.isEmpty) {
      results = childrenNames;
    } else {
      results = childrenNames
          .where((user) => user.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredChildrenNames = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building LocationPage');
    Set<Marker> markers = locationMarker != null ? {locationMarker!} : {};

    return Scaffold(
      body: Stack(
        children: [
          _isLoading? const Center(
            child: CircularProgressIndicator(),
          ): GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation!,
              zoom: 14.0,
            ),
            markers: markers,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              googleMapController = controller;
            },
          ),
          if (widget.isParent) ...[
            _buildSearchBar(),
            _buildParentListView(),
          ],
          if (!widget.isParent) _buildChildLocationOverlay(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        color: Colors.white,
        child: Card(
          child: ListTile(
            leading: Icon(Icons.search),
            title: TextField(
              onChanged: (value) => _searchChild(value),
              decoration: InputDecoration(
                  hintText: 'Search', border: InputBorder.none),
            ),
            trailing: IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                // Clear the search field
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentListView() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.75,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                title: Text('My Children', style: TextStyle(color: Colors.black)),
                backgroundColor: Colors.white,
                leading: SizedBox(), // Empty box to hide leading space
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => ListTile(
                    title: Text(filteredChildrenNames[index]),
                  ),
                  childCount: filteredChildrenNames.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildLocationOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'My Location',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              currentLocationName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}