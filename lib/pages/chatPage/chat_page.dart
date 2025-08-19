// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/login/landingpage.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  //controller for chat text
  TextEditingController chatText = TextEditingController();

  //controller for scrolling chats
  ScrollController controller = ScrollController();
  bool _sendingMessage = false;
  bool _showQuickReplies = true; // Show quick replies by default

  @override
  void initState() {
    getMessages();
    super.initState();
  }

  getMessages() async {
    var val = await getCurrentMessages();
    if (val == 'logout') {
      navigateLogout();
    }
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

  Widget _buildQuickReplyButton(String text) {
    var media = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: media.width * 0.01),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffE7EDEF),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(media.width * 0.02),
          ),
          padding: EdgeInsets.symmetric(
            vertical: media.width * 0.025,
            horizontal: media.width * 0.04,
          ),
        ),
        onPressed: () async {
          setState(() {
            _sendingMessage = true;
          });
          var val = await sendMessage(text);
          if (val == 'logout') {
            navigateLogout();
          }
          setState(() {
            _sendingMessage = false;
          });
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: media.width * fourteen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _quickChatCard(String msg) {
    var media = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: media.width * 0.01),
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _sendingMessage = true;
          });
          var val = await sendMessage(msg);
          if (val == 'logout') {
            navigateLogout();
          }
          setState(() {
            _sendingMessage = false;
          });
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              vertical: media.width * 0.035, horizontal: media.width * 0.04),
          decoration: BoxDecoration(
            color: const Color(0xffF7F7F7),
            borderRadius: BorderRadius.circular(media.width * 0.02),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  msg,
                  style: TextStyle(
                    fontSize: media.width * fourteen,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: media.width * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  void _openGoogleMapsWithLatLng(String message) async {
    // Try to extract lat/lng from the message
    final regex = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    final match = regex.firstMatch(message);
    String url;
    if (match != null) {
      final lat = match.group(1);
      final lng = match.group(2);
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      print('Opening Google Maps at lat: $lat, lng: $lng');
    } else {
      url = 'https://maps.google.com';
      print('No lat/lng found, opening default Google Maps');
    }
    print('Launching URL: $url');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: true,
      child: Material(
        // rtl and ltr
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Scaffold(
            body: ValueListenableBuilder(
                valueListenable: valueNotifierHome.value,
                builder: (context, value, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.animateTo(controller.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease);
                  });
                  //api call for message seen

                  return Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            media.width * 0.05,
                            MediaQuery.of(context).padding.top +
                                media.width * 0.05,
                            media.width * 0.05,
                            media.width * 0.05),
                        height: media.height * 1,
                        width: media.width * 1,
                        color: page,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: media.width * 0.9,
                                  height: media.width * 0.1,
                                  alignment: Alignment.center,
                                  child: MyText(
                                    text: driverReq['userDetail']['data']
                                        ['name'],
                                    size: media.width * twenty,
                                    fontweight: FontWeight.w600,
                                  ),
                                ),
                                Positioned(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: Container(
                                      height: media.width * 0.1,
                                      width: media.width * 0.1,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.arrow_back_ios,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Expanded(
                                child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                children: chatList
                                    .asMap()
                                    .map((i, value) {
                                      return MapEntry(
                                          i,
                                          Container(
                                            padding: EdgeInsets.only(
                                                top: media.width * 0.025),
                                            width: media.width * 0.9,
                                            alignment:
                                                (chatList[i]['from_type'] == 2)
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Column(
                                              crossAxisAlignment: (chatList[i]
                                                          ['from_type'] ==
                                                      2)
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: media.width * 0.5,
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.04),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              media.width *
                                                                  0.02),
                                                                  
                                                      color: (chatList[i][
                                                                  'from_type'] ==
                                                              2)
                                                          ? (isDarkTheme ==
                                                                  true)
                                                              ? const Color(
                                                                  0xffE7EDEF)
                                                              : Colors.black
                                                          : const Color(
                                                              0xffE7EDEF)),
                                                  child: (() {
                                                    final msg = chatList[i]['message'].toString();
                                                    // Look for any Google Maps link with query=lat,lng
                                                    final mapsLinkMatch = RegExp(r'(https://www\.google\.com/maps/search/\?api=1&query=([\d\.\-]+),([\d\.\-]+))').firstMatch(msg);
                                                    if (mapsLinkMatch != null) {
                                                      final linkUrl = mapsLinkMatch.group(1)!;
                                                      final lat = mapsLinkMatch.group(2);
                                                      final lng = mapsLinkMatch.group(3);
                                                      final staticMapUrl =
                                                          'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=16&size=200x100&markers=color:red%7C$lat,$lng&key=AIzaSyC8ajlcg9UzcHWmFjHfNenSynk6VCSlyhU';
                                                      return GestureDetector(
                                                        onTap: () async {
                                                          if (await canLaunch(linkUrl)) {
                                                            await launch(linkUrl);
                                                          }
                                                        },
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(12),
                                                          child: Image.network(
                                                            staticMapUrl,
                                                            width: 200,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    // fallback: show text for all other messages
                                                    return MyText(
                                                      text: msg,
                                                      size: media.width * fourteen,
                                                      color: (chatList[i]['from_type'] == 2)
                                                          ? (isDarkTheme == true)
                                                              ? Colors.black
                                                              : Colors.white
                                                          : Colors.black,
                                                    );
                                                  })(),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.015,
                                                ),
                                                MyText(
                                                  text: chatList[i]
                                                      ['converted_created_at'],
                                                  size: media.width * ten,
                                                )
                                              ],
                                            ),
                                          ));
                                    })
                                    .values
                                    .toList(),
                              ),
                            )),
                            // Collapsible pre-built message widget at bottom right
                            if (_showQuickReplies)
                              Container(
                                margin: EdgeInsets.only(bottom: media.width * 0.015),
                                padding: EdgeInsets.all(media.width * 0.02),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(media.width * 0.03),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.chat_bubble_outline, color: Colors.amber, size: media.width * 0.06),
                                            SizedBox(width: media.width * 0.02),
                                            Text(
                                              'Quick Chat',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: media.width * sixteen,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.keyboard_arrow_up_rounded, size: media.width * 0.08),
                                          onPressed: () {
                                            setState(() {
                                              _showQuickReplies = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: media.width * 0.02),
                                    _quickChatCard('PLEASE SHARE YOUR LOCATION'),
                                    _quickChatCard("I'LL BE THERE IN 5 MINS"),
                                    _quickChatCard('AT PICKUP LOCATION?'),
                                    _quickChatCard('AT DROP LOCATION?'),
                                  ],
                                ),
                              )
                            else
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: Colors.amber, size: media.width * 0.06),
                                    SizedBox(width: media.width * 0.01),
                                    Text(
                                      'Quick Chat',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: media.width * sixteen,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: media.width * 0.08),
                                      onPressed: () {
                                        setState(() {
                                          _showQuickReplies = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              margin: EdgeInsets.only(top: media.width * 0.025),
                              padding: EdgeInsets.fromLTRB(
                                  media.width * 0.025,
                                  media.width * 0.01,
                                  media.width * 0.025,
                                  media.width * 0.01),
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: borderLines, width: 1.2),
                                  color: page),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: MyTextField(
                                      hinttext: languages[choosenLanguage]['text_entermessage'],
                                      textController: chatText,
                                      fontsize: media.width * twelve,
                                      maxline: 1,
                                      onTap: (val) {},
                                    ),
                                  ),
                                  SizedBox(width: media.width * 0.01),
                                  IconButton(
                                    icon: Icon(Icons.location_on, color: Colors.blue, size: media.width * 0.075),
                                    onPressed: () async {
                                      LocationPermission permission = await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                        permission = await Geolocator.requestPermission();
                                        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Location permission denied')),
                                          );
                                          return;
                                        }
                                      }
                                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                      String lat = position.latitude.toString();
                                      String lng = position.longitude.toString();
                                      String url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

                                      // Reverse geocode to get address
                                      String address = '';
                                      try {
                                        print('Google Geocoding API called with: lat=$lat, lng=$lng');
                                        final apiKey = 'AIzaSyC8ajlcg9UzcHWmFjHfNenSynk6VCSlyhU';
                                        final geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';
                                        final response = await http.get(Uri.parse(geocodeUrl));
                                        if (response.statusCode == 200) {
                                          final data = json.decode(response.body);
                                          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
                                            address = data['results'][0]['formatted_address'];
                                            print('Google Geocoding result: $address');
                                          }
                                        }
                                      } catch (e) {
                                        print('Google Geocoding failed: $e');
                                        address = '$lat, $lng';
                                      }
                                      if (address.isEmpty) {
                                        address = '$lat, $lng';
                                      }

                                      String locationMessage = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                      setState(() {
                                        _sendingMessage = true;
                                      });
                                      var val = await sendMessage(locationMessage);
                                      if (val == 'logout') {
                                        navigateLogout();
                                      }
                                      chatText.clear();
                                      setState(() {
                                        _sendingMessage = false;
                                      });
                                    },
                                  ),
                                  SizedBox(width: media.width * 0.01),
                                  InkWell(
                                    onTap: () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() {
                                        _sendingMessage = true;
                                      });

                                      var val =
                                          await sendMessage(chatText.text);
                                      if (val == 'logout') {
                                        navigateLogout();
                                      }
                                      chatText.clear();
                                      setState(() {
                                        _sendingMessage = false;
                                      });
                                    },
                                    child: SizedBox(
                                      child: RotatedBox(
                                          quarterTurns:
                                              (languageDirection == 'rtl')
                                                  ? 2
                                                  : 0,
                                          child: Image.asset(
                                            'assets/images/send.png',
                                            fit: BoxFit.contain,
                                            width: media.width * 0.075,
                                            color: textColor,
                                          )),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      // loader
                      (_sendingMessage == true)
                          ? const Positioned(top: 0, child: Loading())
                          : Container()
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }
}
