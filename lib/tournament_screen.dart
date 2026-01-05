import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'payment_service.dart';
import 'room_screen.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  Future<bool> alreadyJoined(String tournamentId) async {
    final user = FirebaseAuth.instance.currentUser;

    final result = await FirebaseFirestore.instance
        .collection('joins')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('userId', isEqualTo: user!.uid)
        .get();

    return result.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tournaments available'));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['title']),
                  subtitle: Text(
                    '${data['game']} • ${data['date']} • ${data['time']}',
                  ),
                  trailing: ElevatedButton(
                    child: Text('Pay ₹${data['entryFee']}'),
                    onPressed: () async {
                      final joined = await alreadyJoined(doc.id);

                      if (joined) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You already joined this match'),
                          ),
                        );
                        return;
                      }

                      final payment = PaymentService();

                      payment.init(
                        onSuccess: () async {
                          final user =
                              FirebaseAuth.instance.currentUser;

                          await FirebaseFirestore.instance
                              .collection('joins')
                              .add({
                            'tournamentId': doc.id,
                            'userId': user!.uid,
                            'email': user.email,
                            'joinedAt': Timestamp.now(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Joined Successfully 🎉'),
                            ),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomScreen(
                                roomId: data['roomId'],
                                roomPassword:
                                    data['roomPassword'],
                              ),
                            ),
                          );
                        },
                        onFailure: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Payment Failed ❌'),
                            ),
                          );
                        },
                      );

                      payment.openCheckout(
                        amount: data['entryFee'],
                        description: data['title'],
                        email: FirebaseAuth.instance
                                .currentUser?.email ??
                            '',
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
