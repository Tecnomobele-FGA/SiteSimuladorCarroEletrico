import 'package:apps_flutter2/Telas/EditarVeiculos.dart';
import 'package:apps_flutter2/Telas/LerArquivo.dart';
import 'package:apps_flutter2/Telas/LoginCadastro_Screen.dart';
import 'package:apps_flutter2/Telas/gps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:scoped_model/scoped_model.dart';
import 'MeusArquivos.dart';
import '../models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool fazerLogin = false;
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<UserModel>(
        builder: (context, child, model){
          model.nome == "" ? model.nomeUsuario() : print("");
          model.nome == "" ? model.Administrador() : print("");
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
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width > 270 ? 250 : MediaQuery.of(context).size.width - 20,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                              border: Border.all(
                                color: Colors.black,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 5,),
                              Icon(Icons.location_on_outlined),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: Text("Use o gps do seu dispositivo para calcular e gerar os gráficos", textAlign: TextAlign.center,),
                              ),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.black87,
                                  ),
                                  child: Text("Usar Gps", style: TextStyle(color: Colors.white),),
                                  onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => Gps()));
                                  },
                                ),
                              ),
                              SizedBox(height: 5,),
                              Text(" "),
                              SizedBox(height: 5,),
                            ],
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width > 270 ? 250 : MediaQuery.of(context).size.width - 20,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              border: Border.all(
                                color: Colors.black,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(20))
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 5,),
                              Icon(Icons.upload_file_outlined),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: Text("Adicione um arquivo para calcular e gerar os gráficos", textAlign: TextAlign.center,),
                              ),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.black87,
                                  ),
                                  child: Text("Enviar Arquivo", style: TextStyle(color: Colors.white),),
                                  onPressed: (){
                                    model.massa = -999;
                                    model.ca = -999;
                                    model.frontal = -999;
                                    if(model.isLoggedIn() == true){
                                      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => LerArquivo()));
                                    }else{
                                      setState(() {
                                        fazerLogin = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 5,),
                              Text("*É necessário ter um cadastro*"),
                              SizedBox(height: 5,),
                            ],
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width > 270 ? 250 : MediaQuery.of(context).size.width - 20,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              border: Border.all(
                                color: Colors.black,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(20))
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 5,),
                              Icon(Icons.drive_file_move_outline),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: Text("Acesse seus arquivos para calcular e gerar os gráficos", textAlign: TextAlign.center,),
                              ),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.black87,
                                  ),
                                  child: Text("Acessar Arquivos", style: TextStyle(color: Colors.white),),
                                  onPressed: (){
                                    model.massa = -999;
                                    model.ca = -999;
                                    model.frontal = -999;
                                    if(model.isLoggedIn() == true){
                                      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MeusArquivos()));
                                    }else{
                                      setState(() {
                                        fazerLogin = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 5,),
                              Text("*É necessário ter um cadastro*"),
                              SizedBox(height: 5,),
                            ],
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width > 270 ? 250 : MediaQuery.of(context).size.width - 20,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              border: Border.all(
                                color: Colors.black,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(20))
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 5,),
                              Icon(Icons.car_rental_outlined),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: Text("Editar banco de dados dos veículos\n", textAlign: TextAlign.center,),
                              ),
                              SizedBox(height: 5,),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.black87,
                                  ),
                                  child: Text("Editar banco de dados", style: TextStyle(color: Colors.white),),
                                  onPressed: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => EditarVeiculos()));
                                  },
                                ),
                              ),
                              SizedBox(height: 5,),
                              Text(""),
                              SizedBox(height: 5,),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width > 270 ? 250 : MediaQuery.of(context).size.width - 20,
                      child: Image.asset("assets/logo.png"),
                    ),
                  ),
                  Visibility(
                    visible: fazerLogin && model.isLoggedIn() == false,
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.yellow,),
                        TextButton(
                          child: Text("É necessário fazer login!"),
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => loginCadastroScreen()));
                          },
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text("Desenvolvido por Murilo Perazzo Barbosa Souto com o a ajuda de Rudi van Els e Normando Perazzo Barbosa Souto\nPara mais informações sobre o sistema, entre em contato através do email murilopbsouto@gmail.com"),
                  ),
                ],
              ),
            ),
          );
        }
        );
  }
}