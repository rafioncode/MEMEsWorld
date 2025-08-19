import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String description;
  final String uid;
  final String username;
  final List likes; // ✅ fixed type
  final String postId;
  final DateTime datePublished; // ✅ proper type
  final String postUrl;
  final String profImage;

  const Post({
    required this.description,
    required this.uid,
    required this.username,
    required this.likes,
    required this.postId,
    required this.datePublished,
    required this.postUrl,
    required this.profImage,
  });

  // Convert Firestore snapshot to Post
  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      description: snapshot["description"] ?? '',
      uid: snapshot["uid"] ?? '',
      username: snapshot["username"] ?? '',
      likes: snapshot["likes"] ?? [],
      postId: snapshot["postId"] ?? '',
      datePublished: (snapshot["datePublished"] as Timestamp).toDate(), // ✅ convert Timestamp → DateTime
      postUrl: snapshot['postUrl'] ?? '',
      profImage: snapshot['profImage'] ?? '',
    );
  }

  // Convert Post to JSON (for Firestore)
  Map<String, dynamic> toJson() => {
    "description": description,
    "uid": uid,
    "username": username,
    "likes": likes,
    "postId": postId,
    "datePublished": datePublished,
    "postUrl": postUrl,
    "profImage": profImage,
  };
}
