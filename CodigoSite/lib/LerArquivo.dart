import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'HomeScreen.dart';
import 'package:latlong/latlong.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
import 'package:time/time.dart';
import 'LoginCadastro_Screen.dart';
import 'models/user_model.dart';

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
  bool desgraca = false;
  var suporte;
  int tamanhoArquivo = 0;
  String nomeArquivo = "";
  bool erroTamanho = false;
  double progresso = 0;
  String caminho = "";
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: model.isLoggedIn() ? Colors.lightBlueAccent : Colors.grey
                  ),
                  child: Text("Adicionar Arquivo"),
                  onPressed: () async{
                    if(model.isLoggedIn() == true){
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
                      }
                    }
                  },
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Visibility(
                          visible: progresso != 0,
                          child: LinearProgressIndicator(
                            value: progresso,
                          ),
                        ),
                        Visibility(
                          visible: tamanhoArquivo == progresso && tamanhoArquivo != 0,
                          child: Text("Arquivo enviado com sucesso!"),
                        ),
                      ],
                    )
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: model.isLoggedIn() ? Colors.lightBlueAccent : Colors.grey
                  ),
                  child: Text("Ler arquivo"),
                  onPressed: () async{
                    if(model.isLoggedIn() == true){
                      var ref = FirebaseStorage.instance
                          .ref()
                          .child('uploads')
                          .child("$caminho");
                      Uint8List? downloadedData  =  await ref.getData();
                      suporte = utf8.decode(downloadedData!);
                      await pegarArquivo(context, suporte);
                      await calcula();
                      setState(() {
                        terminou = true;
                      });
                    }
                  },
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
              ],
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
      //arquivao.add(element.attributes.first.value);
      //arquivao.add(element.findElements("lat").first.text);
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
    final Distance distance = new Distance();
    for(int i = 0; i < latitude.length - 1; i++){
      distancia.add(distance(
          new LatLng(latitude[i],longitude[i]),
          new LatLng(latitude[i+1],longitude[i+1])
      ));
    }
    for(int i = 0; i < distancia.length; i++){
      velocidade.add((3.6 * distancia[i]) / (tempo[i+1] - tempo[i]));
    }
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
      (0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i]) < 0 ? Pot[i] = 0 : Pot[i] = 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i] ;
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
    }
    return 0;
  }
}
