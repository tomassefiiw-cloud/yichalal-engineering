import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import '../booking_create_screen.dart';

class DiagnoseTab extends StatefulWidget {
  const DiagnoseTab({super.key});
  @override
  State<DiagnoseTab> createState() => _DiagnoseTabState();
}

class _Msg {
  final bool fromUser;
  final String text;
  final bool loading;
  _Msg({required this.fromUser, required this.text, this.loading = false});
}

class _DiagnoseTabState extends State<DiagnoseTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _chat = [
    _Msg(fromUser: false, text: 'Hello! Describe what your car is doing — engine light? overheating? strange noise? You can type in English, አማርኛ, or Afaan Oromoo.'),
  ];
  Vehicle? _vehicle;
  List<Vehicle> _vehicles = [];
  String? _lastAiText;
  bool _busy = false;

  @override
  void initState() { super.initState(); _loadVehicles(); }

  Future<void> _loadVehicles() async {
    final user = context.read<Auth>().currentUser!;
    final list = await Repo.instance.vehiclesOf(user.id);
    if (!mounted) return;
    setState(() {
      _vehicles = list;
      _vehicle = list.isNotEmpty ? list.first : null;
    });
  }

  Future<void> _send([String? prefilled]) async {
    final text = (prefilled ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      _chat.add(_Msg(fromUser: true, text: text));
      _chat.add(_Msg(fromUser: false, text: '', loading: true));
      _busy = true;
    });
    _scrollDown();

    try {
      await for (final chunk in AiDiagnosis.diagnoseStream(text)) {
        if (!mounted) return;
        setState(() {
          _chat.removeLast();
          _chat.add(_Msg(fromUser: false, text: chunk));
          _lastAiText = chunk;
        });
        _scrollDown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chat.removeLast();
          _chat.add(_Msg(fromUser: false, text: 'Sorry — diagnosis failed. Try again.'));
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      if (_vehicle != null && _lastAiText != null) {
        final sev = _extract(_lastAiText!, 'Severity').toLowerCase();
        final repair = _extract(_lastAiText!, 'Estimated repair');
        final costLine = _extract(_lastAiText!, 'Estimated cost');
        final nums = RegExp(r'(\d{2,6})').allMatches(costLine).map((m) => double.parse(m.group(0)!)).toList();
        final cause = _extract(_lastAiText!, 'Probable cause');
        try {
          await Repo.instance.addDiagnosis(_vehicle!.id, text, cause, sev.isEmpty ? 'medium' : sev,
            repair, nums.isNotEmpty ? nums.first : 0, nums.length > 1 ? nums[1] : (nums.isNotEmpty ? nums.first * 2 : 0));
        } catch (_) {}
      }
    }
  }

  String _extract(String src, String label) {
    final r = RegExp('$label\\s*:\\s*(.+)', caseSensitive: false);
    final m = r.firstMatch(src);
    return m?.group(1)?.split('\n').first.trim() ?? '';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (_vehicles.isNotEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Row(children: [
          const Icon(Icons.directions_car_outlined, color: AppColors.orangeDark),
          const SizedBox(width: 8),
          Expanded(child: DropdownButton<Vehicle>(
            value: _vehicle, isExpanded: true, underline: const SizedBox(),
            items: _vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v.title))).toList(),
            onChanged: (v) => setState(() => _vehicle = v),
          )),
        ])),
      Expanded(child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _chat.length,
        itemBuilder: (_, i) => _bubble(_chat[i]),
      )),
      SizedBox(height: 40, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: AiDiagnosis.quickSymptoms.map((q) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ActionChip(label: Text(q, style: const TextStyle(fontSize: 12)), onPressed: _busy ? null : () => _send(q)),
        )).toList(),
      )),
      if (_lastAiText != null && !_busy)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingCreateScreen(
            vehicleId: _vehicle?.id, initial: ServiceType.workshop, prefillDescription: 'AI Diagnosis:\n$_lastAiText'))),
          icon: const Icon(Icons.event_note_rounded), label: const Text('Book Service with this diagnosis'),
        ))),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 10), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: TextField(
          controller: _input, maxLines: 5, minLines: 1, keyboardType: TextInputType.multiline, textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(hintText: 'Describe a symptom…', prefixIcon: Icon(Icons.psychology_alt_outlined)),
        )),
        const SizedBox(width: 8),
        SizedBox(width: 48, height: 48, child: ElevatedButton(
          onPressed: _busy ? null : () => _send(),
          style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
          child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
        )),
      ]))),
    ]);
  }

  Widget _bubble(_Msg m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (m.loading) {
      return Align(alignment: Alignment.centerLeft, child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.orangeLight,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppColors.darkBorder) : null,
        ),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.orange : AppColors.orangeDark)),
      ));
    }
    // Explicit colors so AI response text stays readable in BOTH themes.
    final bubbleColor = m.fromUser
        ? AppColors.orange
        : (isDark ? AppColors.darkCard : AppColors.orangeLight);
    final textColor = m.fromUser
        ? Colors.white
        : (isDark ? AppColors.darkText : AppColors.text);
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(m.fromUser ? 18 : 4),
            bottomRight: Radius.circular(m.fromUser ? 4 : 18),
          ),
          border: (isDark && !m.fromUser) ? Border.all(color: AppColors.darkBorder) : null,
        ),
        child: SelectableText(
          m.text,
          style: TextStyle(color: textColor, fontSize: 14, height: 1.45, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
