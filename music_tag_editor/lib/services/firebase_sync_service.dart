import 'dart:async';
import 'package:meta/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_tag_editor/services/database_service.dart';

/// Service for syncing library data to Firebase Cloud.
class FirebaseSyncService {
  static FirebaseSyncService _instance = FirebaseSyncService._internal();
  static FirebaseSyncService get instance => _instance;

  @visibleForTesting
  static set instance(FirebaseSyncService mock) => _instance = mock;

  FirebaseSyncService._internal();

  FirebaseFirestore? _firestoreOverride;
  FirebaseAuth? _authOverride;
  DatabaseService? _dbOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  DatabaseService get _db => _dbOverride ?? DatabaseService.instance;

  @visibleForTesting
  void setDependencies({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DatabaseService? db,
  }) {
    _firestoreOverride = firestore;
    _authOverride = auth;
    _dbOverride = db;
  }

  bool _syncEnabled = false;
  User? _currentUser;
  StreamSubscription? _authSubscription;

  /// Whether cloud sync is enabled.
  bool get syncEnabled => _syncEnabled;

  /// Current signed-in user.
  User? get currentUser => _currentUser;

  /// Initialize the sync service.
  Future<void> init() async {
    _authSubscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null && _syncEnabled) {
        _startSync();
      }
    });
  }

  /// Enable cloud sync with anonymous sign-in.
  Future<bool> enableSync() async {
    try {
      // Sign in anonymously if not already signed in
      if (_currentUser == null) {
        await _auth.signInAnonymously();
      }
      _syncEnabled = true;
      await _startSync();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disable cloud sync.
  Future<void> disableSync() async {
    _syncEnabled = false;
  }

  /// Sync all local data to cloud.
  Future<void> _startSync() async {
    if (_currentUser == null) {
      return;
    }

    await _syncTracks();
    await _syncPlaylists();
    await _syncSettings();
  }

  /// Sync tracks to Firestore.
  Future<void> _syncTracks() async {
    if (_currentUser == null) {
      return;
    }

    final userId = _currentUser!.uid;
    final tracks = await _db.getTracks();

    final batch = _firestore.batch();
    final tracksRef =
        _firestore.collection('users').doc(userId).collection('tracks');

    for (final track in tracks) {
      final docRef = tracksRef.doc(track['id']);
      batch.set(
          docRef,
          {
            ...track,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Sync playlists to Firestore.
  Future<void> _syncPlaylists() async {
    if (_currentUser == null) {
      return;
    }

    final userId = _currentUser!.uid;
    final playlists = await _db.getPlaylists();

    final batch = _firestore.batch();
    final playlistsRef =
        _firestore.collection('users').doc(userId).collection('playlists');

    for (final playlist in playlists) {
      final docRef = playlistsRef.doc(playlist['id'].toString());
      final tracks = await _db.getPlaylistTracks(playlist['id']);

      batch.set(
          docRef,
          {
            ...playlist,
            'trackIds': tracks.map((t) => t['id']).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Sync settings to Firestore.
  Future<void> _syncSettings() async {
    if (_currentUser == null) {
      return;
    }

    final userId = _currentUser!.uid;
    final settings = await _db.getAllSettings();

    await _firestore.collection('users').doc(userId).set({
      'settings': settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Pull data from cloud to local.
  Future<int> pullFromCloud() async {
    if (_currentUser == null) {
      return 0;
    }

    final userId = _currentUser!.uid;
    int syncedCount = 0;

    // Pull tracks
    final tracksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tracks')
        .get();

    for (final doc in tracksSnapshot.docs) {
      await _db.saveTrack(doc.data());
      syncedCount++;
    }

    // Pull playlists
    final playlistsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .get();

    for (final doc in playlistsSnapshot.docs) {
      final data = doc.data();
      final playlistId = await _db.createPlaylist(
        data['name'],
        description: data['description'],
      );

      final trackIds = data['trackIds'] as List? ?? [];
      for (final trackId in trackIds) {
        await _db.addTrackToPlaylist(playlistId, trackId);
      }
      syncedCount++;
    }

    return syncedCount;
  }

  /// Get sync status.
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (_currentUser == null) {
      return {'status': 'not_signed_in'};
    }

    final userId = _currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return {'status': 'no_data'};
    }

    return {
      'status': 'synced',
      'lastSync': userDoc.data()?['updatedAt'],
      'userId': userId,
    };
  }

  /// Sign out and clear sync.
  Future<void> signOut() async {
    _syncEnabled = false;
    await _auth.signOut();
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}

