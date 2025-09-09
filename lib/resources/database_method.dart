import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:memesworld/models/post.dart';
import 'package:memesworld/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class DatabaseMethods {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<String> uploadPost(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1();

      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
      );

      await _db.child("posts/$postId").set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> likePost(String postId, String uid) async {
    try {
      DatabaseReference likesRef = _db.child("posts/$postId/likes/$uid");
      final snapshot = await likesRef.get();

      if (snapshot.exists) {
        await likesRef.remove(); // unlike
      } else {
        await likesRef.set(true); // like
      }
      return "success";
    } catch (err) {
      return err.toString();
    }
  }

  Future<String> postComment(
    String postId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _db.child("posts/$postId/comments/$commentId").set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now().toIso8601String(),
        });
        return "success";
      } else {
        return "Please enter text";
      }
    } catch (err) {
      return err.toString();
    }
  }

  Future<String> deletePost(String postId) async {
    try {
      await _db.child("posts/$postId").remove();
      return "success";
    } catch (err) {
      return err.toString();
    }
  }

  Future<void> followUser(String uid, String followId) async {
    final userFollowingRef = _db.child("users/$uid/following/$followId");
    final userFollowerRef = _db.child("users/$followId/followers/$uid");

    final snapshot = await userFollowingRef.get();

    if (snapshot.exists) {
      await userFollowingRef.remove();
      await userFollowerRef.remove();
    } else {
      await userFollowingRef.set(true);
      await userFollowerRef.set(true);
    }
  }
}
