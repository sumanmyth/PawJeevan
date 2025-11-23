import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final InputDecoration? decoration;
  final bool isExpanded;

  const AppDropdownFormField({
    super.key,
    required this.items,
    this.value,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.decoration,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark ? Colors.grey[800] : Colors.grey[50];
    final effectiveValue = value ?? initialValue;

    // Start from either the provided decoration or the app's theme so
    // dropdown fields match other input fields exactly (borders, padding).
    final baseDecoration = (decoration ?? const InputDecoration()).applyDefaults(Theme.of(context).inputDecorationTheme);
    final effectiveDecoration = baseDecoration.copyWith(
      filled: true,
      fillColor: baseDecoration.fillColor ?? fillColor,
      contentPadding: baseDecoration.contentPadding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );

    final fieldKey = GlobalKey();

    return FormField<T>(
      initialValue: effectiveValue,
      validator: validator,
      builder: (field) {
        final selectedItem = items.firstWhere((it) => it.value == field.value, orElse: () => items.first);
        final selectedLabel = field.value != null ? (selectedItem.child is Text ? (selectedItem.child as Text).data : selectedItem.value?.toString()) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: effectiveDecoration.copyWith(errorText: field.errorText),
              isEmpty: field.value == null,
              child: InkWell(
                key: fieldKey,
                  onTap: () async {
                    final renderBox = fieldKey.currentContext?.findRenderObject() as RenderBox?;
                    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                    RelativeRect position;
                    double itemWidth = 240;
                    final inputTheme = Theme.of(context).inputDecorationTheme;
                    final borderColor = (inputTheme.enabledBorder is OutlineInputBorder)
                      ? ((inputTheme.enabledBorder as OutlineInputBorder).borderSide.color)
                      : (isDark ? Colors.grey[700]! : Colors.grey[200]!);
                    if (renderBox != null) {
                      final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
                      final overlaySize = overlay.size;
                      final top = offset.dy + renderBox.size.height;

                      // Prefer popup width equal to the field, but ensure a comfortable minimum
                      // so small fields don't produce cramped popups.
                      final desiredWidth = math.max(renderBox.size.width, 220.0);

                      // Center the popup horizontally over the field when it's wider than the field.
                      double left = offset.dx + (renderBox.size.width - desiredWidth) / 2.0;
                      // Clamp to stay within overlay bounds with a small margin
                      left = left.clamp(8.0, overlaySize.width - desiredWidth - 8.0);
                      final right = overlaySize.width - left - desiredWidth;
                      final bottom = overlaySize.height - offset.dy;

                      position = RelativeRect.fromLTRB(left, top, right, bottom);
                      itemWidth = desiredWidth;
                    } else {
                      position = const RelativeRect.fromLTRB(0, 100, 0, 0);
                    }

                    final picked = await showMenu<T>(
                      context: context,
                      position: position,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: borderColor)),
                      elevation: 16,
                      items: [
                        for (var i = 0; i < items.length; i++) ...[
                          PopupMenuItem<T>(
                            value: items[i].value,
                            padding: EdgeInsets.zero,
                            child: Container(
                              width: itemWidth,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              // Round selected background corners to match popup rounded rect
                              decoration: items[i].value == field.value
                                  ? BoxDecoration(
                                      color: const Color(0xFF7C3AED),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(i == 0 ? 12 : 0),
                                        bottom: Radius.circular(i == items.length - 1 ? 12 : 0),
                                      ),
                                    )
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (items[i].child is Text) ? (items[i].child as Text).data ?? '' : (items[i].value?.toString() ?? ''),
                                      style: TextStyle(
                                        color: items[i].value == field.value ? Colors.white : (isDark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                  ),
                                  if (items[i].value == field.value)
                                    const Icon(Icons.check, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          if (i < items.length - 1) const PopupMenuDivider(height: 1),
                        ],
                      ],
                    );

                  if (picked != null) {
                    field.didChange(picked);
                    if (onChanged != null) onChanged!(picked);
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel ?? (effectiveDecoration.hintText ?? ''),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ),
            // If the InputDecorator didn't render the error (older Flutter versions), show it here
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                child: Text(field.errorText ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}
