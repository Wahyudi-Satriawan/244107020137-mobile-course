import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_providers.dart';

/// Screen utama untuk fitur AI Campus Assistant.
/// Telah dioptimasi performanya dengan:
/// 1. Pemisahan widget tree ke class terpisah untuk memaksimalkan widget reuse.
/// 2. Penggunaan `ref.watch(provider.select(...))` untuk mencegah rebuild berlebih.
/// 3. Isolasi animasi paint dengan `RepaintBoundary` pada loading bubble.
/// 4. Penerapan `const` constructor di seluruh subtree statis.
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

  Future<void> _handleSend([String? customText]) async {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (customText == null) {
      _textController.clear();
    }
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
    // Listener untuk fallback dialog jika layanan AI sibuk / error
    ref.listen<String?>(
      chatNotifierProvider.select((s) => s.errorMessage),
      (previous, next) {
        if (next != null && next != previous) {
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
                '$next\n\nCoba lagi nanti atau gunakan mode offline.',
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
      },
    );

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
            child: _ChatMessagesView(
              scrollController: _scrollController,
              onSuggestionSelected: (prompt) => _handleSend(prompt),
            ),
          ),
          _ChatInputBar(
            controller: _textController,
            onSend: () => _handleSend(),
          ),
        ],
      ),
    );
  }
}

/// Widget terpisah untuk menampilkan daftar percakapan.
/// Menggunakan `select` untuk mendengarkan perubahan daftar pesan dan status loading.
class _ChatMessagesView extends ConsumerWidget {
  final ScrollController scrollController;
  final ValueChanged<String> onSuggestionSelected;

  const _ChatMessagesView({
    required this.scrollController,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatNotifierProvider.select((s) => s.messages));
    final isLoading = ref.watch(chatNotifierProvider.select((s) => s.isLoading));

    if (messages.isEmpty) {
      return EmptyChatView(onSuggestionSelected: onSuggestionSelected);
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isLoading ? 1 : 0),
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          return ChatBubbleItem(msg: msg);
        } else {
          // RepaintBoundary mengisolasi animasi indikator pemuatan
          return const RepaintBoundary(
            child: LoadingBubbleWidget(),
          );
        }
      },
    );
  }
}

/// Widget statis tampilan awal kosong saat belum ada pesan.
class EmptyChatView extends StatelessWidget {
  final ValueChanged<String> onSuggestionSelected;

  const EmptyChatView({super.key, required this.onSuggestionSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 56,
                color: colorScheme.primary,
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
                  onPressed: () =>
                      onSuggestionSelected('Jadwal kuliah hari ini?'),
                ),
                ActionChip(
                  label: const Text('Cara melihat pengumuman?'),
                  onPressed: () =>
                      onSuggestionSelected('Cara melihat pengumuman?'),
                ),
                ActionChip(
                  label: const Text('Tips belajar mobile dev'),
                  onPressed: () =>
                      onSuggestionSelected('Tips belajar mobile dev'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget item gelembung percakapan terisolasi.
class ChatBubbleItem extends StatelessWidget {
  final ChatMessage msg;

  const ChatBubbleItem({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
}

/// Widget indikator pemuatan respons asisten AI yang dibungkus RepaintBoundary.
class LoadingBubbleWidget extends StatelessWidget {
  const LoadingBubbleWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Widget input teks dan tombol kirim terpisah.
/// Hanya me-rebuild saat `isLoading` berubah berkat `ref.watch(provider.select(...))`.
class _ChatInputBar extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isolasi rebuild: hanya mendengarkan status isLoading
    final isLoading = ref.watch(chatNotifierProvider.select((s) => s.isLoading));

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
                controller: controller,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
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
              onPressed: isLoading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
