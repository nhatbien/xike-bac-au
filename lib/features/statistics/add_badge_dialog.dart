import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/session_repository.dart';
import '../../data/models/custom_badge.dart';
import '../../app/widgets/achievement_badge.dart';
import '../../data/repositories/statistics_repository.dart';

class AddBadgeDialog extends StatefulWidget {
  final SessionRepository repository;
  const AddBadgeDialog({super.key, required this.repository});

  @override
  State<AddBadgeDialog> createState() => _AddBadgeDialogState();
}

class _AddBadgeDialogState extends State<AddBadgeDialog> {
  final _form = GlobalKey<FormState>();
  BadgeMetric _metric = BadgeMetric.hold;
  final _target = TextEditingController(text: '60');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addBadge(
        _metric,
        _metric.toStoredTarget(int.parse(_target.text)),
      );
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
              DropdownButtonFormField<BadgeMetric>(
                initialValue: _metric,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Loại huy hiệu'),
                items: BadgeMetric.values
                    .map(
                      (metric) => DropdownMenuItem(
                        value: metric,
                        child: Text(metric.label),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (metric) {
                        if (metric == null) return;
                        setState(() {
                          _metric = metric;
                          _target.text = '${metric.defaultTarget}';
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _target,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Mục tiêu (${_metric.unit})',
                ),
                validator: (value) {
                  final target = int.tryParse(value ?? '');
                  return target == null || target < 1 || target > 9999
                      ? 'Nhập mục tiêu từ 1 đến 9999.'
                      : null;
                },
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              if (int.tryParse(_target.text) case final int value
                  when value > 0 && value <= 9999)
                AchievementBadge(
                  StatisticsRepository(widget.repository.sessions)
                      .achievementFor(
                        _metric.key,
                        _metric.title(_metric.toStoredTarget(value)),
                        _metric.toStoredTarget(value),
                      ),
                ),
              const SizedBox(height: 12),
              const Text('Tiến độ tự cập nhật theo lịch sử tập của bạn.'),
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
