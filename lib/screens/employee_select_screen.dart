import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/services/auth_repository.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';
import 'package:ventos_pos/widgets/pos/staff_sign_in_dialog.dart';

class EmployeeSelectScreen extends StatefulWidget {
  const EmployeeSelectScreen({
    super.key,
    required this.auth,
    required this.onStaffActivated,
    required this.onDeviceLogout,
  });

  final AuthRepository auth;
  final VoidCallback onStaffActivated;
  final VoidCallback onDeviceLogout;

  @override
  State<EmployeeSelectScreen> createState() => _EmployeeSelectScreenState();
}

class _EmployeeSelectScreenState extends State<EmployeeSelectScreen> {
  List<PosEmployeeCard>? _roster;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roster = await widget.auth.fetchEmployeeRoster();
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _loading = false;
      });
    } on GraphqlException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openStaffSignIn(PosEmployeeCard employee) async {
    final ok = await showStaffSignInDialog(
      context: context,
      employee: employee,
      auth: widget.auth,
    );
    if (ok == true) widget.onStaffActivated();
  }

  @override
  Widget build(BuildContext context) {
    return VentosScaffold(
      appBar: AppBar(
        title: const Text('Ventos POS'),
        actions: [
          VentosButton(
            onPressed: widget.onDeviceLogout,
            variant: VentosButtonVariant.ghost,
            child: const Text('Lock device'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      VentosButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : VentosPageBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PageHeader(
                        title: 'Who is working?',
                        description: 'Select your name, then enter your password or POS PIN.',
                      ),
                      if ((_roster ?? []).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: Text('No active employees.')),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 900 ? 4 : width >= 600 ? 3 : 2;
                            const avatarSize = 80.0;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 140,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 28,
                              ),
                              itemCount: _roster!.length,
                              itemBuilder: (context, index) {
                                final e = _roster![index];
                                final canSignIn =
                                    e.canSignInWithPassword || e.canSignInWithPin;
                                return _StaggeredRosterEntrance(
                                  index: index,
                                  child: _RosterPersonTile(
                                    displayName: e.displayName,
                                    avatarUrl: e.avatarUrl,
                                    avatarSize: avatarSize,
                                    enabled: canSignIn,
                                    signInHint: canSignIn ? null : e.signInHint,
                                    onTap: canSignIn ? () => _openStaffSignIn(e) : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StaggeredRosterEntrance extends StatefulWidget {
  const _StaggeredRosterEntrance({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_StaggeredRosterEntrance> createState() => _StaggeredRosterEntranceState();
}

class _StaggeredRosterEntranceState extends State<_StaggeredRosterEntrance>
    with SingleTickerProviderStateMixin {
  static const _staggerMs = 70;
  static const _maxStaggerIndex = 18;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.45), end: Offset.zero).animate(curve);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(curve);

    final delay = Duration(
      milliseconds: widget.index.clamp(0, _maxStaggerIndex) * _staggerMs,
    );
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RosterPersonTile extends StatefulWidget {
  const _RosterPersonTile({
    required this.displayName,
    required this.avatarUrl,
    required this.avatarSize,
    required this.enabled,
    this.signInHint,
    this.onTap,
  });

  final String displayName;
  final String? avatarUrl;
  final double avatarSize;
  final bool enabled;
  final String? signInHint;
  final VoidCallback? onTap;

  @override
  State<_RosterPersonTile> createState() => _RosterPersonTileState();
}

class _RosterPersonTileState extends State<_RosterPersonTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showHover = widget.enabled && _hovered;
    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: showHover
                    ? Border.all(color: VentosColors.primary, width: 2)
                    : null,
              ),
              child: VentosAvatar(
                displayName: widget.displayName,
                avatarUrl: widget.avatarUrl,
                size: widget.avatarSize,
                borderRadius: widget.avatarSize / 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? VentosColors.textStrong
                        : VentosColors.textSoft,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.signInHint != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.signInHint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.85),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
