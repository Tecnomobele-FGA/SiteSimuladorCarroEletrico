import 'package:apps_flutter2/classes/dadosCarro.dart';
import 'package:apps_flutter2/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class escolherVeiculo extends StatefulWidget {
  const escolherVeiculo({Key? key}) : super(key: key);

  @override
  _escolherVeiculoState createState() => _escolherVeiculoState();
}

class _escolherVeiculoState extends State<escolherVeiculo> {

  List<dadoCarro> dadosCarros = [];
  List<String> nomesVerificador = [];
  List<DropdownMenuItem<String>> nomeCarros = [];
  String carroEscolhido = "Escolher Carro";
  bool terminouCarroEscolhido = false;
  double ca = 999;
  double massa = 999;
  double frontal = 999;
  final formKey = GlobalKey<FormState>();
  late double massaAdicionar;
  late double caAdicionar;
  late double frontalAdicionar;
  late String nomeAdicionar;

  @override
  void initState(){
    // TODO: implement initState
    inicia();
    super.initState();
  }

  void inicia() async{
    QuerySnapshot banco = await FirebaseFirestore.instance.collection("carros").get();
    banco.docs.forEach((element) {
      nomesVerificador.add(element.get("nome").toString());
      nomeCarros.add(DropdownMenuItem(
        value: element.get("nome").toString(),
        child: Text(element.get("nome")),
      ));
      dadosCarros.add(
          dadoCarro(nome: element.get("nome").toString(),ca: double.parse(element.get("ca").toString()), frontal: double.parse(element.get("frontal").toString()) ,massa: double.parse(element.get("massa").toString()))
      );
    });
    setState(() {
      carroEscolhido = nomeCarros[0].value.toString();
      terminouCarroEscolhido = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<UserModel>(
      builder: (context, child, model){
        return Padding(
          padding: EdgeInsets.fromLTRB(10, 5,10, 2),
          child: Visibility(
            visible: terminouCarroEscolhido,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        items: nomeCarros,
                        value: carroEscolhido,
                        onChanged: (e){
                          dadosCarros.retainWhere((element){
                            if(element.nome == e){
                              ca = double.parse(element.ca.toString());
                              model.ca = double.parse(element.ca.toString());
                              massa = double.parse(element.massa.toString());
                              model.massa = double.parse(element.massa.toString());
                              frontal = double.parse(element.frontal.toString());
                              model.frontal = double.parse(element.frontal.toString());
                            }
                            setState(() {
                              ca = ca;
                              carroEscolhido = e!;
                            });
                            return true;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5,),
                Visibility(
                  visible: ca != 999 && carroEscolhido != "Adicionar Carro",
                  child: Column(
                    children: [
                      Text("massa(kg):"),
                      Text("Área frontal(m2):"),
                      Text("Coeficiente aerodinâmica:")
                    ],
                  ),
                ),
                SizedBox(width: 5,),
                Visibility(
                  visible: ca != 999 && carroEscolhido != "Adicionar Carro",
                  child: Column(
                    children: [
                      Text("$massa"),
                      Text("$frontal"),
                      Text("$ca")
                    ],
                  ),
                ),
                Visibility(
                  visible: ca != 999 && carroEscolhido == "Adicionar Carro",
                  child: formulario(),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget formulario(){
    return Form(
      key: formKey,
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: TextFormField(
              decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(10.0),
                    ),
                  ),
                  filled: true,
                  hintStyle: new TextStyle(color: Colors.grey[800]),
                  hintText: "Digite o nome do carro",
                  fillColor: Colors.white70
              ),
              validator: (valor){
                if(nomesVerificador.contains(valor)){
                  return "O carro já está cadastrado";
                }
                if(valor!.length < 1 || valor.length > 30){
                  return "Informe o nome correto";
                }else{
                  return null;
                }
              },
              onSaved: (valor){
                setState(() {
                  nomeAdicionar = valor.toString();
                });
              },
            ),
          ),
          SizedBox(
            height: 3,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: TextFormField(
              decoration: new InputDecoration(
                border: new OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                    const Radius.circular(10.0),
                  ),
                ),
                  filled: true,
                  hintStyle: new TextStyle(color: Colors.grey[800]),
                  hintText: "Digite a massa do carro em quilogramas",
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
                  massaAdicionar = double.parse(valor.toString());
                });
              },
            ),
          ),
          SizedBox(
            height: 3,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: TextFormField(
              decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(10.0),
                    ),
                  ),
                  filled: true,
                  hintStyle: new TextStyle(color: Colors.grey[800]),
                  hintText: "Digite a área frontal",
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
                  frontalAdicionar = double.parse(valor.toString());
                });
              },
            ),
          ),
          SizedBox(
            height: 3,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: TextFormField(
              decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(10.0),
                    ),
                  ),
                  filled: true,
                  hintStyle: new TextStyle(color: Colors.grey[800]),
                  hintText: "Digite o coeficiente aerodinâmico",
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
                  caAdicionar = double.parse(valor.toString());
                });
              },
            ),
          ),
          SizedBox(
            height: 3,
          ),
          TextButton(
            child: Text("Validar"),
            onPressed: () async{
              if(formKey.currentState!.validate()){
                formKey.currentState!.save();
                await FirebaseFirestore.instance.collection("carros").add({
                  "ca": caAdicionar,
                  "frontal": frontalAdicionar,
                  "nome": nomeAdicionar,
                  "massa": massaAdicionar
                });
                nomesVerificador = [];
                dadosCarros = [];
                nomeCarros = [];
                inicia();
              }
            },
          ),
        ],
      ),
    );
  }
}
