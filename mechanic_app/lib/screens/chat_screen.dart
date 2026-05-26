import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String peerId;
  const ChatScreen({super.key, required this.bookingId, required this.peerId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  AppUser? _peer;

  @override
  void initState() {
    super.initState();
    Repo.instance.findUserById(widget.peerId).then((u) => mounted ? setState(() => _peer = u) : null);
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    _input.clear();
    final me = context.read<Auth>().currentUser!;
    await Repo.instance.sendChat(widget.bookingId, me.id, t);
    if (_peer != null) await Repo.instance.notify(_peer!.id, 'New message', t.length > 50 ? '${t.substring(0, 50)}…' : t, bookingId: widget.bookingId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<Auth>().currentUser!;
    return Scaffold(
      appBar: AppBar(title: Text(_peer?.fullName ?? 'Chat')),
      body: Column(children: [
        Expanded(child: StreamBuilder<List<ChatMessage>>(
          stream: Repo.instance.chatStream(widget.bookingId),
          builder: (_, snap) {
            final list = snap.data ?? [];
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[i];
                final mine = m.senderId == me.id;
                return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: mine ? AppColors.orange : AppColors.orangeLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(mine ? 16 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 16),
                    ),
                  ),
                  child: SelectableText(m.text, style: TextStyle(color: mine ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.text, fontSize: 14, height: 1.35)),
                ));
              },
            );
          },
        )),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(
            controller: _input,
            maxLines: 5, minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            inputFormatters: const [],
            decoration: const InputDecoration(hintText: 'Message…'),
          )),
          const SizedBox(width: 6),
          SizedBox(width: 44, height: 44, child: ElevatedButton(
            onPressed: _send,
            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
            child: const Icon(Icons.send_rounded),
          )),
        ]))),
      ]),
    );
  }
}
