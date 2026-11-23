import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../core/services/storage_service.dart';
import 'invite_access.dart';

/// Protect the entire navigator, including deep links, before mounting it.
class InviteGate extends StatefulWidget {
  final StorageService storage;
  final Widget child;
  const InviteGate({super.key, required this.storage, required this.child});

  @override
  State<InviteGate> createState() => _InviteGateState();
}

class _InviteGateState extends State<InviteGate> {
  final _code = TextEditingController();
  late bool _activated;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activated = InviteAccess.isActivated(widget.storage);
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final accepted = await InviteAccess.activate(widget.storage, _code.text);
      if (!mounted) return;
      setState(() {
        _activated = accepted;
        _saving = false;
        if (!accepted) _error = 'Mã mời không đúng. Vui lòng kiểm tra lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không lưu được mã mời. Vui lòng thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activated) return widget.child;
    return Overlay.wrap(
      child: AppPage(
        children: [
          const SizedBox(height: 56),
          const Icon(Icons.spa_outlined, size: 64, color: AppColors.coral),
          const SizedBox(height: 20),
          Text('Xì ke bắc âu', style: serif(32), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          DashedBorderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nhập mã mời', style: serif(26)),
                const SizedBox(height: 12),
                Text(
                  'Nhập mã được cấp để sử dụng ứng dụng. Bạn chỉ cần nhập một lần trên thiết bị này.',
                  style: body(16),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('invite-code'),
                  controller: _code,
                  enabled: !_saving,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mã mời',
                    errorText: _error,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('invite-submit'),
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Đang lưu…' : 'Vào ứng dụng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
