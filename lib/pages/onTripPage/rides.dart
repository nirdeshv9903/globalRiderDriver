// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:dash_bubble/dash_bubble.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/login/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:http/http.dart' as http;
import 'package:quick_nav/quick_nav.dart';
import '../../functions/functions.dart';
import '../../functions/notifications.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/notification.dart';
import '../loadingPage/loading.dart';
import '../login/landingpage.dart';
import '../navDrawer/nav_drawer.dart';
import '../vehicleInformations/docs_onprocess.dart';
import 'droplocation.dart';
import 'map_page.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

final distanceBetween = [
  {'name': '0-2 km', 'value': '0.43496'},
  {'name': '0-5 km', 'value': '1.0874'},
  {'name': '0-7 km', 'value': '1.7088'}
];
int _choosenDistance = 1;
List choosenRide = [];
bool isOverLayPermission = false;

class _RidePageState extends State<RidePage> with WidgetsBindingObserver {
  late geolocator.LocationPermission permission;
  int gettingPerm = 0;
  String state = '';
  bool _isLoading = false;
  bool _selectDistance = false;
  bool makeOnline = false;
  bool _cancel = false;
  bool isBid = false;
  String rideType = 'normal';
  double _isbottom = -1000;

  bool currentpage = true;
  TextEditingController bidText = TextEditingController();
  // final platforms = const MethodChannel('flutter.app/awake');
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // DashBubble.instance.stopBubble();
    if (Platform.isAndroid) {
      QuickNav.I.stopService();
    }

    if (userDetails['vehicle_types'] != [] && userDetails['role'] != 'owner') {
      setState(() {
        vechiletypeslist = userDetails['driverVehicleType']['data'];
      });
    }
    getadminCurrentMessages();
    currentpage = true;
    getLocs();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isBackground = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive && Platform.isAndroid) {
      // DashBubble.instance.stopBubble();
      QuickNav.I.stopService();
      isBackground = true;
    }
  }

  @override
  void dispose() {
    time?.cancel();
    bidStream?.cancel();
    super.dispose();
  }

  navigateLogout() {
    if (ownermodule == '1') {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (route) => false);
      });
    } else {
      ischeckownerordriver = 'driver';
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false);
      });
    }
  }

//getting permission and current location
  getLocs() async {
    if (signKey == '' || packageName == '') {
      PackageInfo buildKeys = await PackageInfo.fromPlatform();
      signKey = buildKeys.buildSignature;
      packageName = buildKeys.packageName;
    }
    permission = await geolocator.GeolocatorPlatform.instance.checkPermission();
    serviceEnabled =
        await geolocator.GeolocatorPlatform.instance.isLocationServiceEnabled();

    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;

      if (gettingPerm > 1) {
        locationAllowed = false;
        if (userDetails['active'] == true) {
          var val = await driverStatus();
          if (val == 'logout') {
            navigateLogout();
          }
        }
        state = '3';
      } else {
        state = '2';
      }
      setState(() {
        _isLoading = false;
      });
    } else if (permission == geolocator.LocationPermission.whileInUse ||
        permission == geolocator.LocationPermission.always) {
      if (serviceEnabled == true) {
        if (center == null) {
          var locs = await geolocator.Geolocator.getLastKnownPosition();
          if (locs != null) {
            center = LatLng(locs.latitude, locs.longitude);
            heading = locs.heading;
          } else {
            var loc = await geolocator.Geolocator.getCurrentPosition(
                desiredAccuracy: geolocator.LocationAccuracy.low);
            center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            heading = loc.heading;
          }
        }
        if (mounted) {
          setState(() {});
        }
      }

      if (makeOnline == true && userDetails['active'] == false) {
        var val = await driverStatus();
        if (val == 'logout') {
          navigateLogout();
        }
      }
      makeOnline = false;
      if (mounted) {
        setState(() {
          locationAllowed = true;
          state = '3';
          _isLoading = false;
        });
      }
    }
  }

  dynamic time;
  dynamic bidStream;
  List rideBck = [];
  timer() {
    bidStream = FirebaseDatabase.instance
        .ref()
        .child('bid-meta/${choosenRide[0]["request_id"]}')
        .onChildRemoved
        .handleError((onError) {
      bidStream?.cancel();
    }).listen((event) {
      if (driverReq.isEmpty) {
        getUserDetails();
        bidStream?.cancel();
        bidStream = null;
      }
    });
    time = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (waitingList.isNotEmpty || rideList.isNotEmpty) {
        valueNotifierTimer.incrementNotifier();
      } else {
        timer.cancel();
        bidStream?.cancel();
        bidStream = null;
        time = null;
      }
    });
  }

  getLocationPermission() async {
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      if (permission != geolocator.LocationPermission.deniedForever) {
        if (platform == TargetPlatform.android) {
          await perm.Permission.location.request();
          await perm.Permission.locationAlways.request();
        } else {
          await [perm.Permission.location].request();
        }
      }
      if (serviceEnabled == false) {
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.low);
        // await location.requestService();
      }
    } else if (serviceEnabled == false) {
      await geolocator.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocator.LocationAccuracy.low);
      // await location.requestService();
    }
    setState(() {
      _isLoading = true;
    });
    getLocs();
  }

  popFunction() {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    // [RIDE_LATER_FIX] Auto-select ride-later request for accept/reject UI
    print('[RIDE_LATER_FIX] waitingList.length=${waitingList.length}, choosenRide.length=${choosenRide.length}, rideList.length=${rideList.length}');
    
    // Populate choosenRide from waitingList or rideList
  if (waitingList.isNotEmpty && choosenRide.isEmpty) {
      print('[RIDE_LATER_FIX] Adding from waitingList: ${waitingList[0]['request_id']}');
    choosenRide.add(waitingList[0]);
    } else if (waitingList.isEmpty && rideList.isNotEmpty && choosenRide.isEmpty) {
      print('[RIDE_LATER_FIX] Adding from rideList: ${rideList[0]['request_id']}');
      choosenRide.add(rideList[0]);
  }
    
    print('[RIDE_LATER_FIX] After population - choosenRide.length: ${choosenRide.length}');
    
      // Always show the accept/reject UI for testing
    return PopScope(
      canPop: true,
      child: Material(
        child: Stack(
                          children: [
            // ... existing main UI ...
            
            // Add ValueListenableBuilder to start timer when rides are available
            ValueListenableBuilder(
              valueListenable: valueNotifierHome.value,
              builder: (context, value, child) {
                // Start timer if rides are available and timer is not running
                if ((rideList.isNotEmpty || waitingList.isNotEmpty) && time == null && driverReq.isEmpty) {
                  debugPrint('🚗 [RIDES_PAGE] Starting timer for available rides');
                  debugPrint('🚗 [RIDES_PAGE] rideList.length: ${rideList.length}');
                  debugPrint('🚗 [RIDES_PAGE] waitingList.length: ${waitingList.length}');
                  debugPrint('🚗 [RIDES_PAGE] time: $time');
                  debugPrint('🚗 [RIDES_PAGE] driverReq.isEmpty: ${driverReq.isEmpty}');
                  timer();
                } else {
                  debugPrint('🚗 [RIDES_PAGE] Timer conditions not met:');
                  debugPrint('🚗 [RIDES_PAGE] rideList.isNotEmpty: ${rideList.isNotEmpty}');
                  debugPrint('🚗 [RIDES_PAGE] waitingList.isNotEmpty: ${waitingList.isNotEmpty}');
                  debugPrint('🚗 [RIDES_PAGE] time == null: ${time == null}');
                  debugPrint('🚗 [RIDES_PAGE] driverReq.isEmpty: ${driverReq.isEmpty}');
                }
                return Container(); // Return empty container as this is just for side effects
              },
            ),
            
                              Positioned(
                                  child: ValueListenableBuilder(
                                      valueListenable: valueNotifierTimer.value,
                                      builder: (context, value, child) {
                  print('🚗 [UI] ValueListenableBuilder triggered');
                  print('🚗 [UI] waitingList.length: ${waitingList.length}');
                  print('🚗 [UI] choosenRide.length: ${choosenRide.length}');
          print('🚗 [UI] rideList.length: ${rideList.length}');
          print('🚗 [UI] driverReq.isEmpty: ${driverReq.isEmpty}');
          print('🚗 [UI] choosenRide.isNotEmpty: ${choosenRide.isNotEmpty}');
          print('🚗 [UI] Should show UI: ${choosenRide.isNotEmpty && driverReq.isEmpty}');
          
          // [RIDE_LATER_FIX] Show accept/reject UI if choosenRide is not empty and driverReq is empty
                  if (choosenRide.isNotEmpty && driverReq.isEmpty) {
            print('🚗 [UI] SHOWING ACCEPT/REJECT UI!');
                    return Container(
                      height: media.height * 1,
                      width: media.width * 1,
                      color: Colors.transparent.withOpacity(0.6),
                      child: Center(
                        child: Text(
                          'ACCEPT/REJECT UI WOULD SHOW HERE',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    );
          } else {
            print('🚗 [UI] NOT showing accept/reject UI');
                  }
                  // [RIDE_LATER_FIX] Always return a Widget
                  return Container();
                },
              ),
            ),
            // ... other overlays/popups ...
                                                              ],
                                                            ),
                                                          ),
                                                        );
  }
}
