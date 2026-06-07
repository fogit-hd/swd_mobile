import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/create_account_models.dart';
import '../../services/account_service.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/scale_tap.dart';

class ModeratorCreateAccountScreen extends StatefulWidget {
  const ModeratorCreateAccountScreen({super.key});

  @override
  State<ModeratorCreateAccountScreen> createState() =>
      _ModeratorCreateAccountScreenState();
}

class _ModeratorCreateAccountScreenState
    extends State<ModeratorCreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountService = AccountService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Student / Lecturer / EvaluationPanel
  final _fullNameController = TextEditingController();
  // Student
  final _studentCodeController = TextEditingController();
  final _batchController = TextEditingController();
  final _majorController = TextEditingController();
  final _groupIdController = TextEditingController();
  // Lecturer / EvaluationPanel
  final _departmentController = TextEditingController();
  // Lecturer
  final _maxGroupsController = TextEditingController(text: '5');
  // TrainingDepartment
  final _departmentNameController = TextEditingController();
  final _staffCodeController = TextEditingController();
  final _positionController = TextEditingController();
  // SystemAdministrator
  final _adminLevelController = TextEditingController();
  final _permissionScopeController = TextEditingController();

  SystemUserRole _role = SystemUserRole.student;
  int _formVersion = 0;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _studentCodeController.dispose();
    _batchController.dispose();
    _majorController.dispose();
    _groupIdController.dispose();
    _departmentController.dispose();
    _maxGroupsController.dispose();
    _departmentNameController.dispose();
    _staffCodeController.dispose();
    _positionController.dispose();
    _adminLevelController.dispose();
    _permissionScopeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _accountService.createUser(_buildRequest());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tạo tài khoản ${_role.labelVi} (${_usernameController.text.trim()}).',
          ),
        ),
      );
      _resetForm();
    } on AccountException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Không tạo được tài khoản. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  CreateUserRequest _buildRequest() {
    final profile = switch (_role) {
      SystemUserRole.student => StudentProfile(
          fullName: _fullNameController.text.trim(),
          studentCode: _studentCodeController.text.trim(),
          batch: _batchController.text.trim(),
          major: _majorController.text.trim(),
          groupId: _parseOptionalInt(_groupIdController.text),
        ),
      SystemUserRole.lecturer => LecturerProfile(
          fullName: _fullNameController.text.trim(),
          department: _departmentController.text.trim(),
          maxGroups: int.parse(_maxGroupsController.text.trim()),
        ),
      SystemUserRole.evaluationPanel => EvaluationPanelProfile(
          fullName: _fullNameController.text.trim(),
          department: _departmentController.text.trim(),
        ),
      SystemUserRole.trainingDepartment => TrainingDepartmentProfile(
          departmentName: _departmentNameController.text.trim(),
          staffCode: _staffCodeController.text.trim(),
          position: _positionController.text.trim(),
        ),
      SystemUserRole.systemAdministrator => SystemAdministratorProfile(
          adminLevel: _adminLevelController.text.trim(),
          permissionScope: _permissionScopeController.text.trim(),
        ),
    };

    return CreateUserRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      profile: profile,
    );
  }

  int? _parseOptionalInt(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _fullNameController.clear();
    _studentCodeController.clear();
    _batchController.clear();
    _majorController.clear();
    _groupIdController.clear();
    _departmentController.clear();
    _maxGroupsController.text = '5';
    _departmentNameController.clear();
    _staffCodeController.clear();
    _positionController.clear();
    _adminLevelController.clear();
    _permissionScopeController.clear();
    setState(() {
      _role = SystemUserRole.student;
      _formVersion++;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: const Text(
                'Tạo User và hồ sơ theo role hệ thống (bảng User + bảng role tương ứng).',
                style: TextStyle(color: AppTheme.mediumGray, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<SystemUserRole>(
              key: ValueKey('role-$_formVersion'),
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role (User.Role)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: SystemUserRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text('${r.labelVi} (${r.apiValue})'),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (v) {
                      if (v != null) setState(() => _role = v);
                    },
            ),
            const SizedBox(height: 24),
            _sectionTitle('User'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().length < 3 ? 'Tối thiểu 3 ký tự' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Tối thiểu 6 ký tự' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) {
                if (v != _passwordController.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: AppAnimations.normal,
              switchInCurve: AppAnimations.curve,
              switchOutCurve: AppAnimations.curveIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(_role),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(_profileSectionTitle),
                  const SizedBox(height: 12),
                  ..._roleProfileFields(),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ScaleTap(
              onTap: _loading ? null : _submit,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: AnimatedSwitcher(
                  duration: AppAnimations.fast,
                  child: _loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ),
                        )
                      : const Text(
                          key: ValueKey('label'),
                          'Tạo tài khoản',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _profileSectionTitle => switch (_role) {
        SystemUserRole.student => 'Student',
        SystemUserRole.lecturer => 'Lecturer',
        SystemUserRole.evaluationPanel => 'EvaluationPanel',
        SystemUserRole.trainingDepartment => 'TrainingDepartment',
        SystemUserRole.systemAdministrator => 'SystemAdministrator',
      };

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.primary,
      ),
    );
  }

  List<Widget> _roleProfileFields() {
    return switch (_role) {
      SystemUserRole.student => [
          _fullNameField(required: true),
          _textField(
            controller: _studentCodeController,
            label: 'StudentCode',
            icon: Icons.numbers_outlined,
            required: true,
          ),
          _textField(
            controller: _batchController,
            label: 'Batch',
            icon: Icons.calendar_today_outlined,
            required: true,
          ),
          _textField(
            controller: _majorController,
            label: 'Major',
            icon: Icons.menu_book_outlined,
            required: true,
          ),
          _textField(
            controller: _groupIdController,
            label: 'GroupID (tuỳ chọn)',
            icon: Icons.group_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (int.tryParse(v.trim()) == null) return 'Nhập số nguyên';
              return null;
            },
          ),
        ],
      SystemUserRole.lecturer => [
          _fullNameField(required: true),
          _textField(
            controller: _departmentController,
            label: 'Department',
            icon: Icons.business_outlined,
            required: true,
          ),
          _textField(
            controller: _maxGroupsController,
            label: 'MaxGroups',
            icon: Icons.groups_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            required: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập MaxGroups';
              final n = int.tryParse(v.trim());
              if (n == null || n < 0) return 'Số nguyên ≥ 0';
              return null;
            },
          ),
        ],
      SystemUserRole.evaluationPanel => [
          _fullNameField(required: true),
          _textField(
            controller: _departmentController,
            label: 'Department',
            icon: Icons.business_outlined,
            required: true,
          ),
          const Text(
            'Tài khoản EvaluationPanel có thể đăng nhập app với role Panel.',
            style: TextStyle(color: AppTheme.mediumGray, fontSize: 12),
          ),
        ],
      SystemUserRole.trainingDepartment => [
          _textField(
            controller: _departmentNameController,
            label: 'DepartmentName',
            icon: Icons.apartment_outlined,
            required: true,
          ),
          _textField(
            controller: _staffCodeController,
            label: 'StaffCode',
            icon: Icons.badge_outlined,
            required: true,
          ),
          _textField(
            controller: _positionController,
            label: 'Position',
            icon: Icons.work_outline,
            required: true,
          ),
        ],
      SystemUserRole.systemAdministrator => [
          _textField(
            controller: _adminLevelController,
            label: 'AdminLevel',
            icon: Icons.shield_outlined,
            required: true,
          ),
          _textField(
            controller: _permissionScopeController,
            label: 'PermissionScope',
            icon: Icons.admin_panel_settings_outlined,
            required: true,
          ),
        ],
    };
  }

  Widget _fullNameField({required bool required}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _textField(
        controller: _fullNameController,
        label: 'FullName',
        icon: Icons.person_outline,
        required: required,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        validator: validator ??
            (required
                ? (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null
                : null),
      ),
    );
  }
}
