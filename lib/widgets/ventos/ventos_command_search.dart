import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_decorations.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

/// Search field inside combobox/command popovers (web `CommandInput` + InputGroup).
class VentosCommandSearchInput extends StatelessWidget {
  const VentosCommandSearchInput({
    super.key,
    required this.focusNode,
    required this.placeholder,
    required this.onChanged,
  });

  final FocusNode focusNode;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: VentosColors.muted.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: VentosColors.input.withValues(alpha: 0.35)),
        ),
        padding: ventosSingleLineShellPadding(height: 32, fontSize: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: ventosSingleLineTextBlockHeight(fontSize: 14),
                child: TextField(
                  focusNode: focusNode,
                  onChanged: onChanged,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                    color: VentosColors.textStrong,
                  ),
                  strutStyle: const StrutStyle(
                    fontSize: 14,
                    height: 1.25,
                    forceStrutHeight: true,
                  ),
                  cursorHeight: 16,
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
                      color: VentosColors.textSoft.withValues(alpha: 0.95),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            Icon(
              LucideIcons.search,
              size: 16,
              color: VentosColors.mutedForeground.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
