import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerifyStudentRequestsPage extends StatefulWidget {
  const VerifyStudentRequestsPage({Key? key}) : super(key: key);

  @override
  _VerifyStudentRequestsPageState createState() =>
      _VerifyStudentRequestsPageState();
}

class _VerifyStudentRequestsPageState extends State<VerifyStudentRequestsPage> {
  final CollectionReference _studentRequestsCollection =
      FirebaseFirestore.instance.collection('student_requests');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Student Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _studentRequestsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No student requests'));
          }

          final studentRequests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: studentRequests.length,
            itemBuilder: (context, index) {
              final request = studentRequests[index];
              final data = request.data() as Map<String, dynamic>;
              final email =
                  data.containsKey('emailID') ? data['emailID'] : 'No Email';

              return ListTile(
                title: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        _acceptStudentRequest(request.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _rejectStudentRequest(request.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptStudentRequest(String requestId) async {
    try {
      await _studentRequestsCollection.doc(requestId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student request accepted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept request')),
      );
    }
  }

  void _rejectStudentRequest(String requestId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student request rejected')),
    );
  }
}
