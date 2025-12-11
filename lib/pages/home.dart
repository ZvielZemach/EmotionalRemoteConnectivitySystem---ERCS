import 'package:flutter/material.dart';
import 'package:my_app/data/userData.dart';
import 'package:my_app/pages/SelectionPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formkey = GlobalKey<FormState>();
  var name = '';
  var password = '';
  var user = '';
  String message = '';
  void _checkUser() {
    final valid = _formkey.currentState!.validate();
    if (valid) {
      _formkey.currentState!.save();
      setState(() {
        if (user == 'Hadar cohen') {
          print(user);
          message =
              "Hello my darling, did i told you how much i love you today?\n";

          "if not , so i want you to know that you are the love of my life!, and since i met you i became the happiest person i all over the world";
        } else {
          print(user);
          message = "hi Tzviel";
        }
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => Selectionpage(userType: user, name: name),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "hello & good morning",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Hadar&Tzviel.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Hello, please enter your details"),
                  TextFormField(
                    maxLength: 50,
                    decoration: const InputDecoration(
                      label: Text(
                        'name',
                        style: TextStyle(color: Colors.white70, fontSize: 25),
                      ),
                      icon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      var isExist = false;
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length == 1) {
                        return 'Name must be between 1 to 50 charecters';
                      }
                      for (var index = 0; index < users.length; index++) {
                        if (users[index].name == value) {
                          isExist = true;
                        }
                      }
                      if (!isExist) {
                        return 'You are not allow to enter';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      setState(() {
                        name = value!;
                      });
                    },
                  ),
                  TextFormField(
                    maxLength: 10,
                    obscureText: true,
                    decoration: const InputDecoration(
                      label: Text('password'),
                      hintText: 'Enter your phone number',
                      icon: Icon(Icons.password),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var isExist = false;
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length <= 1) {
                        return 'Enter your password';
                      }
                      for (var index = 0; index < users.length; index++) {
                        if (value == users[index].password.toString()) {
                          isExist = true;
                          setState(() {
                            user = users[index].userType.name;
                          });
                        }
                      }
                      if (!isExist) {
                        return 'You are not allowed to enter';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      setState(() {
                        password = newValue!;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: _checkUser,
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      width: 120,
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 135, 210, 248),
                            Color.fromARGB(255, 229, 118, 248),
                          ],
                        ),
                      ),
                      child: const Text(
                        'Enter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
