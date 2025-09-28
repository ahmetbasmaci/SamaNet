import 'package:flutter/material.dart';
import '../../core/constants/arabic_strings.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/bloc_provider.dart';
import '../widgets/conversations_list.dart';

/// Main screen with conversations list
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ArabicStrings.chats),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search page
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
         
        ],
      ),
      body: const ConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/search');
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}
