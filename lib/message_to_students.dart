import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageToStudentPage extends StatelessWidget {
  const MessageToStudentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching data: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var messages = snapshot.data!.docs;

          if (messages.isEmpty) {
            return const Center(
              child: Text('No messages available.'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: messages.map((doc) {
                var message = doc.data() as Map<String, dynamic>;
                String title = message['title'] ?? 'N/A';
                String content = message['message'] ?? 'N/A';
                String sender = message['sender'] ?? 'N/A';
                DateTime timestamp =
                    (message['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: const TextStyle(fontSize: 25),
                        ),
                        const SizedBox(height: 10),
                        Text('Sent by: $sender'),
                        Text('Sent on: ${timestamp.toString()}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
