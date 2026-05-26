import 'package:flutter/material.dart';
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
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    Repo.instance.findUserById(widget.peerId).then((u) {
      if (mounted) setState(() => _peer = u);
    });
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    _input.clear();
    final me = context.read<Auth>().currentUser!;
    try {
      await Repo.instance.sendChat(widget.bookingId, me.id, t);
      if (_peer != null) {
        await Repo.instance.notify(_peer!.id, 'New message from ${me.fullName}',
            t.length > 60 ? '${t.substring(0, 60)}…' : t, bookingId: widget.bookingId);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
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
            // Force ascending order client-side so newest is always at bottom,
            // regardless of how Supabase orders the stream rows.
            final list = List<ChatMessage>.from(snap.data ?? [])
              ..sort((a, b) => a.ts.compareTo(b.ts));
            if (list.length != _lastCount) {
              _lastCount = list.length;
              _scrollToBottom();
            }
            if (list.isEmpty) {
              return const Center(child: Text('Say hello 👋',
                  style: TextStyle(color: AppColors.textMute)));
            }
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[i];
                final mine = m.senderId == me.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        color: mine ? AppColors.orange : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.orangeLight),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(mine ? 16 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 16),
                        ),
                      ),
                      child: SelectableText(
                        m.text,
                        style: TextStyle(
                          color: mine
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text),
                          fontSize: 14, height: 1.35,
                        ),
                      ),
                    ),
                  ),
                );
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
