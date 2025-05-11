import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class UserService {
  final CollectionReference _usersCollection = FirebaseService.usersCollection;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return null;
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Stream user by ID
  Stream<UserModel?> streamUserById(String userId) {
    return _usersCollection.doc(userId).snapshots().map(
            (snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null
    );
  }

  // Get matched users
  Future<List<UserModel>> getMatchedUsers(String currentUserId) async {
    try {
      DocumentSnapshot currentUserDoc = await _usersCollection.doc(currentUserId).get();
      if (!currentUserDoc.exists) return [];

      UserModel currentUser = UserModel.fromFirestore(currentUserDoc);
      List<String> matchedUserIds = currentUser.matchedUsers;

      if (matchedUserIds.isEmpty) return [];

      QuerySnapshot matchedUsersSnapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: matchedUserIds)
          .get();

      return matchedUsersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting matched users: $e');
      return [];
    }
  }

  // Stream matched users
  Stream<List<UserModel>> streamMatchedUsers(String currentUserId) {
    return _usersCollection.doc(currentUserId).snapshots().asyncMap(
            (snapshot) async {
          if (!snapshot.exists) return [];

          UserModel currentUser = UserModel.fromFirestore(snapshot);
          List<String> matchedUserIds = currentUser.matchedUsers;

          if (matchedUserIds.isEmpty) return [];

          QuerySnapshot matchedUsersSnapshot = await _usersCollection
              .where(FieldPath.documentId, whereIn: matchedUserIds)
              .get();

          return matchedUsersSnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        }
    );
  }

  // Unmatch users
  Future<void> unmatchUsers(String currentUserId, String otherUserId) async {
    try {
      DocumentReference currentUserRef = _usersCollection.doc(currentUserId);
      DocumentReference otherUserRef = _usersCollection.doc(otherUserId);

      // Remove from current user's matches
      await currentUserRef.update({
        'matchedUsers': FieldValue.arrayRemove([otherUserId])
      });

      // Remove from other user's matches
      await otherUserRef.update({
        'matchedUsers': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      print('Error unmatching users: $e');
      rethrow;
    }
  }
}