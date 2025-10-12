import 'package:flutter/material.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/user.dart';
import '../../data/services/user_service.dart';
import '../../data/services/local_storage_service.dart';
import 'messages_page.dart';
import '../widgets/user_avatar.dart';

/// Search page for finding users by username
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _usernameController = TextEditingController();
  late LocalStorageService _localStorage;
  late UserService _userService;

  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  User? _currentUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeServices();
    await _loadCurrentUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _localStorage = serviceLocator.get<LocalStorageService>();
    _userService = serviceLocator.get<UserService>();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Load cached user data instead of just user ID
      final cachedUser = await _localStorage.getCurrentUser();
      if (cachedUser != null) {
        setState(() {
          _currentUser = cachedUser;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _searchUsers() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _errorMessage = ArabicStrings.enterUsername;
      });
      return;
    }

    if (username.length < 4) {
      setState(() {
        _errorMessage = ArabicStrings.usernameMinLength4;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults.clear();
    });

    try {
      // Real API call
      final response = await _userService.searchUsersByUsername(username);

      if (response.isSuccess && response.data != null) {
        print(_currentUser!.name);
        // Filter out current user from results
        final filteredResults = response.data!.where((user) {
          return _currentUser == null || user.id != _currentUser!.id;
        }).toList();

        setState(() {
          _searchResults = filteredResults;
          _hasSearched = true;
          _isSearching = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? ArabicStrings.userNotFound;
          _hasSearched = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ArabicStrings.connectionError;
        _hasSearched = true;
        _isSearching = false;
      });
    }
  }

  void _startChat(User user) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => MessagesPage(chatUser: user)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.searchUsers), elevation: 0),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Fixed header section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search instruction
                  Text(
                    ArabicStrings.searchByUsername,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Username input
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: ArabicStrings.enterUsername,
                      hintText: 'ahmed_123',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: _errorMessage,
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchUsers(),
                    enabled: !_isSearching,
                  ),

                  const SizedBox(height: 16),

                  // Search button
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchUsers,
                    icon: _isSearching
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? ArabicStrings.loading : ArabicStrings.search),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search results header
                  if (_hasSearched)
                    Text(
                      ArabicStrings.searchResults,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  if (_hasSearched) const SizedBox(height: 12),
                ],
              ),
            ),

            // Expandable content section
            Expanded(
              child: _hasSearched
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSearchResults(theme),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'أدخل اسم المستخدم للبحث عن المستخدمين',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _hasSearched = false;
                });
              },
              child: const Text(ArabicStrings.search),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              ArabicStrings.noUsersFound,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'تأكد من اسم المستخدم وحاول مرة أخرى',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: UserAvatar(user: user, radius: 24),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.phoneNumber),
                Text(
                  user.isOnline ? ArabicStrings.online : ArabicStrings.offline,
                  style: TextStyle(
                    color: user.isOnline ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(onPressed: () => _startChat(user), child: const Text(ArabicStrings.startChat)),
          ),
        );
      },
    );
  }
}
