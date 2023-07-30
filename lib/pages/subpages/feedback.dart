import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lalo/pages/subpages/login.dart';
import 'package:lalo/services/services.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Feedback'),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[400],
                    child: Text(
                      user!.displayName?.substring(0, 2).toUpperCase() ?? 'HI',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.feedback,
                  size: 100,
                  color: Colors.orange,
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('Feedback',
                      style: Theme.of(context).textTheme.displaySmall)),
              Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Form(
                      key: _formKey,
                      child: TextFormField(
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        validator: (String? text) {
                          if (text == null || text.trim().isEmpty) {
                            return 'Please enter your feedback';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Your feedback'),
                      ))),
              Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await FirebaseFirestore.instance
                              .doc('feedback/${user!.uid}')
                              .set({
                            DateTime.now().millisecondsSinceEpoch.toString():
                                _controller.text
                          }, SetOptions(merge: true));
                          Navigator.pop(context);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text('Submit', style: TextStyle(fontSize: 18)),
                      ))),
            ],
          ));
    } else {
      return const LoginPage();
    }
  }
}
