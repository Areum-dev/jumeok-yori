import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

/// 정보 오류 신고 다이얼로그
class ReportDialog extends StatefulWidget {
  final String? menuItemId;
  final String? starterMenuId;
  final String? restaurantId;
  final String? recommendationType;
  final String? userId;
  final String? anonymousUserId;

  const ReportDialog({
    super.key,
    this.menuItemId,
    this.starterMenuId,
    this.restaurantId,
    this.recommendationType,
    this.userId,
    this.anonymousUserId,
  });

  static Future<void> show(
    BuildContext context, {
    String? menuItemId,
    String? starterMenuId,
    String? restaurantId,
    String? recommendationType,
    String? userId,
    String? anonymousUserId,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReportDialog(
        menuItemId: menuItemId,
        starterMenuId: starterMenuId,
        restaurantId: restaurantId,
        recommendationType: recommendationType,
        userId: userId,
        anonymousUserId: anonymousUserId,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selected;
  bool _submitting = false;

  final _reasons = ['가격이 달라요', '사진이 이상해요', '폐업/운영 안 함', '기타'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('정보 오류 신고'),
      content: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (v) => setState(() => _selected = v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reasons
              .map(
                (r) => RadioListTile<String>(
                  value: r,
                  title: Text(r, style: const TextStyle(fontSize: 14)),
                  activeColor: AppColors.orange,
                  contentPadding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _selected == null || _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('신고하기', style: TextStyle(color: AppColors.orange)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ReportService.submitReport(
      reason: _selected!,
      menuItemId: widget.menuItemId,
      starterMenuId: widget.starterMenuId,
      restaurantId: widget.restaurantId,
      recommendationType: widget.recommendationType,
      userId: widget.userId,
      anonymousUserId: widget.anonymousUserId,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신고가 접수됐어요. 검토 후 처리할게요.')));
    }
  }
}
