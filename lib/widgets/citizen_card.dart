import 'dart:io';
import 'package:flutter/material.dart';
import '../models/citizen.dart';
import '../utils/app_colors.dart';

class CitizenCard extends StatelessWidget {
  final Citizen citizen;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onView;

  const CitizenCard({
    super.key,
    required this.citizen,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.isMultiSelect = false,
    this.onEdit,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 14),
                Expanded(child: _buildInfo(context)),
                if (isMultiSelect) _buildCheckbox(),
                if (!isMultiSelect) _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final photoFile = citizen.photo != null ? File(citizen.photo!) : null;
    final hasPhoto = photoFile != null && photoFile.existsSync();

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withAlpha(80),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: hasPhoto
                ? Image.file(photoFile, fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceLight,
                    child: Center(
                      child: Text(
                        citizen.name.isNotEmpty
                            ? citizen.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          citizen.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.credit_card_rounded, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              citizen.nic,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        if (citizen.village.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                citizen.village,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
        if (citizen.gender.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _genderColor(citizen.gender).withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _genderColor(citizen.gender).withAlpha(80)),
            ),
            child: Text(
              citizen.gender,
              style: TextStyle(
                color: _genderColor(citizen.gender),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onView != null)
          _ActionButton(
            icon: Icons.visibility_rounded,
            color: AppColors.info,
            onTap: onView!,
          ),
        if (onEdit != null) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.edit_rounded,
            color: AppColors.accent,
            onTap: onEdit!,
          ),
        ],
      ],
    );
  }

  Color _genderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male': return AppColors.info;
      case 'female': return const Color(0xFFEC407A);
      default: return AppColors.textSecondary;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
