import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/user.dart';
import '../../data/services/file_service.dart';
import '../../data/services/user_service.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/bloc_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  late final UserService _userService;
  late final FileService _fileService;
  AuthBloc? _authBloc;
  User? _user;
  bool _isUpdatingAvatar = false;

  @override
  void initState() {
    super.initState();
    _userService = serviceLocator.get<UserService>();
    _fileService = serviceLocator.get<FileService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authBloc ??= BlocProvider.of<AuthBloc>(context);
    if (_user == null) {
      _initializeUser();
    }
  }

  void _initializeUser() {
    final bloc = _authBloc;
    if (bloc == null) return;

    if (bloc.currentUser != null) {
      setState(() {
        _user = bloc.currentUser;
      });
      return;
    }

    final state = bloc.state;
    if (state is AuthAuthenticated) {
      setState(() {
        _user = state.user;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_user == null || _isUpdatingAvatar) return;

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
      if (pickedFile == null) {
        return;
      }

      final filePath = pickedFile.path;
      final fileSize = await _fileService.getFileSize(filePath);

      if (!_fileService.isFileSizeValid(fileSize)) {
        if (!mounted) return;
        _showSnackBar(ArabicStrings.avatarFileTooLarge, isError: true);
        return;
      }

      final messageType = _fileService.getMessageTypeFromFile(filePath);
      if (messageType != AppConstants.messageTypeImage) {
        if (!mounted) return;
        _showSnackBar(ArabicStrings.avatarInvalidImageType, isError: true);
        return;
      }

      setState(() {
        _isUpdatingAvatar = true;
      });

      final uploadResponse = await _fileService.uploadFile(filePath: filePath, messageType: messageType);
      if (!uploadResponse.isSuccess || uploadResponse.data?.filePath == null) {
        if (!mounted) return;
        _showSnackBar(ArabicStrings.avatarUpdateFailure, isError: true);
        return;
      }

      final updatedResponse = await _userService.updateAvatar(
        userId: _user!.id,
        avatarPath: uploadResponse.data!.filePath!,
      );

      if (!updatedResponse.isSuccess || updatedResponse.data == null) {
        if (!mounted) return;
        _showSnackBar(ArabicStrings.avatarUpdateFailure, isError: true);
        return;
      }

      final updatedUser = updatedResponse.data!;
      setState(() {
        _user = updatedUser;
      });

      _authBloc?.add(AuthUserUpdated(user: updatedUser));

      if (!mounted) return;
      _showSnackBar(ArabicStrings.avatarUpdateSuccess);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('${ArabicStrings.avatarUpdateFailure}: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAvatar = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(ArabicStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final authBloc = BlocProvider.of<AuthBloc>(context);
              authBloc.add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _buildAvatar(user),
                  ),
                  const SizedBox(height: 24),
                  _buildReadOnlyField(label: ArabicStrings.usernameLabel, value: user.username, icon: Icons.person),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      label: ArabicStrings.phoneNumberLabel, value: user.phoneNumber, icon: Icons.phone),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: ArabicStrings.displayNameLabel,
                    value: user.displayName?.isNotEmpty == true ? user.displayName! : '-',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      label: ArabicStrings.createdAtLabel,
                      value: _formatDate(user.createdAt),
                      icon: Icons.calendar_today),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: ArabicStrings.lastSeenLabel,
                    value: user.lastSeen != null ? _formatDate(user.lastSeen!) : '-',
                    icon: Icons.visibility,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
                    icon: _isUpdatingAvatar
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isUpdatingAvatar ? ArabicStrings.loading : ArabicStrings.updateAvatar),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar(User user) {
    final avatarPath = user.avatarPath;
    const double size = 120;

    Widget avatarContent;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final imageUrl = _fileService.getStreamUrl(avatarPath);
      avatarContent = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircleAvatar(radius: 60, child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => _buildInitialsAvatar(user, size),
        ),
      );
    } else {
      avatarContent = _buildInitialsAvatar(user, size);
    }

    return Column(
      children: [
        SizedBox(width: size, height: size, child: avatarContent),
        const SizedBox(height: 12),
        Text(
          avatarPath == null || avatarPath.isEmpty ? ArabicStrings.avatarNoImage : ArabicStrings.avatarSelectImage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(User user, double size) {
    return GestureDetector(
      onTap: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          user.initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          initialValue: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
              icon: const Icon(Icons.copy),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    twoDigits(int value) => value.toString().padLeft(2, '0');
    final datePart = '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
    final timePart = '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    return '$datePart $timePart';
  }
}
