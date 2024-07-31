import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class Mapa extends StatefulWidget {

  String? idViagem;

  Mapa({ this.idViagem });

  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {

  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marcadores = {};
  CameraPosition _posicaoCamera = const CameraPosition(
      target: LatLng(-23.562436, -46.655005),
      zoom: 18
  );

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  _onMapCreated( GoogleMapController controller ){
    _controller.complete( controller );
  }

  _adicionarMarcador( LatLng latLng ) async {
    List<Placemark> listaEnderecos = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if(listaEnderecos.isNotEmpty){

      Placemark endereco = listaEnderecos[0];
      String? rua = endereco.thoroughfare;

      //41.890250, 12.492242
      Marker marcador = Marker(
          markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow(
              title: rua
          )
      );

      setState(() {
        _marcadores.add( marcador );

        //Salva no firebase
        Map<String, dynamic> viagem = {};
        viagem["titulo"] = rua;
        viagem["latitude"] = latLng.latitude;
        viagem["longitude"] = latLng.longitude;

        _db.collection("viagens")
        .add( viagem );
      });
    }
  }

  _movimentarCamera() async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        _posicaoCamera
      )
    );
  }

  _adicionarListenerLocalizacao(){
    var locationSettings = const LocationSettings(accuracy: LocationAccuracy.high);
    Geolocator.getPositionStream( locationSettings: locationSettings ).listen((Position position){

      setState(() {
        _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
          zoom: 18
        );
        _movimentarCamera();
      });
    });
  }

  _recuperaViagemParaID(String? idViagem) async {
    if( idViagem != null ){
      //exibir marcador para id viagem
      DocumentSnapshot documentSnapshot = await _db
          .collection("viagens")
          .doc( idViagem )
          .get();

      var dados = documentSnapshot.data() as Map;

      String titulo = dados["titulo"];
      LatLng latLng = LatLng(
          dados["latitude"],
          dados["longitude"]
      );

      setState(() {
        Marker marcador = Marker(
            markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
            position: latLng,
            infoWindow: InfoWindow(
                title: titulo
            )
        );

        _marcadores.add( marcador );
        _posicaoCamera = CameraPosition(
            target: latLng,
          zoom: 18
        );
        _movimentarCamera();
      });

    }else{
      _adicionarListenerLocalizacao();
    }

  }

  @override
  void initState() {
    super.initState();
    _recuperaViagemParaID( widget.idViagem );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa"),),
      body: SizedBox(
        child: GoogleMap(
            markers: _marcadores,
            mapType: MapType.normal,
            initialCameraPosition: _posicaoCamera,
            onMapCreated: _onMapCreated,
          onLongPress: _adicionarMarcador,
        ),
      ),
    );
  }
}