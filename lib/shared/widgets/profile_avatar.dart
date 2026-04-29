import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    required this.isGuest,
    required this.radius,
  });

  final AppUser? user;
  final bool isGuest;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageSource = user?.profilePicture.trim() ?? '';
    final initials = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim().characters.first.toUpperCase()
        : isGuest
        ? 'G'
        : 'U';
    final imageProvider = _resolveImageProvider(imageSource);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageProvider != null
          ? Image(
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) =>
                  _AvatarFallback(initials: initials, radius: radius),
            )
          : _AvatarFallback(initials: initials, radius: radius),
    );
  }

  ImageProvider<Object>? _resolveImageProvider(String imageSource) {
    if (imageSource.isEmpty) return null;

    final uri = Uri.tryParse(imageSource);
    final isRemote =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (isRemote) {
      return NetworkImage(imageSource);
    }

    final localFile = File(imageSource);
    if (localFile.existsSync()) {
      return FileImage(localFile);
    }

    return null;
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
