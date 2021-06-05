import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart' as latlongg;
import 'package:scoped_model/scoped_model.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:xml/xml.dart' as xml;
import 'HomeScreen.dart';
import 'LoginCadastro_Screen.dart';
import 'models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class CalcularMeusArquivos extends StatefulWidget {
  const CalcularMeusArquivos({Key? key}) : super(key: key);

  @override
  _CalcularMeusArquivosState createState() => _CalcularMeusArquivosState();
}

class _CalcularMeusArquivosState extends State<CalcularMeusArquivos> {
  final massaControlador = TextEditingController();
  bool comecou = false;
  bool terminou = false;
  bool calculando = false;
  int posicoesColhidas = 0;
  List<double> latitude   = [];
  List<double> longitude  = [];
  List<double> altitude   = [];
  List<double> velocidade = [];
  List<LatLng> localizacao = [];
  List tempo = [];
  int segundaVez = 0;
  List<double> Pot = [];
  double potMax = 0;
  double energia = 0;
  List<dynamic> arquivao = [];
  bool desgraca = false;
  var suporte;
  int tamanhoArquivo = 0;
  String nomeArquivo = "";
  bool erroTamanho = false;
  double progresso = 0;
  String caminho = "";
  int lixo = 0;
  Set<Polyline> polyline = Set<Polyline>();
  late PolylinePoints polylinePoints;
  //Completer<GoogleMapController> _controler = Completer();

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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: model.isLoggedIn() ? Colors.lightBlueAccent : Colors.grey
                  ),
                  child: Text("Ler arquivo"),
                  onPressed: () async{
                    setState(() {
                      calculando = true;
                    });
                    if(model.isLoggedIn() == true && model.isArquivo == true){
                      var ref = FirebaseStorage.instance
                          .ref()
                          .child('uploads')
                          .child("${model.caminho}");
                      Uint8List? downloadedData  =  await ref.getData();
                      suporte = utf8.decode(downloadedData!);
                      await pegarArquivo(context, suporte);
                      await calcula();
                    }
                    if(model.isLoggedIn() == true && model.isArquivo == false){
                      for(int i = 0; i < model.velocidade.length; i++){
                        velocidade.add(double.parse((model.velocidade[i]).toString()));
                        altitude.add(double.parse((model.altitude[i]).toString()));
                      }
                      await calculaGPS();
                    }
                    setState(() {
                      terminou = true;
                      calculando = false;
                    });
                  },
                ),
                Visibility(
                  visible: calculando,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator()
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Visibility(
                    visible: nomeArquivo != "",
                    child: Text("$nomeArquivo"),
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


  Future<List> pegarArquivo(BuildContext context, var suporte) async{
    List dados = [];
    var raw = xml.XmlDocument.parse(suporte);
    var elements = raw.findAllElements('trkpt');
    return elements.map((element){
      latitude.add(double.parse(element.attributes.first.value));
      longitude.add(double.parse(element.attributes.last.value));
      altitude.add(double.parse(element.findElements("ele").first.text));
      tempo.add(DateTime.parse(element.findElements("time").first.text).millisecondsSinceEpoch / 1000);
      //latitudeAgora != double.parse(double.parse(element.attributes.first.value).toStringAsPrecision(4)) || longitudeAgora != double.parse(double.parse(element.attributes.last.value).toStringAsPrecision(4)) ? localizacao.add(Location(double.parse(double.parse(element.attributes.first.value).toStringAsPrecision(4)), double.parse(double.parse(element.attributes.last.value).toStringAsPrecision(4)))) : lixo=1;
      //localizacao.add(LatLng(double.parse(double.parse(element.attributes.first.value).toStringAsPrecision(4)), double.parse(double.parse(element.attributes.last.value).toStringAsPrecision(4))));
      localizacao.add(LatLng(double.parse(element.attributes.first.value), double.parse(element.attributes.last.value)));
      return dados.add(element.findElements("ele").first.text);
    }).toList();
  }

  List<double> diff(List lista){
    List<double> resultado = [];
    for(int i = 0; i < lista.length - 1; i ++){
      resultado.add(lista[i + 1] - lista[i]);
    }
    return resultado;
  }

  Future<int> calcula() async{
    List distancia = [];
    final latlongg.Distance distance = new latlongg.Distance();
    for(int i = 0; i < latitude.length - 1; i++){
      distancia.add(distance(
          new latlongg.LatLng(latitude[i],longitude[i]),
          new latlongg.LatLng(latitude[i+1],longitude[i+1])
      ));
    }
    for(int i = 0; i < distancia.length; i++){
      velocidade.add((3.6 * distancia[i]) / (tempo[i+1] - tempo[i]));
    }
    double M=600;
    //double g=9.8;
    double Crr1=0.127;
    double Crrv2=0.000116;
    double Rho=1.1241;
    double Cd=0.5;
    List<double> dV=[];
    double Af=2.5;
    dV = diff(velocidade);
    Pot=dV;
    for(int i = 0; i < velocidade.length - 1; i++){
      (0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i]) < 0 ? Pot[i] = 0 : Pot[i] = 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i] ;
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
    }
    return 0;
  }
  Future<int> calculaGPS() async{
    double M=600;
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
