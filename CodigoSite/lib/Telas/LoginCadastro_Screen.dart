import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import '../models/user_model.dart';
import 'package:scoped_model/scoped_model.dart';

class loginCadastroScreen extends StatefulWidget {
  @override
  _loginCadastroScreenState createState() => _loginCadastroScreenState();
}

class _loginCadastroScreenState extends State<loginCadastroScreen> {

  TextEditingController emailLoginControlador = TextEditingController();
  TextEditingController senhaLoginControlador = TextEditingController();
  TextEditingController nomeCadastroControlador = TextEditingController();
  TextEditingController emailCadastroControlador = TextEditingController();
  TextEditingController senhaCadastroControlador = TextEditingController();
  GlobalKey<FormState> _formKeyLogin = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyCadastro = GlobalKey<FormState>();

  bool algoErrado = false;

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
            ),
            backgroundColor: Colors.grey[200],
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width >= 550 ? 500 : MediaQuery.of(context).size.width - 30,
                          height: 500,
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Form(
                            key: _formKeyLogin,
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: algoErrado,
                                  child: Row(
                                    children: [
                                      Text("Algo está errado"),
                                      Icon(Icons.warning_rounded, color: Colors.yellow,),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    top: 20,
                                    left: 10,
                                    child: Text("Já tenho cadastro",
                                      style: TextStyle(fontSize: 20),)
                                ),
                                Positioned(
                                  top: 80,
                                  left: 20,
                                  child: Text("E-mail"),
                                ),
                                Positioned(
                                  top: 100,
                                  left: 20,
                                  child: SizedBox(
                                    //height: 35,
                                    width: 300,
                                    child: TextFormField(
                                      controller: emailLoginControlador,
                                      obscureText: false,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: "",
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                                        ),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide()),
                                      ),
                                      validator: (text){
                                        if(!text!.contains("@")) return "Certeza que esse é um e-mail válido?";
                                        else return null;
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 180,
                                  left: 20,
                                  child: Text("Senha"),
                                ),
                                Positioned(
                                  top: 200,
                                  left: 20,
                                  child: SizedBox(
                                    //height: 35,
                                    width: 300,
                                    child: TextFormField(
                                      controller: senhaLoginControlador,
                                      keyboardType: TextInputType.text,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: "",
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                                        ),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide()),
                                      ),
                                      validator: (text){
                                        if(text!.isEmpty) return "A senha não pode ficar em branco!";
                                        if(text.length < 6) return "A senha precisa ter mais do que 6 dígitos!";
                                        else return null;
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 280,
                                  left: 20,
                                  child: SizedBox(
                                    width: 150,
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.black87,
                                      ),
                                      child: Text("Entrar", style: TextStyle(color: Colors.white),),
                                      onPressed: (){
                                        if(_formKeyLogin.currentState!.validate()){
                                          if(model.isLoggedIn() == true){
                                            model.signOut();
                                          }
                                          model.signIn(
                                              email: emailLoginControlador.text,
                                              pass: senhaLoginControlador.text,
                                              onSuccess: _onSuccess,
                                              onFail: _onFail);
                                        }
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width >= 550 ? 500 : MediaQuery.of(context).size.width - 30,
                          height: 500,
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Form(
                            key: _formKeyCadastro,
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: algoErrado,
                                  child: Row(
                                    children: [
                                      Text("Algo está errado, a operação não deu certo!"),
                                      Icon(Icons.warning_rounded, color: Colors.yellow,),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    top: 20,
                                    left: 10,
                                    child: Text("Quero me cadastrar",
                                      style: TextStyle(fontSize: 20),)
                                ),
                                Positioned(
                                  top: 80,
                                  left: 20,
                                  child: Text("Nome"),
                                ),
                                Positioned(
                                  top: 100,
                                  left: 20,
                                  child: SizedBox(
                                    //height: 35,
                                    width: 300,
                                    child: TextFormField(
                                      controller: nomeCadastroControlador,
                                      obscureText: false,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                        labelText: "",
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                                        ),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide()),
                                      ),
                                      validator: (text){
                                        if(text!.isEmpty) return "Você precisa digitar seu nome!";
                                        else return null;
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 180,
                                  left: 20,
                                  child: Text("E-mail"),
                                ),
                                Positioned(
                                  top: 200,
                                  left: 20,
                                  child: SizedBox(
                                    //height: 35,
                                    width: 300,
                                    child: TextFormField(
                                      controller: emailCadastroControlador,
                                      obscureText: false,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: "",
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                                        ),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide()),
                                      ),
                                      validator: (text){
                                        if(!text!.contains("@")) return "Certeza que esse é um e-mail válido?";
                                        else return null;
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 280,
                                  left: 20,
                                  child: Text("Senha"),
                                ),
                                Positioned(
                                  top: 300,
                                  left: 20,
                                  child: SizedBox(
                                    //height: 35,
                                    width: 300,
                                    child: TextFormField(
                                      controller: senhaCadastroControlador,
                                      keyboardType: TextInputType.text,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: "",
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                                        ),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide()),
                                      ),
                                      validator: (text){
                                        if(text!.isEmpty) return "A senha não pode ficar em branco!";
                                        if(text.length < 6) return "A senha precisa ter mais do que 6 dígitos!";
                                        else return null;
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 380,
                                  left: 20,
                                  child: SizedBox(
                                    width: 150,
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.black87,
                                      ),
                                      child: Text("Cadastrar", style: TextStyle(color: Colors.white),),
                                      onPressed: (){
                                        if(_formKeyCadastro.currentState!.validate()){
                                          Map<String, dynamic> userData = {
                                            "usuario": nomeCadastroControlador.text,
                                            "email": emailCadastroControlador.text,
                                          };

                                          model.signUp(userData: userData,
                                              pass: senhaCadastroControlador.text,
                                              onSuccess: _onSuccess,
                                              onFail: _onFail
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
  void _onSuccess(){
    setState(() {
      algoErrado = false;
    });

    Navigator.of(context).pop();

  }

  void _onFail(){
    setState(() {
      algoErrado = true;
    });
  }
}