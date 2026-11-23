import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import 'legal_content.dart';

class LegalView extends StatelessWidget {
  final String document;
  const LegalView(this.document, {super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: LegalContent.data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const AppPage(
          title: 'Thông tin ứng dụng',
          children: [
            Text('Không đọc được nội dung. Vui lòng mở lại ứng dụng.'),
          ],
        );
      }
      final data = snapshot.data;
      if (data == null) {
        return const AppPage(
          children: [Center(child: CircularProgressIndicator())],
        );
      }
      final page = data['pages'][document] as Map<String, dynamic>;
      return AppPage(
        title: page['title'] as String,
        children: [
          Text(
            'Xì ke bắc âu · MAX\nCập nhật: ${data['updated']}',
            style: body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          for (final section in page['sections'])
            DashedBorderCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(section['title'] as String, style: serif(20)),
                  const SizedBox(height: 8),
                  for (final paragraph in section['paragraphs'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SelectableText(
                        paragraph as String,
                        style: body(16),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
