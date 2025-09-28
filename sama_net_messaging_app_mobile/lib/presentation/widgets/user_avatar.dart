import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sama_net_messaging_app_mobile/core/di/service_locator.dart';
import 'package:sama_net_messaging_app_mobile/data/models/user.dart';
import 'package:sama_net_messaging_app_mobile/data/services/file_service.dart';

/// Reusable user avatar widget that prioritizes profile images
/// and gracefully falls back to displaying user initials.
class UserAvatar extends StatelessWidget {
	final User user;
	final double radius;
	final Color? backgroundColor;
	final TextStyle? textStyle;

	static final FileService _fileService = serviceLocator.get<FileService>();

	const UserAvatar({super.key, required this.user, this.radius = 24, this.backgroundColor, this.textStyle});

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final avatarPath = user.avatarPath;
		final initials = user.initials;
		final bgColor = backgroundColor ?? theme.colorScheme.primary;
		final initialsStyle = textStyle ??
				TextStyle(
					color: theme.colorScheme.onPrimary,
					fontWeight: FontWeight.bold,
					fontSize: radius * 0.9,
				);

		if (avatarPath != null && avatarPath.isNotEmpty) {
			final imageUrl = _fileService.getStreamUrl(avatarPath);
			return CircleAvatar(
				radius: radius,
				backgroundColor: Colors.transparent,
				child: ClipOval(
					child: CachedNetworkImage(
						imageUrl: imageUrl,
						width: radius * 2,
						height: radius * 2,
						fit: BoxFit.cover,
						placeholder: (context, url) => _buildInitialsCircle(bgColor, initialsStyle, initials),
						errorWidget: (context, url, error) => _buildInitialsCircle(bgColor, initialsStyle, initials),
					),
				),
			);
		}

		return _buildInitialsCircle(bgColor, initialsStyle, initials);
	}

	Widget _buildInitialsCircle(Color bgColor, TextStyle textStyle, String initials) {
		return CircleAvatar(
			radius: radius,
			backgroundColor: bgColor,
			child: Text(initials, style: textStyle, textAlign: TextAlign.center),
		);
	}
}

