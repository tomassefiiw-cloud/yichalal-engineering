import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _name, _email, _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<Auth>().currentUser!;
    _name = TextEditingController(text: u.fullName);
    _email = TextEditingController(text: u.email ?? '');
    _address = TextEditingController(text: u.address);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    final user = auth.currentUser!;
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.t('settings'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen(primary: AppColors.orange))),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Column(children: [
          const CircleAvatar(radius: 40, backgroundColor: AppColors.orangeLight,
              child: Icon(Icons.person, size: 38, color: AppColors.orangeDark)),
          const SizedBox(height: 10),
          Text(user.fullName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
          Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(20)),
            child: const Text('CUSTOMER', style: TextStyle(color: AppColors.orangeDark, fontWeight: FontWeight.w700, fontSize: 11))),
        ])),
        const SizedBox(height: 18),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: TextEditingController(text: user.phone), enabled: false,
            decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
        const SizedBox(height: 12),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _address, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _saving ? null : () async {
            setState(() => _saving = true);
            try {
              await Repo.instance.upsertUser(user.copyWith(
                  fullName: _name.text.trim(),
                  email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                  address: _address.text.trim()));
              await auth.refresh();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(s.t('save_changes')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(primary: AppColors.orange))),
          icon: const Icon(Icons.settings_outlined),
          label: Text('${s.t('settings')} — ${s.t('language')} & ${s.t('theme')}'),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () async {
            await auth.logout();
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          },
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: Text(s.t('logout'), style: const TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
        ),
      ]),
    );
  }
}
