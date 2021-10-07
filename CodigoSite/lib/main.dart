import 'package:apps_flutter2/Telas/HomeScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'models/user_model.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScopedModel<UserModel>(
        model: UserModel(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tecnomobele',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: HomePage(),
        )
    );
  }
}
