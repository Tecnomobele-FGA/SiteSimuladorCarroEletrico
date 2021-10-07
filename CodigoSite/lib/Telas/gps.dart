import 'package:apps_flutter2/widgets/escolherVeiculo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:scoped_model/scoped_model.dart';
import 'HomeScreen.dart';
import 'package:time/time.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'LoginCadastro_Screen.dart';
import '../models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class Gps extends StatefulWidget {
  const Gps({Key? key}) : super(key: key);

  @override
  _GpsState createState() => _GpsState();
}

class _GpsState extends State<Gps> {
  late double M;
  double Af = 0;
  double Cd = 0;
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
  String erro = "";

  List<dadosGrafico> potenciaCartesiano = [];
  List<dadosGrafico> altitudeCartesiano = [];
  List<dadosGrafico> velocidadeCartesiano = [];

  late TooltipBehavior _tooltipPotencia;
  late TooltipBehavior _tooltipAltitude;
  late TooltipBehavior _tooltipVelocidade;
  final GlobalKey<SfCartesianChartState> _chartKey = GlobalKey();


  @override
  void initState(){
    _tooltipPotencia =  TooltipBehavior(enable: true);
    _tooltipAltitude =  TooltipBehavior(enable: true);
    _tooltipVelocidade =  TooltipBehavior(enable: true);
    super.initState();
  }

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
                escolherVeiculo(),
                TextButton(
                  child: !comecou ? Text("Começar") : Text("Parar"),
                  onPressed: () async{
                    M = model.massa;
                    Af = model.frontal;
                    Cd = model.ca;
                    if(model.ca == -999 || model.frontal == -999 || model.massa == -999 || M.isNaN ||M < 10){
                      setState(() {
                        erro = "Escolha um carro";
                      });
                    }else{
                      setState(() {
                        comecou == true ? comecou = false : comecou = true;
                        terminou = false;
                        erro = "";
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
                      }if(comecou == true){
                      }if(comecou == true){
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
                    }
                  },
                ),
                Visibility(
                  visible: erro != "",
                  child: Text(erro),
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
                        child: SfCartesianChart(
                            title: ChartTitle(text: 'Gráfico da altitude em metros versus tempo em segundos'),
                            tooltipBehavior: _tooltipAltitude,
                            // Initialize category axis
                            primaryXAxis: CategoryAxis(),
                            series: <ChartSeries>[
                              // Initialize line series
                              LineSeries<dadosGrafico, int>(
                                  enableTooltip: true,
                                  dataSource: altitudeCartesiano,
                                  xValueMapper: (dadosGrafico dados, _) => dados.x,
                                  yValueMapper: (dadosGrafico dados, _) => dados.y
                              )
                            ]
                        ),
                      ),
                    ),
                  ),
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
                        child: SfCartesianChart(
                            title: ChartTitle(text: 'Gráfico da velocidade em Km/h versus tempo em segundos'),
                            tooltipBehavior: _tooltipVelocidade,
                            // Initialize category axis
                            primaryXAxis: CategoryAxis(),
                            series: <ChartSeries>[
                              // Initialize line series
                              LineSeries<dadosGrafico, int>(
                                  yAxisName: "Velocidade em km/h",
                                  enableTooltip: true,
                                  dataSource: velocidadeCartesiano,
                                  xValueMapper: (dadosGrafico dados, _) => dados.x,
                                  yValueMapper: (dadosGrafico dados, _) => dados.y
                              )
                            ]
                        ),
                      ),
                    ),
                  ),
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
                        child: SfCartesianChart(
                            key: _chartKey,
                            title: ChartTitle(text: 'Gráfico da Potência em watts versus tempo em segundos'),
                            tooltipBehavior: _tooltipPotencia,
                            // Initialize category axis
                            primaryXAxis: CategoryAxis(),
                            series: <ChartSeries>[
                              // Initialize line series
                              LineSeries<dadosGrafico, int>(
                                  enableTooltip: true,
                                  dataSource: potenciaCartesiano,
                                  xValueMapper: (dadosGrafico dados, _) => dados.x,
                                  yValueMapper: (dadosGrafico dados, _) => dados.y
                              )
                            ]
                        ),
                      ),
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
      geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
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
    List<double> dV=[];
    dV = diff(velocidade);
    Pot=dV;
    for(int i = 0; i < velocidade.length - 1; i++){
      Pot[i]= 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i];
      potenciaCartesiano.add(dadosGrafico(i, Pot[i]));
      velocidadeCartesiano.add(dadosGrafico(i, velocidade[i]));
      altitudeCartesiano.add(dadosGrafico(i, altitude[i]));
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
    }
    return 0;
  }
}
class dadosGrafico{
  dadosGrafico(this.x, this.y);
  int x;
  double y;
}