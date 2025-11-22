import 'package:flutter/marterial.dart';
import 'package:ppb_journey_app/services/auth_service.dart';

class LoginScreen extends StatefulWidgets(){
    const LoginScreen({super.key})

    @override
    State<LoginScreen> loginState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditorController();
    final _passwordController = TextEditorController();

    return Scaffold(
        appBar: AppBar(title: Text('Login Screen'),
        body: Padding(padding: EdgeInsets.all(16), child: Form(
            key: _formKey,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    TextFormField(
                        controller: _usernameController,
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.email)
                    ),
                    SizedBox(
                        height: 16,
                    ),
                    TextFormField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.key)
                    ),
                    SizedBox(
                        height: 16,
                    ),
                    ElevatedButton.icon(
                        onTap: (){},
                        Icon: Icons.door,
                        label: Text('Login')
                    )
                ]
            )
        ))))
    
}