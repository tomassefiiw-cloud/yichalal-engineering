import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

class AuthScreen extends StatefulWidget {
  final UserRole role;
  const AuthScreen({super.key, required this.role});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.role == UserRole.customer;
    final primary = isCustomer ? AppColors.orange : AppColors.mintDark;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 24),
          GearLogo(size: 90, primary: primary, secondary: isCustomer ? AppColors.mint : AppColors.orange),
          const SizedBox(height: 8),
          Text(isCustomer ? 'Customer' : 'Mechanic',
              style: TextStyle(color: AppColors.textMute, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TabBar(
              controller: _tab,
              labelColor: primary, unselectedLabelColor: AppColors.textMute,
              indicatorColor: primary, indicatorWeight: 3,
              tabs: const [Tab(text: 'Sign in'), Tab(text: 'Sign up')],
            ),
          ),
          Expanded(child: TabBarView(controller: _tab, children: [
            _LoginForm(role: widget.role, primary: primary),
            _SignupForm(role: widget.role, primary: primary),
          ])),
        ]),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final UserRole role; final Color primary;
  const _LoginForm({required this.role, required this.primary});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _phone = TextEditingController(text: '+251');
  final _otp = TextEditingController();
  bool _sent = false, _busy = false;

  Future<void> _send() async {
    if (!_phone.text.startsWith('+251') || _phone.text.length < 12) {
      _toast('Enter valid +251 number'); return;
    }
    setState(() { _sent = true; _otp.text = '123456'; });
    _toast('Demo OTP 123456 auto-filled. Tap Verify.');
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final u = await context.read<Auth>().verifyOtpAndLogin(
        phone: _phone.text.trim(), code: _otp.text.trim(), expectedRole: widget.role);
      if (u == null && mounted) _toast('No account with this phone. Tap "Sign up" tab.');
      if (u != null) await Notify.watchUser(u.id);
    } catch (e) { if (mounted) _toast(e.toString()); }
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Sign in with your phone number to continue.', style: TextStyle(color: AppColors.textMute)),
        const SizedBox(height: 22),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_android))),
        if (_sent) ...[
          const SizedBox(height: 14),
          TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'OTP code', prefixIcon: Icon(Icons.lock_outline))),
          Text('Demo OTP 123456 (auto-filled)', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.primary, minimumSize: const Size.fromHeight(52)),
            onPressed: _busy ? null : _verify,
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify & Login'),
          ),
        ] else ...[
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.primary, minimumSize: const Size.fromHeight(52)),
            onPressed: _send,
            child: const Text('Send code'),
          ),
        ],
      ]),
    );
  }
}

class _SignupForm extends StatefulWidget {
  final UserRole role; final Color primary;
  const _SignupForm({required this.role, required this.primary});
  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _phone = TextEditingController(text: '+251');
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _specialties = TextEditingController(text: 'Engine, Electrical, Brakes');
  final _licenseId = TextEditingController();
  final _natId = TextEditingController();
  final Set<EngineType> _engines = {EngineType.gasoline};
  final _otp = TextEditingController();
  bool _agreed = false, _sent = false, _busy = false;

  bool get isMech => widget.role == UserRole.mechanic;

  Future<void> _send() async {
    if (_name.text.trim().isEmpty) return _toast('Enter your name');
    if (!_phone.text.startsWith('+251') || _phone.text.length < 12) return _toast('Phone must start with +251');
    if (isMech) {
      if (_licenseId.text.trim().isEmpty) return _toast('Trade License number required');
      if (_natId.text.trim().isEmpty) return _toast('National ID number required');
      if (_specialties.text.trim().isEmpty) return _toast('List at least one specialty');
      if (!_agreed) return _toast('Accept terms to continue');
    } else {
      if (!_agreed) return _toast('Accept terms to continue');
    }
    setState(() { _sent = true; _otp.text = '123456'; });
    _toast('Demo OTP 123456 auto-filled. Tap Create.');
  }

  Future<void> _finish() async {
    if (_otp.text.trim() != '123456') return _toast('Wrong OTP. Use 123456.');
    setState(() => _busy = true);
    try {
      final u = await context.read<Auth>().register(
        phone: _phone.text.trim(),
        fullName: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        address: _address.text.trim(),
        role: widget.role,
        engineTypes: _engines.toList(),
        specialties: isMech ? _specialties.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const [],
        tradeLicenseUrl: isMech ? 'LIC:${_licenseId.text.trim()}' : null,
        nationalIdUrl: isMech ? 'NID:${_natId.text.trim()}' : null,
      );
      await Notify.watchUser(u.id);
    } catch (e) { if (mounted) _toast(e.toString()); }
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Create your account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 22),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_android))),
        const SizedBox(height: 12),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address / landmark', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 16),
        const Text('Engine types I drive / service', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: EngineType.values.map((e) => FilterChip(
          label: Text(e.name.toUpperCase()),
          selected: _engines.contains(e),
          onSelected: (v) => setState(() => v ? _engines.add(e) : _engines.remove(e)),
        )).toList()),
        if (isMech) ...[
          const SizedBox(height: 20),
          const Text('Legal & verification (required)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(controller: _licenseId, decoration: const InputDecoration(labelText: 'Trade License #', prefixIcon: Icon(Icons.badge_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _natId, decoration: const InputDecoration(labelText: 'National ID #', prefixIcon: Icon(Icons.fingerprint))),
          const SizedBox(height: 12),
          TextField(controller: _specialties, decoration: const InputDecoration(labelText: 'Specialties (comma-separated)', prefixIcon: Icon(Icons.build_outlined))),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.orangeDark, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Your KYC verification status will be reviewed by Yichalal admin. You can start receiving jobs once verified.', style: TextStyle(fontSize: 12))),
            ])),
        ],
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: widget.primary,
          value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false),
          title: const Text('I accept the Terms of Service & Privacy Policy', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 8),
        if (_sent) ...[
          TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'OTP code', prefixIcon: Icon(Icons.lock_outline))),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.primary, minimumSize: const Size.fromHeight(52)),
            onPressed: _busy ? null : _finish,
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account'),
          ),
        ] else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.primary, minimumSize: const Size.fromHeight(52)),
            onPressed: _send,
            child: const Text('Continue'),
          ),
        const SizedBox(height: 30),
      ]),
    );
  }
}
