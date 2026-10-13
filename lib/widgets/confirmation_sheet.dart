import 'package:flutter/material.dart';
import 'package:chatapp/utils/responsive.dart';
import 'package:chatapp/widgets/glass_container.dart';

/// Shows [builder] as a bottom sheet on phones and as a centered dialog on
/// desktop-sized windows. The builder receives `isDialog` so the content can
/// drop the drag handle and round every corner when shown as a dialog.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, bool isDialog) builder,
  double dialogMaxWidth = 420,
}) {
  if (isDesktopLayout(context)) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogMaxWidth),
          child: builder(context, true),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => builder(context, false),
  );
}

BorderRadius _sheetRadius(bool isDialog) => isDialog
    ? BorderRadius.circular(24)
    : const BorderRadius.vertical(top: Radius.circular(24));

Widget _handleBar(BuildContext context, bool isDialog) {
  if (isDialog) return const SizedBox.shrink();
  final colorScheme = Theme.of(context).colorScheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withAlpha(50),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
}

/// Shows a styled confirmation bottom sheet with customizable actions.
/// Returns the result of the user's choice.
Future<T?> showConfirmationSheet<T>({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  String cancelText = 'Cancel',
  Color? confirmColor,
  IconData? icon,
  bool isDanger = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final effectiveConfirmColor =
      confirmColor ?? (isDanger ? colorScheme.error : colorScheme.primary);

  return showAdaptiveSheet<T>(
    context: context,
    builder: (context, isDialog) => _ConfirmationSheetContent(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: effectiveConfirmColor,
      icon: icon,
      isDanger: isDanger,
      isDialog: isDialog,
    ),
  );
}

class _ConfirmationSheetContent extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final IconData? icon;
  final bool isDanger;
  final bool isDialog;

  const _ConfirmationSheetContent({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.confirmColor,
    this.icon,
    required this.isDanger,
    required this.isDialog,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      borderRadius: _sheetRadius(isDialog),
      blurSigma: 20,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handleBar(context, isDialog),

              // Icon
              if (icon != null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: confirmColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: confirmColor),
                ),
                const SizedBox(height: 20),
              ],

              // Title
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows an action sheet with multiple options
Future<T?> showActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<ActionSheetItem<T>> actions,
}) async {
  return showAdaptiveSheet<T>(
    context: context,
    builder: (context, isDialog) => _ActionSheetContent<T>(
      title: title,
      message: message,
      actions: actions,
      isDialog: isDialog,
    ),
  );
}

class ActionSheetItem<T> {
  final String label;
  final IconData? icon;
  final T value;
  final bool isDanger;

  const ActionSheetItem({
    required this.label,
    this.icon,
    required this.value,
    this.isDanger = false,
  });
}

class _ActionSheetContent<T> extends StatelessWidget {
  final String title;
  final String? message;
  final List<ActionSheetItem<T>> actions;
  final bool isDialog;

  const _ActionSheetContent({
    required this.title,
    this.message,
    required this.actions,
    required this.isDialog,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      borderRadius: _sheetRadius(isDialog),
      blurSigma: 20,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handleBar(context, isDialog),

              // Title
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, action.value),
                      icon: action.icon != null
                          ? Icon(action.icon, size: 20)
                          : const SizedBox.shrink(),
                      label: Text(action.label),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action.isDanger
                            ? colorScheme.errorContainer
                            : colorScheme.surfaceContainerHighest,
                        foregroundColor: action.isDanger
                            ? colorScheme.error
                            : colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows an input bottom sheet for editing text
Future<String?> showInputSheet({
  required BuildContext context,
  required String title,
  String? initialValue,
  String? hintText,
  String confirmText = 'Save',
  int maxLines = 4,
}) async {
  return showAdaptiveSheet<String>(
    context: context,
    dialogMaxWidth: 520,
    builder: (context, isDialog) => _InputSheetContent(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      confirmText: confirmText,
      maxLines: maxLines,
      isDialog: isDialog,
    ),
  );
}

class _InputSheetContent extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? hintText;
  final String confirmText;
  final int maxLines;
  final bool isDialog;

  const _InputSheetContent({
    required this.title,
    this.initialValue,
    this.hintText,
    required this.confirmText,
    required this.maxLines,
    required this.isDialog,
  });

  @override
  State<_InputSheetContent> createState() => _InputSheetContentState();
}

class _InputSheetContentState extends State<_InputSheetContent> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GlassContainer(
      borderRadius: _sheetRadius(widget.isDialog),
      blurSigma: 20,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handleBar(context, widget.isDialog),

            // Title
            Text(
              widget.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Text field
            TextField(
              controller: _controller,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Type here...',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: widget.maxLines,
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        Navigator.pop(context, _controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.confirmText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
