import 'package:apps_flutter2/models/user_model.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Alignment, Row;
import 'HomeScreen.dart';
import 'LoginCadastro_Screen.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class EditarVeiculos extends StatefulWidget {
  const EditarVeiculos({Key? key}) : super(key: key);

  @override
  _EditarVeiculosState createState() => _EditarVeiculosState();
}

class _EditarVeiculosState extends State<EditarVeiculos> {

  bool editarMassa = false;
  bool editarCa = false;
  bool editarFrontal = false;
  double ca = 999;
  double massa = 999;
  double frontal = 999;
  final formKey = GlobalKey<FormState>();
  late double massaAdicionar;
  late double caAdicionar;
  late double frontalAdicionar;
  late String nomeAdicionar;
  TextEditingController massaControlador = TextEditingController();
  TextEditingController frontalControlador = TextEditingController();
  TextEditingController caControlador = TextEditingController();
  late String itemid;
  List nomesExcel = [];
  List caExcel = [];
  List frontalExcel = [];
  List massaExcel = [];
  int tamanhoExcel = 0;
  bool avisoAdmiro = false;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<UserModel>(
        builder: (context, child, model) {
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
            body: SingleChildScrollView(
              child:
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blueAccent,
                        ),
                        child: Text("Baixar Excel com banco de dados", style: TextStyle(color: Colors.white),),
                        onPressed: (){
                          if(tamanhoExcel > 0){
                            criarExcel();
                          }
                        },
                      ),
                    ),
                    StreamBuilder(
                        stream: FirebaseFirestore.instance.collection("carros").snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Algo está errado!'));
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Row(
                              children: [
                                Text("Carregando!"),
                                SizedBox(width: 5,),
                                Container(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator()
                                ),
                              ],
                            );
                          }
                          if(!snapshot.hasData){
                            return Center(child: Text("Infelizmente você ainda não possui nada salvo"));
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              var temp = snapshot.data!.docs[index];
                              nomesExcel.add(temp["nome"]);
                              caExcel.add(temp["ca"]);
                              frontalExcel.add(temp["frontal"]);
                              massaExcel.add(temp["massa"]);
                              tamanhoExcel = snapshot.data!.docs.length;
                              return Container(
                                padding: EdgeInsets.all(10.0),
                                child: Card(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(width: 8,),
                                          AutoSizeText("${temp["nome"]}", maxLines: 2,),
                                        ],
                                      ),
                                      SizedBox(width: 8,),
                                      Row(
                                        children: [
                                          AutoSizeText("Massa: ${temp["massa"]} Kg"),
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: (){
                                              setState(() {
                                                itemid = snapshot.data!.docs[index].id;
                                                model.administrador ? editarMassa = true  : editarMassa = false;
                                                model.administrador ? avisoAdmiro = false : avisoAdmiro = true;
                                              });
                                            },
                                          ),
                                          Visibility(
                                            visible: avisoAdmiro,
                                            child: Text("Você precisa ser admin para alterar valores"),
                                          ),
                                          Visibility(
                                            visible: editarMassa && itemid == snapshot.data!.docs[index].id,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width / 4,
                                                  child: TextFormField(
                                                    controller: massaControlador,
                                                    decoration: new InputDecoration(
                                                        border: new OutlineInputBorder(
                                                          borderRadius: const BorderRadius.all(
                                                            const Radius.circular(10.0),
                                                          ),
                                                        ),
                                                        filled: true,
                                                        hintStyle: new TextStyle(color: Colors.grey[800]),
                                                        hintText: "Digite a nova massa",
                                                        fillColor: Colors.white70
                                                    ),
                                                    validator: (valor){
                                                      if(valor!.length < 3 || valor.length > 10){
                                                        return "Informe a massa correta";
                                                      }else{
                                                        return null;
                                                      }
                                                    },
                                                    onSaved: (valor){
                                                      setState(() {
                                                        //print(valor);
                                                        massaAdicionar = double.parse(valor.toString());
                                                      });
                                                    },
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  child: Text("Validar"),
                                                  onPressed: () async{
                                                    massaAdicionar = double.parse(massaControlador.text);
                                                    //print(snapshot.data!.docs[index].id);
                                                    await FirebaseFirestore.instance.collection("carros").doc(snapshot.data!.docs[index].id).update(
                                                        {"massa" : massaAdicionar});
                                                    setState(() {
                                                      editarMassa = false;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 8,),
                                      Row(
                                        children: [
                                          AutoSizeText("Área Frontal: ${temp["frontal"]} m2"),
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: (){
                                              setState(() {
                                                itemid = snapshot.data!.docs[index].id;
                                                model.administrador ? editarFrontal = true : editarFrontal = false;
                                                model.administrador ? avisoAdmiro = false  : avisoAdmiro   = true;
                                              });
                                            },
                                          ),
                                          Visibility(
                                            visible: avisoAdmiro,
                                            child: Text("Você precisa ser admin para alterar valores"),
                                          ),
                                          Visibility(
                                            visible: editarFrontal && itemid == snapshot.data!.docs[index].id,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width / 4,
                                                  child: TextFormField(
                                                    controller: frontalControlador,
                                                    decoration: new InputDecoration(
                                                        border: new OutlineInputBorder(
                                                          borderRadius: const BorderRadius.all(
                                                            const Radius.circular(10.0),
                                                          ),
                                                        ),
                                                        filled: true,
                                                        hintStyle: new TextStyle(color: Colors.grey[800]),
                                                        hintText: "Digite a nova área frontal",
                                                        fillColor: Colors.white70
                                                    ),
                                                    validator: (valor){
                                                      if(valor!.length < 3 || valor.length > 10){
                                                        return "Informe a área frontal correta";
                                                      }else{
                                                        return null;
                                                      }
                                                    },
                                                    onSaved: (valor){
                                                      setState(() {
                                                        //print(valor);
                                                        frontalAdicionar = double.parse(valor.toString());
                                                      });
                                                    },
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  child: Text("Validar"),
                                                  onPressed: () async{
                                                    frontalAdicionar = double.parse(frontalControlador.text);
                                                    //print(snapshot.data!.docs[index].id);
                                                    await FirebaseFirestore.instance.collection("carros").doc(snapshot.data!.docs[index].id).update(
                                                        {"frontal" : frontalAdicionar});
                                                    setState(() {
                                                      editarFrontal = false;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 8,),
                                      Row(
                                        children: [
                                          AutoSizeText("Coeficiente aerodinâmica: ${temp["ca"]}"),
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: (){
                                              setState(() {
                                                itemid = snapshot.data!.docs[index].id;
                                                model.administrador ? editarCa    = true  : editarFrontal = false;
                                                model.administrador ? avisoAdmiro = false : avisoAdmiro =   true;
                                              });
                                            },
                                          ),
                                          Visibility(
                                            visible: avisoAdmiro,
                                            child: Text("Você precisa ser admin para alterar valores"),
                                          ),
                                          Visibility(
                                            visible: editarCa && itemid == snapshot.data!.docs[index].id,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width / 4,
                                                  child: TextFormField(
                                                    controller: caControlador,
                                                    decoration: new InputDecoration(
                                                        border: new OutlineInputBorder(
                                                          borderRadius: const BorderRadius.all(
                                                            const Radius.circular(10.0),
                                                          ),
                                                        ),
                                                        filled: true,
                                                        hintStyle: new TextStyle(color: Colors.grey[800]),
                                                        hintText: "Digite o novo coefiente aerodinâmico",
                                                        fillColor: Colors.white70
                                                    ),
                                                    validator: (valor){
                                                      if(valor!.length < 3 || valor.length > 10){
                                                        return "Informe o coeficiente aerodinâmico correto";
                                                      }else{
                                                        return null;
                                                      }
                                                    },
                                                    onSaved: (valor){
                                                      setState(() {
                                                        //print(valor);
                                                        caAdicionar = double.parse(valor.toString());
                                                      });
                                                    },
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  child: Text("Validar"),
                                                  onPressed: () async{
                                                    caAdicionar = double.parse(caControlador.text);
                                                    //print(snapshot.data!.docs[index].id);
                                                    await FirebaseFirestore.instance.collection("carros").doc(snapshot.data!.docs[index].id).update(
                                                        {"ca" : caAdicionar});
                                                    setState(() {
                                                      editarCa = false;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 8,),

                                      /*IconButton(
                                        icon: Icon(Icons.arrow_forward_rounded),
                                        onPressed: () async{
                                          model.isArquivo = await temp["arquivo"];
                                          model.isArquivo == true ? model.caminho = await temp["caminho"] : model.isArquivo = model.isArquivo;
                                          model.isArquivo == true ? model.isArquivo = model.isArquivo : model.velocidade = await temp["velocidade"];
                                          model.isArquivo == true ? model.isArquivo = model.isArquivo : model.altitude = await temp["altitude"];
                                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CalcularMeusArquivos()));
                                        },
                                      )*/
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                  ],
                ),

            ),
          );
        }
    );
  }

  Future<void> criarExcel() async{
    final Workbook workbook = new Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.getRangeByName('A1').setText('Veículo');
    sheet.getRangeByName('B1').setText('Massa');
    sheet.getRangeByName('C1').setText('Coeficiente Aerodinâmico');
    sheet.getRangeByName('D1').setText('Área Frontal');
    for(int i = 0; i < tamanhoExcel; i++){
      sheet.getRangeByName('A${i+2}').setText(nomesExcel[i]);
      sheet.getRangeByName('B${i+2}').setNumber(massaExcel[i]);
      sheet.getRangeByName('C${i+2}').setNumber(caExcel[i]);
      sheet.getRangeByName('D${i+2}').setNumber(frontalExcel[i]);
    }
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    if(kIsWeb){
      AnchorElement(href: 'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', 'Tecnomobele_Banco_de_Dados.xlsx')
        ..click();
    }
  }
}
