// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:label_marker/label_marker.dart';

import 'package:ebroker/data/Repositories/location_repository.dart';
import 'package:ebroker/data/model/google_place_model.dart';
import 'package:ebroker/utils/string_extenstion.dart';
import 'package:ebroker/utils/ui_utils.dart';

import '../Ui/screens/widgets/AnimatedRoutes/blur_page_route.dart';

class BezierCv extends CustomClipper<Path> {
  final List demo;

  BezierCv(this.demo);

  @override
  Path getClip(Size size) {
    Path path = Path();

    if (demo.isNotEmpty) {
      path.moveTo(demo[0]['x'], demo[0]['y']);
    }

    if (demo.length > 3) {
      path.quadraticBezierTo(
          demo[2]['x'], demo[3]['y'], demo[1]['x'], demo[1]['y']);
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}

class PlayGround extends StatefulWidget {
  const PlayGround({super.key});

  static Route route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const PlayGround(),
    );
  }

  @override
  State<PlayGround> createState() => _PlayGroundState();
}

class _PlayGroundState extends State<PlayGround> {
  List<Map> tapped = [];
  List demo = [];
  Set<Marker> marker = {};

  LatLng cameraPosition = const LatLng(
    42.42345651793833,
    23.906250000000004,
  );
  var map = [
    {
      "property_id": 1,
      "latitude": 42.42345651793833,
      "longitude": 23.906250000000004,
      "type": "sell",
      "price": "290000"
    },
    {
      "property_id": 1,
      "latitude": 10.0,
      "longitude": 11.0,
      "type": "rent",
      "price": "290000"
    },
  ];
  @override
  void initState() {
    super.initState();

    for (var i = 0; i < map.length; i++) {
      var element = map[i];
      marker
          .addLabelMarker(LabelMarker(
        label: r"$" + (element['price'] as dynamic).toString().priceFormate(),
        markerId: MarkerId("$i"),
        position: LatLng(
            element['latitude'] as dynamic, element['longitude'] as dynamic),
        backgroundColor:
            element['type'] == "sell" ? Colors.green : Colors.orange,
      ))
          .then(
        (value) {
          setState(() {});
        },
      );
    }

    // map.mapIndexed((i, Map d) {

    // }).toSet();
  }

  @override
  void didChangeDependencies() {
    // MyLang.context = context;
    super.didChangeDependencies();
  }

  // Completer completer = Completer();
  late GoogleMapController _controller;
  Timer? timer;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              markers: marker,
              onMapCreated: (controller) {
                _controller = controller;
                setState(() {});
                // completer.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: cameraPosition,
              ),
            ),
            SizedBox(
              height: 60,
              child: Material(
                child: TypeAheadField(
                  textFieldConfiguration: const TextFieldConfiguration(
                    autofocus: true,
                  ),
                  debounceDuration: const Duration(milliseconds: 500),
                  minCharsForSuggestions: 3,
                  suggestionsCallback: (pattern) async {
                    List<GooglePlaceModel> serchCities =
                        await GooglePlaceRepository().serchCities(
                      pattern,
                    );

                    return serchCities;
                  },
                  itemBuilder: (context, GooglePlaceModel suggestion) {
                    return ListTile(
                      title: Text(suggestion.city),
                    );
                  },
                  onSuggestionSelected: (GooglePlaceModel suggestion) async {
                    var data = await GooglePlaceRepository()
                        .getPlaceDetailsFromPlaceId(suggestion.placeId);
                    cameraPosition = LatLng(data['lat'], data['lng']);
                    setState(() {});
                    _controller.animateCamera(CameraUpdate.newCameraPosition(
                        CameraPosition(target: cameraPosition, zoom: 14)));
                  },
                  loadingBuilder: (context) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          child: UiUtils.progress(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Positioned(
            //     child: SizedBox(
            //   height: 60,
            //   width: context.screenWidth,
            //   child: TextField(
            //     autocorrect: true,
            //     onChanged: (value) async {
            //       timer?.cancel();

            //       timer = Timer(
            //         const Duration(milliseconds: 500),
            //         () async {
            //           List<GooglePlaceModel> serchCities =
            //               await GooglePlaceRepository().serchCities(
            //             value,
            //           );
            //           setState(() {});
            //           log(serchCities.toString());
            //         },
            //       );
            //     },
            //     decoration: const InputDecoration(
            //         fillColor: Colors.white, filled: true),
            //   ),
            // )),
          ],
        ),
      ),
    );
  }
}
