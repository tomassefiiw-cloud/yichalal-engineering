import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _name, _email, _address, _specialties;

  @override
  void initState() {
    super.initState();
    final u = context.read<Auth>().currentUser!;
    _name = TextEditingController(text: u.fullName);
    _email = TextEditingController(text: u.email ?? '');
    _address = TextEditingController(text: u.address);
    _specialties = TextEditingController(text: u.specialties.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    final user = auth.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Column(children: [
          CircleAvatar(radius: 40, backgroundColor: AppColors.mintDark.withOpacity(0.15), child: const Icon(Icons.handyman_rounded, size: 36, color: AppColors.mintDark)),
          const SizedBox(height: 10),
          Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.mintDark.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('MECHANIC', style: TextStyle(color: AppColors.mintDark, fontWeight: FontWeight.w700, fontSize: 11))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(user.kycVerified ? Icons.verified_rounded : Icons.warning_amber, size: 16, color: user.kycVerified ? AppColors.success : AppColors.warn),
            const SizedBox(width: 4),
            Text(user.kycVerified ? 'KYC verified' : 'KYC pending review', style: TextStyle(color: user.kycVerified ? AppColors.success : AppColors.warn, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ])),
        const SizedBox(height: 18),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: TextEditingController(text: user.phone), enabled: false, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
        const SizedBox(height: 12),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Workshop address', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _specialties, decoration: const InputDecoration(labelText: 'Specialties (comma-separated)', prefixIcon: Icon(Icons.build_outlined))),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await Repo.instance.upsertUser(user.copyWith(
              fullName: _name.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              address: _address.text.trim(),
              specialties: _specialties.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
            ));
            await auth.refresh();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
          },
          icon: const Icon(Icons.save_outlined), label: const Text('Save changes'),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () async {
            await auth.logout();
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          },
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
        ),
      ]),
    );
  }
}
