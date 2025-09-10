import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:memesworld/models/user.dart' as model;
import 'package:memesworld/providers/user_provider.dart';

class CommentCard extends StatefulWidget {
  final DocumentSnapshot snap;

  const CommentCard({super.key, required this.snap});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late Map<String, dynamic> data;
  late String commentId;
  late List likes;
  late model.User user;

  @override
  void initState() {
    super.initState();
    data = widget.snap.data() as Map<String, dynamic>;
    commentId = widget.snap.id;
    likes = data['likes'] is List ? List.from(data['likes']) : [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    user = Provider.of<UserProvider>(context).getUser;
  }

  void toggleLike() async {
    final uid = user.uid;
    final isLiked = likes.contains(uid);

    setState(() {
      if (isLiked) {
        likes.remove(uid);
      } else {
        likes.add(uid);
      }
    });

    await FirebaseFirestore.instance
        .collection('comments') // ⚠️ change if nested under posts
        .doc(commentId)
        .update({'likes': likes});
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? "User";
    final String profilePic = data['profilePic'] ?? "";
    final String commentText = data['text'] ?? "";
    final Timestamp timestamp = data['datePublished'] ?? Timestamp.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage:
            profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
            backgroundColor: profilePic.isEmpty
                ? Colors.primaries[name.hashCode % Colors.primaries.length]
                : null,
            child: profilePic.isEmpty
                ? Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          // Comment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "$name ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: commentText,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(timestamp.toDate()),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Like button
          Column(
            children: [
              IconButton(
                icon: Icon(
                  likes.contains(user.uid)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: likes.contains(user.uid) ? Colors.red : Colors.white,
                  size: 20,
                ),
                onPressed: toggleLike,
              ),
              Text(
                '${likes.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
