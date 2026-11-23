import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import 'logs_controller.dart';

class LogsView extends GetView<LogsController> {
  const LogsView({super.key});
  @override
  Widget build(BuildContext context) => Obx(
    () => AppPage(
      title: 'Nhật ký',
      children: [
        Text(
          'Có lỗi thì chụp màn này hoặc bấm “Gửi nhật ký” rồi gửi lại.',
          style: body(13.5, color: AppColors.muted),
        ),
        DashedBorderCard(
          radius: 14,
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            controller.text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
        ),
        Builder(
          builder: (buttonContext) => RoundedOutlineButton(
            'Gửi nhật ký',
            onPressed: () {
              final box = buttonContext.findRenderObject() as RenderBox?;
              controller.share(
                origin: box == null
                    ? null
                    : box.localToGlobal(Offset.zero) & box.size,
              );
            },
          ),
        ),
      ],
    ),
  );
}
