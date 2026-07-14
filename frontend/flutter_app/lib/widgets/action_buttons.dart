import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The three admin resolution buttons shown on the threat screen.
/// Buttons become disabled with a loading spinner while [isResolving].
class ActionButtons extends StatelessWidget {
  final bool isResolving;
  final void Function(String action) onAction;
  final VoidCallback onQuarantineRequest; // triggers confirmation dialog

  const ActionButtons({
    super.key,
    required this.isResolving,
    required this.onAction,
    required this.onQuarantineRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(),
        const SizedBox(height: 12),
        _ActionBtn(
          label: 'Allow',
          sublabel: 'Resume execution — permit this action',
          icon: Icons.check_circle_rounded,
          color: AppTheme.green,
          isResolving: isResolving,
          onPressed: isResolving ? null : () => onAction('ALLOW'),
        ),
        const SizedBox(height: 10),
        _ActionBtn(
          label: 'Block Command',
          sublabel: 'Discard payload and resume safely',
          icon: Icons.block_rounded,
          color: AppTheme.amber,
          isResolving: isResolving,
          onPressed: isResolving ? null : () => onAction('BLOCK_COMMAND'),
        ),
        const SizedBox(height: 10),
        _ActionBtn(
          label: 'Quarantine Agent',
          sublabel: 'Terminate subprocess — hard quarantine',
          icon: Icons.dangerous_rounded,
          color: AppTheme.red,
          isResolving: isResolving,
          onPressed: isResolving ? null : onQuarantineRequest,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Admin Decision Required',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.secondaryText,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Individual action button ──────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool isResolving;
  final VoidCallback? onPressed;

  const _ActionBtn({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.isResolving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? color.withAlpha(20) : color.withAlpha(30),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.btnRadius),
            side: BorderSide(
              color: disabled ? color.withAlpha(40) : color.withAlpha(160),
              width: 1.5,
            ),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: isResolving && onPressed == null
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: color, strokeWidth: 2.5),
              )
            : Row(
                children: [
                  Icon(icon,
                      color: disabled ? color.withAlpha(80) : color,
                      size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: disabled ? color.withAlpha(80) : color,
                          ),
                        ),
                        Text(
                          sublabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
