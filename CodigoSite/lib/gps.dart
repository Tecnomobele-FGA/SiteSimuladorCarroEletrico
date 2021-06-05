import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:scoped_model/scoped_model.dart';
import 'HomeScreen.dart';
import 'package:time/time.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart';
import 'LoginCadastro_Screen.dart';
import 'models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
//import 'package:latlong/latlong.dart';

class Gps extends StatefulWidget {
  const Gps({Key? key}) : super(key: key);

  @override
  _GpsState createState() => _GpsState();
}

class _GpsState extends State<Gps> {
  TextEditingController massaControlador = TextEditingController();
  late double M;
  bool comecou = false;
  bool terminou = false;
  int posicoesColhidas = 0;
  List<double> latitude   = [];
  double latitudeAgora = 0;
  List<double> longitude  = [];
  double longitudeAgora = 0;
  List<double> altitude   = [];
  double altitudeAgora = 0;
  List<double> velocidade = [];
  double velocidadeAgora = 0;
  int segundaVez = 0;
  List<double> Pot = [];
  double potMax = 0;
  double energia = 0;
  String salvar = "";
  List<LatLng> localizacao = [];
  Set<Polyline> polyline = Set<Polyline>();
  late PolylinePoints polylinePoints;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<UserModel>(
        builder: (context, child, model){
          return Scaffold(
            appBar: AppBar(
              leading: Icon(Icons.car_repair),
              title: TextButton(
                child: Text("Tecnomobele", style: TextStyle(color: Colors.white),),
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
                },
              ),
              actions: [
                Center(child: Text(model.isLoggedIn() == true && model.nome != "" ? "Olá, ${model.nome}" : "Entrar")),
                IconButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => loginCadastroScreen()));
                  },
                  icon: Icon(Icons.login_outlined),
                ),
              ],
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
                  child: new TextFormField(
                    controller: massaControlador,
                    decoration: new InputDecoration(
                        border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(10.0),
                          ),
                        ),
                        filled: true,
                        hintStyle: new TextStyle(color: Colors.grey[800]),
                        hintText: "Digite a massa do carro em quilogramas",
                        fillColor: Colors.white70),
                    validator: (text){
                      if(text!.isEmpty) return "É necessário digitar a massa do carro!";
                      else return null;
                    },
                  ),
                ),
                TextButton(
                  child: !comecou ? Text("Começar") : Text("Parar"),
                  onPressed: () async{
                    setState(() {
                      comecou == true ? comecou = false : comecou = true;
                      terminou = false;
                    });
                    if(segundaVez != 0 && comecou == true){
                      setState(() {
                        latitude   = [];
                        longitude  = [];
                        altitude   = [];
                        velocidade = [];
                        Pot        = [];
                        posicoesColhidas = 0;
                        salvar = "";
                      });
                    }if(comecou == true && massaControlador.text.isEmpty == false){
                      M = double.parse(massaControlador.text);
                      await Gps();
                      await calcula();
                      setState(() {
                        comecou = false;
                        terminou = true;
                      });
                    }else{
                      setState(() {
                        comecou = false;
                        terminou = false;
                      });
                    }
                    segundaVez += 1;
                  },
                ),
                Visibility(
                  visible: comecou,
                  child: Column(
                    children: [
                      Text("Latitude: $latitudeAgora"),
                      Text("Longitude: $longitudeAgora"),
                      Text("Altitude: $altitudeAgora"),
                      Text("Velocidade: $velocidadeAgora"),
                      Text("Posições Colhidas: $posicoesColhidas")
                    ],
                  ),
                ),
                Visibility(
                  visible: terminou,
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Text("Gráfico da Potência em watts versus tempo em segundos"),
                  )),
                ),
                Visibility(
                  visible: terminou,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all()
                        ),
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width - 30,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SfSparkLineChart(
                              trackball: SparkChartTrackball(
                                  activationMode: SparkChartActivationMode.tap),
                              data: Pot,
                            )
                        )
                    ),
                  ),
                ),
                Visibility(
                  visible: terminou,
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Text("Gráfico da velocidade em Km/h versus tempo em segundos"),
                  )),
                ),
                Visibility(
                  visible: terminou,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all()
                        ),
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width - 30,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SfSparkLineChart(
                            trackball: SparkChartTrackball(
                                activationMode: SparkChartActivationMode.tap),
                            data: velocidade,
                          ),
                        )
                    ),
                  ),
                ),
                Visibility(
                  visible: terminou,
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Text("Gráfico da altitude em metros versus tempo em segundos"),
                  )),
                ),
                Visibility(
                  visible: terminou,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all()
                        ),
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width - 30,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SfSparkLineChart(
                            trackball: SparkChartTrackball(
                                activationMode: SparkChartActivationMode.tap),
                            data: altitude,
                          ),
                        )
                    ),
                  ),
                ),
                Visibility(
                  visible: terminou,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text("Potência máxima em kW = ${(potMax / 1000).toStringAsPrecision(7)}"),
                        Text("Energia total em kWh = ${(energia / 3600000).toStringAsPrecision(7)}")
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: terminou,
                  child: ElevatedButton(
                    child: Text("Salvar resultado"),
                    onPressed: () async{
                      if(model.isLoggedIn() == true){
                        setState(() {
                          salvar = "Salvando, espere!";
                        });
                        await FirebaseFirestore.instance.collection("usuarios").doc("${model.firebaseUser!.uid}").collection("arquivos").add({
                          "data" : "${DateTime.now()}",
                          "latitude" : latitude,
                          "longitude" : longitude,
                          "altitude" : altitude,
                          "velocidade" : velocidade,
                          "arquivo" : false,
                          "nomeArquivo" : "GPS: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                        });
                        setState(() {
                          salvar = "Resultado salvo!";
                        });
                      }else{
                        setState(() {
                          salvar = "Você precisa fazer login para poder salvar!";
                        });
                      }
                    },
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(salvar),
                  ),
                ),
                Visibility(
                  visible: terminou,
                  child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          children: [
                            Text("Mapa do percurso"),
                            Text("Dica: use o botão direito para movimentar o mapa"),
                          ],
                        ),
                      )
                  ),
                ),
                Visibility(
                    visible: terminou,
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 20,
                          height: MediaQuery.of(context).size.height - 100,
                          child: GoogleMap(
                            myLocationEnabled: false,
                            compassEnabled: false,
                            tiltGesturesEnabled: false,
                            polylines: polyline,
                            initialCameraPosition: CameraPosition(
                              target: terminou ? localizacao[0] : LatLng(-3.352538, -60.163816),
                              zoom: 15.0,
                            ),
                            onMapCreated: (GoogleMapController controller){
                              setState(() {
                                polyline.add(
                                    Polyline(
                                        width: 7,
                                        polylineId: PolylineId('polyLine'),
                                        points: localizacao,
                                        color: Colors.blueAccent
                                    )
                                );
                              });
                            },
                          ),
                        )
                    )
                )
              ],
            ),
          );
        }
    );
  }

  Future<int> Gps() async{
    while(comecou == true){
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latitude.add(position.latitude);
      altitude.add(position.altitude);
      longitude.add(position.longitude);
      velocidade.add(position.speed);
      localizacao.add(LatLng(position.latitude, position.longitude));
      setState(() {
        posicoesColhidas += 1;
        longitudeAgora = position.longitude;
        latitudeAgora = position.latitude;
        altitudeAgora = position.altitude;
        velocidadeAgora = position.speed * 3.6;
      });
      await 1.seconds.delay;
    }
    return 0;
  }
  List<double> diff(List lista){
    List<double> resultado = [];
    for(int i = 0; i < lista.length - 1; i ++){
      resultado.add(lista[i + 1] - lista[i]);
    }
    return resultado;
  }
  Future<int> calcula() async{
    double Crr1=0.127;
    double Crrv2=0.000116;
    double Rho=1.1241;
    double Cd=0.5;
    List<double> dV=[];
    double Af=2.5;
    dV = diff(velocidade);
    Pot=dV;
    for(int i = 0; i < velocidade.length - 1; i++){
      Pot[i]= 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i];
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
    }
    return 0;
  }
}
