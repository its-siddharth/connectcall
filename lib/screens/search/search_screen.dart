import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';
import '../../services/calling_service.dart';
import '../../widgets/user_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    context.read<UsersProvider>().clearSearch();
    super.dispose();
  }

  void _onSearch(String query) {
    final auth = context.read<AuthProvider>();
    context.read<UsersProvider>().search(
      query,
      excludeId: auth.currentUser?.id,
    );
  }

  void _startCall(
    BuildContext context,
    UserModel callee,
    CallType type,
  ) {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;
    final calling = context.read<CallingService>();
    final call = calling.initiateCall(caller: currentUser, callee: callee, type: type);
    if (type == CallType.audio) {
      Navigator.of(context).pushNamed('/audio-call', arguments: {
        'call': call,
        'currentUser': currentUser,
        'remoteUser': callee,
      });
    } else {
      Navigator.of(context).pushNamed('/video-call', arguments: {
        'call': call,
        'currentUser': currentUser,
        'remoteUser': callee,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();
    final results = usersProvider.searchResults;
    final query = usersProvider.searchQuery;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search people...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: query.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: AppColors.lightTextMuted),
                  SizedBox(height: 12),
                  Text(
                    'Search for people',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_search,
                        size: 64,
                        color: AppColors.lightTextMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "$query"',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 80),
                  itemBuilder: (ctx, i) {
                    final user = results[i];
                    return UserTile(
                      user: user,
                      onAudioCall: () => _startCall(ctx, user, CallType.audio),
                      onVideoCall: () => _startCall(ctx, user, CallType.video),
                      onTap: () => Navigator.of(ctx).pushNamed(
                        '/user-profile',
                        arguments: user,
                      ),
                    );
                  },
                ),
    );
  }
}
