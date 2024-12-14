import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ComplainPage extends StatefulWidget {
  const ComplainPage({Key? key}) : super(key: key);

  @override
  _ComplainPageState createState() => _ComplainPageState();
}

class _ComplainPageState extends State<ComplainPage> {
  late User? user;
  List<QueryDocumentSnapshot> complaints = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('complains') // Ensure the collection name matches
          .where('receiver',
              isEqualTo: user?.uid) // Changed to use UID instead of email
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        complaints = snapshot.docs;
      });
    } catch (error) {
      print('Error fetching complaints: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _fetchComplaints,
                child: const Text('Refresh'),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                final String message =
                    complaint['complaint']; // Ensure the field name matches
                final String sender = complaint['sender'];
                final Timestamp timestamp = complaint['timestamp'];

                return ListTile(
                  leading: const Icon(Icons.message),
                  title: Text(message),
                  subtitle: Text('From: $sender'),
                  trailing: Text('Date: ${timestamp.toDate().toString()}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
