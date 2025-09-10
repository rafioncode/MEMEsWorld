import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memesworld/models/user.dart' as model;
import 'package:memesworld/providers/user_provider.dart';
import 'package:memesworld/screens/comments_screen.dart';
import 'package:memesworld/utils/colors.dart';
import 'package:memesworld/utils/global_variable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final dynamic snap; // DocumentSnapshot or Map

  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> data;
  late model.User user;
  late String postId;
  late List likes;

  @override
  void initState() {
    super.initState();
    data = widget.snap.data() as Map<String, dynamic>? ?? {};
    postId = widget.snap.id;
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
        .collection('posts')
        .doc(postId)
        .update({'likes': likes});
  }

  Future<void> sharePost() async {
    String? recipientEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Share with user'),
          content: TextField(
            controller: controller,
            decoration:
            const InputDecoration(hintText: 'Enter recipient email'),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Send'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (recipientEmail != null && recipientEmail.isNotEmpty) {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('shared_posts').add({
          'from': user.email,
          'to': recipientEmail,
          'postId': postId,
          'caption': data['caption'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post shared with $recipientEmail!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: width > webScreenSize ? secondaryColor : mobileBackgroundColor,
        ),
        color: mobileBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // HEADER SECTION
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16)
                .copyWith(right: 0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['username']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (data['uid']?.toString() == user.uid)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        useRootNavigator: false,
                        context: context,
                        builder: (context) => Dialog(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shrinkWrap: true,
                            children: [
                              InkWell(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: const Text('Delete'),
                                ),
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(postId)
                                      .delete();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ),
          // LIKE & COMMENT & SHARE SECTION
          Row(
            children: [
              IconButton(
                icon: Icon(
                  likes.contains(user.uid)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: likes.contains(user.uid) ? Colors.yellow : null,
                ),
                onPressed: toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(postId: postId),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: sharePost,
              ),
            ],
          ),
          // DESCRIPTION & COMMENTS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Likes count
                Text(
                  '${likes.length} likes',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: primaryColor),
                    children: [
                      TextSpan(
                          text: data['username']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' ${data['caption'] ?? ''}'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => CommentsScreen(postId: postId)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all comments',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    data['timestamp'] != null && data['timestamp'] is Timestamp
                        ? DateFormat.yMMMd()
                        .format((data['timestamp'] as Timestamp).toDate())
                        : '',
                    style: const TextStyle(color: secondaryColor),
                  ),
                ),
                // COMMENTS SECTION
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!.docs.map((doc) {
                        final comment =
                            doc.data() as Map<String, dynamic>? ?? {};
                        final commentText =
                            comment['text']?.toString().trim() ?? '';
                        if (commentText.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '${comment['username'] ?? 'User'}: $commentText',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
