import 'package:flutter/material.dart';
import 'package:lalo/services/services.dart';

class NamePage extends StatefulWidget {
  const NamePage({Key? key}) : super(key: key);

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(
            Icons.lightbulb,
            size: 100,
            color: Colors.orange,
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text('Your name',
                style: Theme.of(context).textTheme.displaySmall)),
        const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'This is used so that your friends know who you are. Only your friends can see your name.',
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            )),
        Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
                key: _formKey,
                child: TextFormField(
                  keyboardType: TextInputType.name,
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  validator: (String? text) {
                    if (text == null || text.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Your name'),
                ))),
        Padding(
            padding: const EdgeInsets.all(15.0),
            child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await user!.updateDisplayName(_controller.text);
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text('Next', style: TextStyle(fontSize: 18)),
                ))),
      ],
    ));
  }
}
