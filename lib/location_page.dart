import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'qrcode_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationPage extends StatefulWidget {
  final bool isParent;

  const LocationPage({Key? key, required this.isParent}) : super(key: key);

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  LatLng? currentLocation; // Default to SF coordinates
  bool _isLoading = true;
  String currentLocationName = "Fetching location...";
  Marker? locationMarker;
  List<String> childrenNames = [];
  List<String> filteredChildrenNames = [];
  late GoogleMapController googleMapController;

  @override
  void initState() {
    super.initState();
    _getLocation();
    filteredChildrenNames = childrenNames;
    _fetchChildrenNames();
  }

  Future<void> _fetchChildrenNames() async {
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;

      if (user != null) {
        DatabaseReference databaseReference = FirebaseDatabase.instance
            .reference();
        DatabaseReference linkedReference = databaseReference.child('linked');

        Query query = linkedReference.orderByChild('parent_id').equalTo(
            user.uid);

        DatabaseEvent event = await query.once();

        if (event.snapshot?.value != null) {
          Map<dynamic, dynamic> linkedData = (event.snapshot!.value as Map<
              dynamic,
              dynamic>);

          List<String> childrenIds = linkedData.values
              .map<String>((childData) => childData['child_id'].toString())
              .toList();

          List<String> updatedChildrenNames = [];

          for (String childId in childrenIds) {
            DatabaseReference userReference = databaseReference.child('users')
                .child(childId);

            DatabaseEvent userEvent = await userReference.once();

            if (userEvent.snapshot?.value != null) {
              String? childName = (userEvent.snapshot!.value as Map<
                  dynamic,
                  dynamic>?)?['name']?.toString();
              if (childName != null) {
                updatedChildrenNames.add(childName);
              }
            }
          }

          setState(() {
            childrenNames = updatedChildrenNames;
            filteredChildrenNames =
                updatedChildrenNames; // Update filtered list as well
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _fetchChildrenNames: $e');
    }
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

        final String geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=YOUR_API_KEY';

        final response = await http.get(Uri.parse(geocodingUrl));
        final responseJson = json.decode(response.body);

        if (responseJson['results'] != null &&
            responseJson['results'].length > 0) {
          setState(() {
            currentLocationName =
            responseJson['results'][0]['formatted_address'];
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
          .where((user) =>
          user.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredChildrenNames = results;
    });
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery
          .of(context)
          .padding
          .top,
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

  Future<double> calculateDistance(double latitude, double longitude,
      Position userLocation) async {
    double distanceInMeters = await Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      latitude,
      longitude,
    );

    // Convert distance to kilometers
    double distanceInKm = distanceInMeters / 1000;
    return distanceInKm;
  }

  Future<String> getAddressFromCoordinates(double latitude,
      double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String fullAddress = '';

        fullAddress += placemark.subThoroughfare ?? '';
        fullAddress +=
        placemark.thoroughfare != null ? placemark.thoroughfare! + ', ' : '';
        fullAddress +=
        placemark.locality != null ? placemark.locality! + ', ' : '';
        fullAddress +=
        placemark.administrativeArea != null ? placemark.administrativeArea! +
            ', ' : '';
        fullAddress +=
        placemark.postalCode != null ? placemark.postalCode! + ', ' : '';
        fullAddress += placemark.country != null ? placemark.country! : '';

        return fullAddress;
      } else {
        return 'No address found';
      }
    } catch (e) {
      return 'Error: $e';
    }
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
                automaticallyImplyLeading: false,
                pinned: true,
                title: Text(
                    'My Children', style: TextStyle(color: Colors.black)),
                backgroundColor: Colors.white,
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        // Navigate to the QR code page here
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRCodePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    String childName = filteredChildrenNames[index];
                    return FutureBuilder<Position>(
                      future: _determinePosition(),
                      // Replace with the method to get the child's location
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text(childName),
                          );
                        } else if (snapshot.hasError) {
                          return ListTile(
                            title: Text(
                                '$childName - Error: ${snapshot.error}'),
                          );
                        } else {
                          Position childLocation = snapshot.data!;
                          return FutureBuilder<double>(
                            future: calculateDistance(
                              childLocation.latitude,
                              childLocation.longitude,
                              snapshot.data!,
                            ),
                            builder: (context, distanceSnapshot) {
                              if (distanceSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  title: Text('Loading...'),
                                );
                              } else if (distanceSnapshot.hasError) {
                                return ListTile(
                                  title: Text(
                                      'Error: ${distanceSnapshot.error}'),
                                );
                              } else {
                                double distanceInKm = distanceSnapshot.data ??
                                    0.0;
                                return ListTile(
                                  title: Text(childName),
                                  subtitle: FutureBuilder<String>(
                                    future: getAddressFromCoordinates(
                                        childLocation.latitude,
                                        childLocation.longitude),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        String address = snapshot.data ??
                                            'Unknown address';
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text('$address'),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  trailing: Text(
                                      '${distanceInKm.toStringAsFixed(2)} km'),
                                  onTap: () {
                                    _showGetDirectionsDialog(
                                        childLocation.latitude,
                                        childLocation.longitude);
                                  },
                                );
                              }
                            },
                          );
                        }
                      },
                    );
                  },
                  childCount: filteredChildrenNames.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGetDirectionsDialog(double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Get Directions'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Google Maps',
                  style: TextStyle(color: Colors.orange), // Set color
                ),
                leading: Icon(
                  Icons.map,
                  color: Colors.orange, // Set color
                ),
                onTap: () {
                  _launchMaps('google', latitude, longitude);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  'Waze',
                  style: TextStyle(color: Colors.blue), // Set color
                ),
                leading: Icon(
                  Icons.directions_car,
                  color: Colors.blue, // Set color
                ),
                onTap: () {
                  _launchMaps('waze', latitude, longitude);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _launchMaps(String app, double latitude, double longitude) async {
    String url;

    if (app == 'google') {
      url =
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    } else {
      url = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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

  @override
  Widget build(BuildContext context) {
    debugPrint('Building LocationPage');
    Set<Marker> markers = locationMarker != null ? {locationMarker!} : {};

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : GoogleMap(
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
}