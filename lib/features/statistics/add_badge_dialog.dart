import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/session_repository.dart';

class AddBadgeDialog extends StatefulWidget {
  final SessionRepository repository;
  const AddBadgeDialog({super.key, required this.repository});

  @override
  State<AddBadgeDialog> createState() => _AddBadgeDialogState();
}

class _AddBadgeDialogState extends State<AddBadgeDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _points = TextEditingController(text: '10');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addBadge(_name.text, int.parse(_points.text));
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is FormatException
              ? error.message
              : 'Chưa lưu được huy hiệu. Bạn thử lại nhé.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Thêm huy hiệu'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                enabled: !_saving,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Tên huy hiệu'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên huy hiệu.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _points,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Điểm thưởng (1–9999)',
                ),
                validator: (value) {
                  final points = int.tryParse(value ?? '');
                  return points == null || points < 1 || points > 9999
                      ? 'Nhập số điểm từ 1 đến 9999.'
                      : null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              const Text('Điểm thưởng được cộng vào tổng điểm huy hiệu.'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu…' : 'Thêm'),
        ),
      ],
    ),
  );
}
