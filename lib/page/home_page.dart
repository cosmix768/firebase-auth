import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return MyWidget(snapshot: snapshot);
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class MyWidget extends StatelessWidget {
  final AsyncSnapshot<User?> snapshot;

  const MyWidget({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Welcome ${snapshot.data!.email}'),
                const SizedBox(height: 20),
                MyTextfield(),
                const SizedBox(height: 20),
                UserDataDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyTextfield extends StatefulWidget {
  const MyTextfield({super.key});

  @override
  _MyTextfieldState createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  final TextEditingController _dataController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitData() async {
    String data = _dataController.text;
    User? currentUser = _auth.currentUser;

    if (data.isNotEmpty && currentUser != null) {
      try {
        await _firestore.collection('user_data').add({
          'uid': currentUser.uid,
          'data': data,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _dataController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data submitted successfully')),
        );
      } catch (e) {
        print("Error submitting data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit data')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _dataController,
              decoration: const InputDecoration(labelText: "Data"),
            ),
          ),
          ElevatedButton(
            onPressed: submitData,
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}

class UserDataDisplay extends StatelessWidget {
  const UserDataDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_data')
          .where('uid', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return const Center(child: Text('No data found for this user'));
        }

        return ListView(
          shrinkWrap: true,
          children: documents.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['data'] ?? 'No data'),
              subtitle: Text(data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate().toString()
                  : 'No timestamp'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('user_data')
                        .doc(doc.id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data deleted successfully')),
                    );
                  } catch (e) {
                    print("Error deleting data: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete data')),
                    );
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
