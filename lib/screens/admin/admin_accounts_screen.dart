import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/account.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  List<Account>? _accounts;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accounts == null && _error == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      final accounts = await AdminService(ApiClient(auth)).fetchAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleStatus(Account account) async {
    try {
      final auth = AuthScope.of(context);
      await AdminService(ApiClient(auth)).updateAccountStatus(
        userId: account.id,
        isActive: !account.isActive,
      );
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            account.isActive
                ? 'Đã khóa ${account.username}'
                : 'Đã mở khóa ${account.username}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && (_accounts == null || _accounts!.isEmpty)) {
      return const AppLoadingIndicator(message: 'Đang tải tài khoản...');
    }

    if (_error != null && (_accounts == null || _accounts!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final accounts = _accounts ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Quản lý tài khoản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${accounts.length} tài khoản • PATCH /api/accounts/{{id}}/status',
            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Chưa có tài khoản nào.',
                  style: TextStyle(color: AppTheme.mediumGray),
                ),
              ),
            )
          else
            ...accounts.map(
              (account) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: account.isActive
                        ? AppTheme.primary
                        : AppTheme.mediumGray,
                    child: Text(
                      (account.username ?? '?').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppTheme.white),
                    ),
                  ),
                  title: Text(
                    account.username ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.email ?? '—'),
                      Text('Role: ${account.role ?? '—'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      account.isActive ? Icons.block : Icons.check_circle,
                      color: account.isActive ? AppTheme.error : AppTheme.success,
                    ),
                    tooltip: account.isActive ? 'Khóa tài khoản' : 'Mở khóa',
                    onPressed: () => _toggleStatus(account),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
