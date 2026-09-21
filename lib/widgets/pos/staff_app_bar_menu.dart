import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';
import 'package:ventos_pos/widgets/ventos/ventos_avatar.dart';

/// Staff avatar + name in the app bar, with switch / lock actions.
class StaffAppBarMenu extends StatefulWidget {
  const StaffAppBarMenu({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.onLogOut,
    required this.onLockDevice,
  });

  final String displayName;
  final String? avatarUrl;
  final VoidCallback onLogOut;
  final VoidCallback onLockDevice;

  @override
  State<StaffAppBarMenu> createState() => _StaffAppBarMenuState();
}

class _StaffAppBarMenuState extends State<StaffAppBarMenu> {
  final MenuController _menuController = MenuController();

  void _toggleMenu() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    const avatarSize = 32.0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MenuAnchor(
        controller: _menuController,
        alignmentOffset: const Offset(0, 6),
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(VentosColors.cardOpaque),
          elevation: WidgetStateProperty.all(12),
          shadowColor: WidgetStateProperty.all(VentosColors.shadowSm),
          padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: VentosColors.strokeSoft),
            ),
          ),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
        builder: (context, controller, child) {
          final isOpen = controller.isOpen;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleMenu,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isOpen
                      ? VentosColors.muted.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VentosAvatar(
                      displayName: widget.displayName,
                      avatarUrl: widget.avatarUrl,
                      size: avatarSize,
                      borderRadius: avatarSize / 2,
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        widget.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevrons_up_down,
                      size: 14,
                      color: VentosColors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        menuChildren: [
          _StaffMenuHeader(
            displayName: widget.displayName,
            avatarUrl: widget.avatarUrl,
          ),
          const Divider(height: 1, color: VentosColors.strokeSoft),
          _StaffMenuAction(
            icon: LucideIcons.log_out,
            label: 'Log out',
            onPressed: () {
              _menuController.close();
              widget.onLogOut();
            },
          ),
          _StaffMenuAction(
            icon: LucideIcons.lock,
            label: 'Lock device',
            onPressed: () {
              _menuController.close();
              widget.onLockDevice();
            },
          ),
        ],
      ),
    );
  }
}

class _StaffMenuHeader extends StatelessWidget {
  const _StaffMenuHeader({
    required this.displayName,
    this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          VentosAvatar(
            displayName: displayName,
            avatarUrl: avatarUrl,
            size: 36,
            borderRadius: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffMenuAction extends StatelessWidget {
  const _StaffMenuAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        minimumSize: WidgetStateProperty.all(const Size(200, 40)),
        alignment: Alignment.centerLeft,
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 16, color: VentosColors.textStrong),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VentosColors.textStrong,
                ),
          ),
        ],
      ),
    );
  }
}
