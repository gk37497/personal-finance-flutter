import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// [START listen_to_realtime_updates_listen_for_updates2]
class Transactions extends StatefulWidget {
  const Transactions({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _TransactionsState createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  bool showIncomes = false;

  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('transaction')
      .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

  void setShowIncomes(bool value) {
    setState(() {
      showIncomes = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _usersStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading");
            }

            List<DocumentSnapshot> data = snapshot.data!.docs;
            return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: SizedBox(
                height: 500,
                width: 300,
                child: ListView(
                  children: data
                      .map((DocumentSnapshot document) {
                        Map<String, dynamic> data =
                            document.data()! as Map<String, dynamic>;
                        return ListTile(
                          tileColor: data['type'] == 'INCOME'
                              ? Colors.amber
                              : Colors.blue,
                          title: Text(data['title']),
                          subtitle: Text(data['amount'].toString()),
                          leading: Icon(
                            data['type'] == 'INCOME' ? Icons.add : Icons.remove,
                          ),
                          trailing: const IconButton(
                            onPressed: null,
                            icon: Icon(Icons.delete),
                          ),
                          style: ListTileStyle.list,
                        );
                      })
                      .toList()
                      .cast(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
// [END listen_to_realtime_updates_listen_for_updates2]