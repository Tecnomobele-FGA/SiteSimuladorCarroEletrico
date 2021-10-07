import 'dart:convert';
import 'dart:typed_data';
import 'package:apps_flutter2/widgets/escolherVeiculo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'HomeScreen.dart';
import 'package:latlong/latlong.dart' as latlongg;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
import 'LoginCadastro_Screen.dart';
import '../models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class LerArquivo extends StatefulWidget {
  const LerArquivo({Key? key}) : super(key: key);

  @override
  _LerArquivoState createState() => _LerArquivoState();
}

class _LerArquivoState extends State<LerArquivo> {
  final massaControlador = TextEditingController();
  bool comecou = false;
  bool terminou = false;
  int posicoesColhidas = 0;
  List<double> latitude   = [];
  List<double> longitude  = [];
  List<double> altitude   = [];
  List<double> velocidade = [];
  List tempo = [];
  int segundaVez = 0;
  List<double> Pot = [];
  double potMax = 0;
  double energia = 0;
  List<dynamic> arquivao = [];
  var suporte;
  int tamanhoArquivo = 0;
  String nomeArquivo = "";
  bool erroTamanho = false;
  double progresso = 0;
  String caminho = "";
  Set<Polyline> polyline = Set<Polyline>();
  late PolylinePoints polylinePoints;
  List<LatLng> localizacao = [];
  double velocidadeMaxima = 0;
  double velocidadeTotal = 0;
  double tempoTotal = 0;
  bool terminouPrimeirosDados = false;
  bool carregando = false;
  double potTotal = 0;
  String erro = "";
  double M = 0;
  double Af = 0;
  double Cd = 0;
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
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Wrap(
                    children: [
                      SizedBox(width: 19,),
                      Text("Veículo", style: TextStyle(fontSize: 40, color: Colors.indigo[900], fontWeight: FontWeight.w900),),
                      SizedBox(width: 25,),
                      escolherVeiculo(),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        width: 250,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Roteiro", style: TextStyle(fontSize: 40, color: Colors.indigo[900], fontWeight: FontWeight.w900),),
                            SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: model.isLoggedIn() ? Colors.grey[200] : Colors.grey,
                                  side: BorderSide(
                                    width: 1,
                                    color: Colors.grey
                                  )
                                ),
                                child: Text("Carregar arquivo gpx", style: TextStyle(color: Colors.deepPurple),),
                                onPressed: () async{
                                  M = model.massa;
                                  Cd = model.ca;
                                  Af = model.frontal;
                                  if(model.ca == -999 || model.frontal == -999 || model.massa == -999 || M.isNaN ||M < 10){
                                    setState(() {
                                      erro = "Escolha um carro";
                                    });
                                  }
                                  if(model.isLoggedIn() == true && model.ca != -999){
                                    setState(() {
                                      terminou = false;
                                      erro = "";
                                    });
                                    if(segundaVez != 0){
                                      resetarVariaveis();
                                    }
                                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['xml', 'gpx'],
                                    );
                                    if (result != null) {
                                      if(result.files.first.size > 10000000 || (result.files.first.extension != "gpx" && result.files.first.extension != "xml")){
                                        setState(() {
                                          tamanhoArquivo = result.files.first.size;
                                          erroTamanho = true;
                                        });
                                        return;
                                      }
                                      Uint8List? fileBytes = result.files.first.bytes;
                                      // Upload file
                                      caminho = "${model.firebaseUser!.uid}+${DateTime.now().millisecondsSinceEpoch}";
                                      var teste = await FirebaseStorage.instance.ref('uploads/$caminho').putData(fileBytes!);
                                      await FirebaseFirestore.instance.collection("usuarios").doc("${model.firebaseUser!.uid}").collection("arquivos").add({
                                        "data" : "${DateTime.now()}",
                                        "caminho" : "$caminho",
                                        "nomeArquivo" : "${result.files.first.name}",
                                        "arquivo" : true,
                                      });
                                      setState(() {
                                        tamanhoArquivo = result.files.first.size;
                                        nomeArquivo = result.files.first.name;
                                        progresso = double.parse(teste.bytesTransferred.toString());
                                      });
                                      //lendo arquivo
                                      var ref = FirebaseStorage.instance
                                          .ref()
                                          .child('uploads')
                                          .child("$caminho");
                                      Uint8List? downloadedData  =  await ref.getData();
                                      suporte = utf8.decode(downloadedData!);
                                      await pegarArquivo(context, suporte);
                                      await primeirosDados();
                                      setState(() {
                                        terminouPrimeirosDados = true;
                                        carregando = false;
                                      });
                                    }
                                    segundaVez += 1;
                                  }
                                },
                              ),
                            ),
                            SizedBox(height: 5,),
                            Visibility(
                              visible: erro != "",
                              child: Text(erro),
                            ),
                            Visibility(
                              visible: carregando,
                              child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator()
                              ),
                            ),
                            Visibility(
                              visible: nomeArquivo != "",
                              child: Text("$nomeArquivo"),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Velocidade máxima (km/h)"),
                                    SizedBox(height: 10,),
                                    Text("Velocidade média (km/h)"),
                                    SizedBox(height: 10,),
                                    Text("Tempo percurso (minutos)"),
                                  ],
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Visibility(
                                  visible: terminouPrimeirosDados,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${velocidadeMaxima.toStringAsPrecision(4)}"),
                                      SizedBox(height: 10,),
                                      Text("${(velocidadeTotal/velocidade.length).toStringAsPrecision(4)}"),
                                      SizedBox(height: 10,),
                                      Text("${tempoTotal.toStringAsPrecision(4)}"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15,),
                            SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: model.isLoggedIn() && terminouPrimeirosDados ? Colors.blueAccent : Colors.grey,
                                ),
                                child: Text("Iniciar Simulação", style: TextStyle(color: Colors.white),),
                                onPressed: ()async{
                                  await calcula();
                                  setState(() {
                                    terminou = true;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 20,),
                            Visibility(
                              visible: terminou,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Relatório", style: TextStyle(fontSize: 30, color: Colors.indigo[900], fontWeight: FontWeight.w900),),
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Potência de pico (kW)"),
                                          SizedBox(height: 10,),
                                          Text("Potência média (kW)"),
                                          SizedBox(height: 10,),
                                          Text("Energia necessária (kWh)"),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${(potMax / 1000).toStringAsPrecision(6)}"),
                                          SizedBox(height: 10,),
                                          Text("${((potTotal/Pot.length)/1000).toStringAsPrecision(6)}"),
                                          SizedBox(height: 10,),
                                          Text("${(energia / 3600000).toStringAsPrecision(6)}"),
                                          SizedBox(height: 10,),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 300,
                        child: Column(
                          children: [
                            Visibility(
                              visible: terminouPrimeirosDados,
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
                                visible: terminouPrimeirosDados,
                                child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width - 20,
                                      height: MediaQuery.of(context).size.height / 2,
                                      child: GoogleMap(
                                        myLocationEnabled: false,
                                        compassEnabled: false,
                                        tiltGesturesEnabled: false,
                                        polylines: polyline,
                                        initialCameraPosition: CameraPosition(
                                          target: terminouPrimeirosDados ? localizacao[0] : LatLng(-3.352538, -60.163816),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: !model.isLoggedIn(),
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.yellow,),
                        Text("Você não está logado, é necessário criar um cadastro para submeter um arquivo"),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: erroTamanho,
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.yellow,),
                        Text("O tamanho máximo que o arquivo pode ter é: 10 Mb, seu arquivo teve: $tamanhoArquivo bytes, formatos aceitos: .xml e .gpx"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Future<List> pegarArquivo(BuildContext context, var suporte) async{
    List dados = [];
    //String xmlstring = await DefaultAssetBundle.of(context).loadString('insteicasa2.gpx');
    //String xmlstring = await DefaultAssetBundle.of(context).load(suporte);
    //var raw = xml.XmlDocument.parse(xmlstring);
    var raw = xml.XmlDocument.parse(suporte);
    var elements = raw.findAllElements('trkpt');
    return elements.map((element){
      latitude.add(double.parse(element.attributes.first.value));
      longitude.add(double.parse(element.attributes.last.value));
      altitude.add(double.parse(element.findElements("ele").first.text));
      tempo.add(DateTime.parse(element.findElements("time").first.text).millisecondsSinceEpoch / 1000);
      localizacao.add(LatLng(double.parse(element.attributes.first.value), double.parse(element.attributes.last.value)));
      //arquivao.add(element.attributes.first.value);
      //arquivao.add(element.findElements("lat").first.text);
      return dados.add(element.findElements("ele").first.text);
    }).toList();
  }

  Future<int> primeirosDados() async{
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
      (3.6 * distancia[i]) / (tempo[i+1] - tempo[i]) > velocidadeMaxima ? velocidadeMaxima = (3.6 * distancia[i]) / (tempo[i+1] - tempo[i]) : velocidadeMaxima = velocidadeMaxima;
      velocidadeTotal = velocidadeTotal + (3.6 * distancia[i]) / (tempo[i+1] - tempo[i]);
      velocidadeCartesiano.add(dadosGrafico(i, velocidade[i]));
      altitudeCartesiano.add(dadosGrafico(i, altitude[i]));
    }
    tempoTotal = (tempo.last - tempo.first) / 60;
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
      (0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i]) < 0 ? Pot[i] = 0 : Pot[i] = 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i] ;
      potenciaCartesiano.add(dadosGrafico(i, Pot[i]));
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
      potTotal = potTotal + Pot[i];
    }
    return 0;
  }

  void resetarVariaveis(){
    posicoesColhidas = 0;
    latitude   = [];
    longitude  = [];
    altitude   = [];
    velocidade = [];
    tempo = [];
    Pot = [];
    potMax = 0;
    energia = 0;
    arquivao = [];
    tamanhoArquivo = 0;
    nomeArquivo = "";
    progresso = 0;
    caminho = "";
    localizacao = [];
    velocidadeMaxima = 0;
    velocidadeTotal = 0;
    tempoTotal = 0;
    potTotal = 0;
    erro = "";
    energia = 0;
  }

}

class dadosGrafico{
  dadosGrafico(this.x, this.y);
  int x;
  double y;
}
