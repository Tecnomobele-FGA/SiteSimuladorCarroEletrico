import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'CalcularMeusArquivos.dart';
import 'HomeScreen.dart';
import 'LoginCadastro_Screen.dart';
import 'models/user_model.dart';

class MeusArquivos extends StatefulWidget {
  const MeusArquivos({Key? key}) : super(key: key);

  @override
  _MeusArquivosState createState() => _MeusArquivosState();
}

class _MeusArquivosState extends State<MeusArquivos> {

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<UserModel>(
      //FirebaseFirestore.instance.collection("usuarios").doc("${model.firebaseUser!.uid}").get(),
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
            body: StreamBuilder(
              /*stream: FirebaseFirestore.instance.collection("usuarios").doc(
                  "${model.firebaseUser!.uid}")
                  .collection("arquivos")
                  .snapshots(),*/
                stream: FirebaseFirestore.instance.collection("usuarios").doc("${model.firebaseUser!.uid}").collection("arquivos").snapshots(),
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
                      return Container(
                        padding: EdgeInsets.all(10.0),
                        child: Card(
                          child: Column(
                            children: [
                              SizedBox(width: 8,),
                              AutoSizeText("${temp["nomeArquivo"]}", maxLines: 2,),
                              SizedBox(width: 8,),
                              AutoSizeText("${temp["data"]}"),
                              SizedBox(width: 8,),
                              IconButton(
                                icon: Icon(Icons.arrow_forward_rounded),
                                onPressed: () async{
                                  model.isArquivo = await temp["arquivo"];
                                  model.isArquivo == true ? model.caminho = await temp["caminho"] : model.isArquivo = model.isArquivo;
                                  model.isArquivo == true ? model.isArquivo = model.isArquivo : model.velocidade = await temp["velocidade"];
                                  model.isArquivo == true ? model.isArquivo = model.isArquivo : model.altitude = await temp["altitude"];
                                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CalcularMeusArquivos()));
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
          );
        }
    );
  }
}