import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/calling_service.dart';
import '../../models/user_model.dart';
import '../../models/call_model.dart';
import '../../widgets/user_tile.dart';
import '../../widgets/user_avatar.dart';
import '../call/incoming_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<UsersProvider>().loadUsers(excludeId: auth.currentUser?.id);
    });
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final calling = context.watch<CallingService>();

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: const [
              _HomeTab(),
              _ContactsTab(),
              _CallsTab(),
              _ProfileTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.contacts_outlined),
                activeIcon: Icon(Icons.contacts),
                label: 'Contacts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.call_outlined),
                activeIcon: Icon(Icons.call),
                label: 'Calls',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        // Incoming call overlay
        if (calling.hasIncomingCall && calling.incomingCall != null)
          IncomingCallScreen(call: calling.incomingCall!),
      ],
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = context.watch<UsersProvider>();
    final calling = context.read<CallingService>();
    final currentUser = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ConnectCall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => users.loadUsers(excludeId: currentUser?.id),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _WelcomeCard(user: currentUser),
              ),
            ),
            if (users.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (users.error != null)
              SliverToBoxAdapter(child: _ErrorState(message: users.error!))
            else if (users.users.isEmpty)
              const SliverToBoxAdapter(child: _EmptyContacts())
            else ...[
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recent Contacts',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final user = users.users[i];
                    return UserTile(
                      user: user,
                      onAudioCall: () => _startCall(ctx, currentUser!, user, CallType.audio, calling),
                      onVideoCall: () => _startCall(ctx, currentUser!, user, CallType.video, calling),
                      onTap: () => Navigator.of(ctx).pushNamed(
                        '/user-profile',
                        arguments: user,
                      ),
                    );
                  },
                  childCount: users.users.length > 5 ? 5 : users.users.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startCall(
    BuildContext context,
    UserModel caller,
    UserModel callee,
    CallType type,
    CallingService calling,
  ) {
    final call = calling.initiateCall(
      caller: caller,
      callee: callee,
      type: type,
    );
    if (type == CallType.audio) {
      Navigator.of(context).pushNamed('/audio-call', arguments: {
        'call': call,
        'currentUser': caller,
        'remoteUser': callee,
      });
    } else {
      Navigator.of(context).pushNamed('/video-call', arguments: {
        'call': call,
        'currentUser': caller,
        'remoteUser': callee,
      });
    }
  }
}

class _WelcomeCard extends StatelessWidget {
  final UserModel? user;
  const _WelcomeCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          UserAvatar(user: user, size: 52, showStatus: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name.split(' ').first ?? 'User'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready to connect?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.lightTextMuted),
          SizedBox(height: 12),
          Text(
            'No contacts yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Contacts will appear here once they join',
            style: TextStyle(color: AppColors.lightTextMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Contacts Tab ─────────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  const _ContactsTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final users = context.watch<UsersProvider>();
    final calling = context.read<CallingService>();
    final currentUser = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
        ],
      ),
      body: users.isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.error != null
              ? _ErrorState(message: users.error!)
              : users.users.isEmpty
                  ? const _EmptyContacts()
                  : ListView.separated(
                      itemCount: users.users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
                      itemBuilder: (ctx, i) {
                        final user = users.users[i];
                        return UserTile(
                          user: user,
                          onAudioCall: () => _startCall(ctx, currentUser!, user, CallType.audio, calling),
                          onVideoCall: () => _startCall(ctx, currentUser!, user, CallType.video, calling),
                          onTap: () => Navigator.of(ctx).pushNamed(
                            '/user-profile',
                            arguments: user,
                          ),
                        );
                      },
                    ),
    );
  }

  void _startCall(
    BuildContext context,
    UserModel caller,
    UserModel callee,
    CallType type,
    CallingService calling,
  ) {
    final call = calling.initiateCall(caller: caller, callee: callee, type: type);
    if (type == CallType.audio) {
      Navigator.of(context).pushNamed('/audio-call', arguments: {
        'call': call,
        'currentUser': caller,
        'remoteUser': callee,
      });
    } else {
      Navigator.of(context).pushNamed('/video-call', arguments: {
        'call': call,
        'currentUser': caller,
        'remoteUser': callee,
      });
    }
  }
}

// ── Calls Tab ─────────────────────────────────────────────────────────────────

class _CallsTab extends StatefulWidget {
  const _CallsTab();

  @override
  State<_CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<_CallsTab> {
  @override
  Widget build(BuildContext context) {
    final calling = context.watch<CallingService>();
    final history = calling.getCallHistory();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear call history?'),
                    content: const Text('This will remove all call records.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await calling.clearCallHistory();
                  setState(() {});
                }
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call_outlined, size: 64, color: AppColors.lightTextMuted),
                  SizedBox(height: 12),
                  Text(
                    'No call history',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your call history will appear here',
                    style: TextStyle(color: AppColors.lightTextMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 74),
              itemBuilder: (ctx, i) {
                final call = history[i];
                return CallHistoryTile(
                  call: call,
                  onCallBack: currentUser != null
                      ? () {
                          final remoteId = call.direction == CallDirection.incoming
                              ? call.callerId
                              : call.calleeId;
                          final remoteName = call.direction == CallDirection.incoming
                              ? call.callerName
                              : call.calleeName;
                          final remoteUser = UserModel(
                            id: remoteId,
                            name: remoteName,
                            email: '',
                            createdAt: DateTime.now(),
                          );
                          final newCall = calling.initiateCall(
                            caller: currentUser,
                            callee: remoteUser,
                            type: call.type,
                          );
                          if (call.type == CallType.audio) {
                            Navigator.of(ctx).pushNamed('/audio-call', arguments: {
                              'call': newCall,
                              'currentUser': currentUser,
                              'remoteUser': remoteUser,
                            });
                          } else {
                            Navigator.of(ctx).pushNamed('/video-call', arguments: {
                              'call': newCall,
                              'currentUser': currentUser,
                              'remoteUser': remoteUser,
                            });
                          }
                        }
                      : null,
                );
              },
            ),
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: UserAvatar(user: user, size: 88, showStatus: true),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.online.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  color: AppColors.online,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Actions
            _ProfileAction(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
            ),
            const Divider(height: 1, indent: 64),
            _ProfileAction(
              icon: Icons.dark_mode_outlined,
              label: 'Toggle Dark Mode',
              onTap: () => context.read<ThemeProvider>().toggleTheme(),
            ),
            const Divider(height: 1, indent: 64),
            _ProfileAction(
              icon: Icons.logout,
              label: 'Logout',
              color: AppColors.error,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout?'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
