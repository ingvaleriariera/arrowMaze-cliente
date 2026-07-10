import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/validators/auth_validator.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;
  final bool showRequirements;

  static const Color neonGreen = Color(0xFF00F5A0);
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color checkedColor = Color(0xFF00F5A0);
  static const Color uncheckedColor = Color(0xFF444444);

  const PasswordRequirements({
    Key? key,
    required this.password,
    this.showRequirements = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showRequirements) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final result = AuthValidator.validatePassword(password);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBackground.withOpacity(0.5),
        border: Border.all(
          color: neonGreen.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('passwordRequirements'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: neonGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _RequirementRow(
            icon: Icons.format_list_numbered,
            text: l10n.translate('passwordRequiresMinLength'),
            isValid: result.hasMinLength,
          ),
          const SizedBox(height: 8),
          _RequirementRow(
            icon: Icons.text_fields,
            text: l10n.translate('passwordRequiresUpperCase'),
            isValid: result.hasUpperCase,
          ),
          const SizedBox(height: 8),
          _RequirementRow(
            icon: Icons.security,
            text: l10n.translate('passwordRequiresSpecialChar'),
            isValid: result.hasSpecialChar,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isValid;

  const _RequirementRow({
    required this.icon,
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isValid ? PasswordRequirements.checkedColor : PasswordRequirements.uncheckedColor;

    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
