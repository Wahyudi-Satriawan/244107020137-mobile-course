import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    _scrollToBottom();

    await ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey =
        await ref.read(chatNotifierProvider.notifier).getApiKey() ?? '';
    if (!mounted) return;

    final controller = TextEditingController(text: currentKey);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Key disimpan dengan aman di flutter_secure_storage dan tidak pernah di-hardcode.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(chatNotifierProvider.notifier)
                  .saveApiKey(controller.text);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API Key berhasil disimpan dengan aman.'),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback error listener using AlertDialog
    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Layanan AI Sibuk'),
              ],
            ),
            content: Text(
              '${next.errorMessage}\n\nCoba lagi nanti atau gunakan mode offline.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(chatNotifierProvider.notifier).clearError();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    });

    final chatState = ref.watch(chatNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined),
            SizedBox(width: 8),
            Text('Campus AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Atur API Key',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount:
                        chatState.messages.length +
                        (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatState.messages.length) {
                        final msg = chatState.messages[index];
                        return _buildChatBubble(msg);
                      } else {
                        return _buildLoadingBubble();
                      }
                    },
                  ),
          ),
          _buildInputBar(chatState.isLoading),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Halo Mahasiswa!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saya asisten kampus Campus Notify siap membantu menjawab pertanyaan seputar kampus secara singkat dan ramah.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Jadwal kuliah hari ini?'),
                  onPressed: () {
                    _textController.text = 'Jadwal kuliah hari ini?';
                    _handleSend();
                  },
                ),
                ActionChip(
                  label: const Text('Cara melihat pengumuman?'),
                  onPressed: () {
                    _textController.text = 'Cara melihat pengumuman?';
                    _handleSend();
                  },
                ),
                ActionChip(
                  label: const Text('Tips belajar mobile dev'),
                  onPressed: () {
                    _textController.text = 'Tips belajar mobile dev';
                    _handleSend();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser
                      ? const Radius.circular(14)
                      : const Radius.circular(2),
                  bottomRight: isUser
                      ? const Radius.circular(2)
                      : const Radius.circular(14),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Asisten sedang mengetik...',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isLoading) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan untuk asisten kampus...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              onPressed: isLoading ? null : _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}
