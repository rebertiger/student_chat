import 'package:flutter/material.dart';
import '../cubit/chat_cubit.dart';

class ReportBottomSheet extends StatefulWidget {
  final int messageId;
  final String? messageText;
  final String? senderName;
  final ChatCubit chatCubit;

  const ReportBottomSheet({
    Key? key,
    required this.messageId,
    required this.chatCubit,
    this.messageText,
    this.senderName,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required int messageId,
    required ChatCubit chatCubit,
    String? messageText,
    String? senderName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReportBottomSheet(
        messageId: messageId,
        chatCubit: chatCubit,
        messageText: messageText,
        senderName: senderName,
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _predefinedReasons = [
    'Inappropriate content',
    'Harassment',
    'Spam',
    'Off-topic',
    'Offensive language',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_selectedReason == null && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for reporting')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Get the final reason (custom or selected)
    final String reason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : _selectedReason ?? '';

    // Use the passed chatCubit instead of trying to get it from context
    widget.chatCubit
        .reportMessage(
      messageId: widget.messageId,
      reason: reason,
    )
        .then((_) {
      // Show success message and close the bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message reported successfully')),
      );
      Navigator.of(context).pop();
    }).catchError((error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report message: $error')),
      );
      setState(() {
        _isSubmitting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Report Message',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Message Preview
          if (widget.messageText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.senderName != null)
                    Text(
                      widget.senderName!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    widget.messageText!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Predefined reasons
          const Text(
            'Select a reason:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _predefinedReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(reason),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedReason = selected ? reason : null;
                    // If "Other" is selected, keep the text field enabled
                    if (reason != 'Other' && selected) {
                      _reasonController.clear();
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom reason input
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Other reason (optional)',
              border: OutlineInputBorder(),
              hintText: 'Provide details if needed',
            ),
            maxLines: 3,
            onChanged: (value) {
              if (value.trim().isNotEmpty && _selectedReason != 'Other') {
                setState(() {
                  _selectedReason = 'Other';
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Submit button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Report'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
