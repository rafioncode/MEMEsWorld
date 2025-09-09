import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memesworld/models/user.dart' as model;
import 'package:memesworld/providers/user_provider.dart';
import 'package:memesworld/resources/database_method.dart';
import 'package:memesworld/screens/comments_screen.dart';
import 'package:memesworld/utils/colors.dart';
import 'package:memesworld/utils/global_variable.dart';
import 'package:memesworld/utils/utils.dart';
import 'package:memesworld/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot snap; // Explicit type annotation

  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int commentLen = 0;
  bool isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    fetchCommentLen();
  }

  Future<void> fetchCommentLen() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      if (!mounted) return; // Avoid using context across async gaps
      setState(() {
        commentLen = snap.docs.length;
      });
    } catch (err) {
      if (!mounted) return;
      showSnackBar(context, err.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await DatabaseMethods().deletePost(postId);
    } catch (err) {
      if (!mounted) return;
      showSnackBar(context, err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
          width > webScreenSize ? secondaryColor : mobileBackgroundColor,
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
                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                  NetworkImage(widget.snap['profImage'].toString()),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.snap['username'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.snap['uid'].toString() == user.uid)
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
                                onTap: () {
                                  deletePost(widget.snap['postId'].toString());
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
          // IMAGE SECTION
          GestureDetector(
            onDoubleTap: () {
              DatabaseMethods().likePost(
                  widget.snap['postId'].toString(),
                  user.uid,
                  widget.snap['likes']);
              setState(() => isLikeAnimating = true);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: Image.network(
                    widget.snap['postUrl'].toString(),
                    fit: BoxFit.cover,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      setState(() => isLikeAnimating = false);
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // LIKE & COMMENT SECTION
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user.uid),
                smallLike: true,
                child: IconButton(
                  icon: widget.snap['likes'].contains(user.uid)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border),
                  onPressed: () => DatabaseMethods().likePost(
                      widget.snap['postId'].toString(),
                      user.uid,
                      widget.snap['likes']),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CommentsScreen(postId: widget.snap['postId'].toString()),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: () {}),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                      icon: const Icon(Icons.bookmark_border), onPressed: () {}),
                ),
              ),
            ],
          ),
          // DESCRIPTION & COMMENTS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.snap['likes'].length} likes',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: primaryColor),
                    children: [
                      TextSpan(
                          text: widget.snap['username'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' ${widget.snap['description']}'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                            postId: widget.snap['postId'].toString())),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all $commentLen comments',
                      style: const TextStyle(fontSize: 16, color: secondaryColor),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    DateFormat.yMMMd()
                        .format((widget.snap['datePublished'] as Timestamp).toDate()),
                    style: const TextStyle(color: secondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
