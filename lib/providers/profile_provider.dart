import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileState {
  final String? fullName;
  final String? username;
  final String? email;
  final DateTime? dob;
  final String? gender;
  final double? height;
  final double? weight;
  final String? avatarPath; // store relative path only
  final bool loading;

  const ProfileState({
    this.fullName,
    this.username,
    this.email,
    this.dob,
    this.gender,
    this.height,
    this.weight,
    this.avatarPath,
    this.loading = false,
  });

  ProfileState copyWith({
    String? fullName,
    String? username,
    String? email,
    DateTime? dob,
    String? gender,
    double? height,
    double? weight,
    String? avatarPath,
    bool? loading,
  }) {
    return ProfileState(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      avatarPath: avatarPath ?? this.avatarPath,
      loading: loading ?? this.loading,
    );
  }

  /// Helper to get full public URL for avatar
  String? get avatarUrl {
    if (avatarPath == null || avatarPath!.isEmpty) return null;
    if (avatarPath!.startsWith('http')) return avatarPath;
    return "https://phrvarboqhiowgtiogle.supabase.co/storage/v1/object/public/profiles/$avatarPath";
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  /// Fetch profile from DB
  Future<void> loadProfile() async {
    try {
      state = state.copyWith(loading: true);
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      final profileData = await _supabase
          .from('user_details')
          .select()
          .eq('id', user.id)
          .single();

      if (profileData != null) {
        String? avatarPath;
        if (profileData['avatar_url'] != null && profileData['avatar_url'].isNotEmpty) {
          // Keep only relative path if stored as full URL
          final url = profileData['avatar_url'] as String;
          if (url.startsWith('http')) {
            avatarPath = url.split('/profiles/').last;
          } else {
            avatarPath = url;
          }
        }

        state = state.copyWith(
          username: profileData['username'],
          email: profileData['email'],
          dob: profileData['dob'] != null ? DateTime.parse(profileData['dob']) : null,
          gender: profileData['gender'],
          height: profileData['height_cm'] != null ? (profileData['height_cm'] as num).toDouble() : null,
          weight: profileData['weight_kg'] != null ? (profileData['weight_kg'] as num).toDouble() : null,
          avatarPath: avatarPath,
          loading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  /// Pick & Upload avatar → update `avatar_url` in DB (store relative path)
  Future<void> pickAndUploadAvatar() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      state = state.copyWith(loading: true);

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      final filePath = "${user.id}/profile.png";

      // Upload to Supabase storage
      await _supabase.storage.from("profiles").upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Update DB with relative path only
      await _supabase.from("user_details").update({
        "avatar_url": filePath,
      }).eq("id", user.id);

      state = state.copyWith(avatarPath: filePath, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  /// Update metrics in DB
  Future<void> updateMetrics({
    double? weight,
    double? height,
    String? gender,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(loading: true);

      final updates = <String, dynamic>{
        if (weight != null) 'weight_kg': weight.toDouble(),
        if (height != null) 'height_cm': height.toDouble(),
        if (gender != null) 'gender': gender,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (updates.isNotEmpty) {
        await _supabase.from('user_details').update(updates).eq('id', user.id);
      }

      state = state.copyWith(
        weight: weight ?? state.weight,
        height: height ?? state.height,
        gender: gender ?? state.gender,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false);
      print("Error updating metrics: $e");
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final notifier = ProfileNotifier();
  notifier.loadProfile();
  return notifier;
});
