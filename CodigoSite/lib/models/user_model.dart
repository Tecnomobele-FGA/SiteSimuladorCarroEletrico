import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'dart:async';

class UserModel extends Model {
  late String colecao;
  late String documento1;
  late String documento2;
  late String produtoId;
  late String uidd;
  late String tipo;
  late bool logado;
  late String caminho;
  late bool isArquivo;
  late List<dynamic> velocidade;
  late List<dynamic> altitude;
  late bool administrador;
  String nome = "";
  FirebaseAuth _auth = FirebaseAuth.instance;
  User? firebaseUser;
  Map<String, dynamic> userData = Map();
  double massa = -999;
  double frontal = -999;
  double ca = -999;


  bool isLoading = false;

  void signUp({required Map<String, dynamic> userData, required String pass, required VoidCallback onSuccess, required VoidCallback onFail}){
    isLoading = true;
    notifyListeners();
    _auth.createUserWithEmailAndPassword(
        email: userData["email"],
        password: pass
    ).then((auth) async{
      firebaseUser = auth.user!;
      await _saveUserData(userData);
      onSuccess();
      isLoading = false;
      notifyListeners();
    }).catchError((e){
      onFail();
      isLoading = false;
      notifyListeners();
    });
  }
  void signIn({required String email, required String pass, required VoidCallback onSuccess, required VoidCallback onFail}) async{
    isLoading = true;
    notifyListeners();

    _auth.signInWithEmailAndPassword(email: email, password: pass).then(
            (auth) async{
          firebaseUser = auth.user!;
          onSuccess();
          isLoading = false;
          notifyListeners();
        }).catchError((e){
      onFail();
      isLoading = false;
      notifyListeners();
    });
  }
  void recoverPass(String email){
    _auth.sendPasswordResetEmail(email: email);
  }

  bool isLoggedIn(){
    return firebaseUser != null;
  }

  void signOut() async{
    print(isLoggedIn());
    //await FirebaseAuth.instance.signOut();
    //print(isLoggedIn());
    await _auth.signOut();
    nome = "";
    userData = Map();
    notifyListeners();
  }

  void nomeUsuario() async{
    if(isLoggedIn() == true) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(
          'usuarios').doc("${firebaseUser!.uid}").get();
      nome = snapshot["usuario"].toString();
      notifyListeners();
    }
  }

  void Administrador() async{
    if(isLoggedIn() == true) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(
          'usuarios').doc("${firebaseUser!.uid}").get();
      snapshot["administrador"] == true ? administrador = true : administrador == false;
      notifyListeners();
    }else{
      administrador = false;
    }
  }

  Future<Null> _saveUserData(Map<String, dynamic> userData) async{
    this.userData = userData;
    await FirebaseFirestore.instance.collection("usuarios").doc(firebaseUser!.uid).set(userData);
    await FirebaseFirestore.instance.collection("usuarios").doc(firebaseUser!.uid).update({"administrador" : false});
  }
}

