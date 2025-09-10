import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memesworld/resources/auth_methods.dart';
import 'package:memesworld/resources/firestore_methods.dart';
import 'package:memesworld/screens/login_screen.dart';
import 'package:memesworld/utils/colors.dart';
import 'package:memesworld/utils/utils.dart';
import 'package:memesworld/widgets/follow_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      if (!mounted) return;

      final data = userSnap.data() ?? {};
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        userData = data;
        postLen = postSnap.docs.length;
        followers = data['followers']?.length ?? 0;
        following = data['following']?.length ?? 0;
        isFollowing = data['followers']?.contains(currentUid) ?? false;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(userData['username'] ?? ''),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage: userData['photoUrl'] != null
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildStatColumn(postLen, "posts"),
                              buildStatColumn(followers, "followers"),
                              buildStatColumn(following, "following"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildActionButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userData['username'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(userData['bio'] ?? ''),
                ),
              ],
            ),
          ),
          const Divider(),
          buildPostsGrid(),
        ],
      ),
    );
  }

  Widget buildActionButton() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == widget.uid) {
      return FollowButton(
        text: 'Sign Out',
        backgroundColor: mobileBackgroundColor,
        textColor: primaryColor,
        borderColor: Colors.grey,
        function: () async {
          await AuthMethods().signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      );
    }

    return isFollowing
        ? FollowButton(
      text: 'Unfollow',
      backgroundColor: Colors.white,
      textColor: Colors.black,
      borderColor: Colors.grey,
      function: () async {
        await FireStoreMethods().followUser(currentUid!, userData['uid']);
        if (!mounted) return;
        setState(() {
          isFollowing = false;
          followers--;
        });
      },
    )
        : FollowButton(
      text: 'Follow',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      borderColor: Colors.blue,
      function: () async {
        await FireStoreMethods().followUser(currentUid!, userData['uid']);
        if (!mounted) return;
        setState(() {
          isFollowing = true;
          followers++;
        });
      },
    );
  }

  Widget buildPostsGrid() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No posts yet"));
        }

        final posts = snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 1.5,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final snap = posts[index].data();
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  snap['caption'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
