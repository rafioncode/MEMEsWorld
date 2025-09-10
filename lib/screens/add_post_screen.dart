import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memesworld/providers/user_provider.dart';
import 'package:memesworld/utils/colors.dart';
import 'package:memesworld/utils/utils.dart';
import 'package:provider/provider.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  AddPostScreenState createState() => AddPostScreenState();
}

class AddPostScreenState extends State<AddPostScreen> {
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> postText(String uid, String username, String profImage) async {
    if (_descriptionController.text.trim().isEmpty) {
      showSnackBar(context, "Caption cannot be empty!");
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'caption': _descriptionController.text.trim(),
        'uid': uid,
        'username': username,
        'profileImage': profImage,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, 'Posted!');
      _descriptionController.clear();
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, err.toString());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);

    if (userProvider.userOrNull == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Post to'),
        centerTitle: false,
        actions: <Widget>[
          TextButton(
            onPressed: _descriptionController.text.trim().isNotEmpty
                ? () => postText(
              userProvider.getUser.uid,
              userProvider.getUser.username,
              userProvider.getUser.photoUrl,
            )
                : null,
            child: const Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundImage: (userProvider.getUser.photoUrl).isNotEmpty
                    ? NetworkImage(userProvider.getUser.photoUrl)
                    : const AssetImage('assets/images/memesworld.png')
                as ImageProvider,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: "Write a caption...",
                    border: InputBorder.none,
                  ),
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
