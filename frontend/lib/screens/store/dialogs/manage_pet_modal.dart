import 'package:flutter/material.dart';

class ManagePetModal {
  static void show({
    required BuildContext context,
    required dynamic adoption,
    required VoidCallback onEdit,
    required Function(String) onStatusChange,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with gradient
              _buildHeader(adoption, theme),
              const SizedBox(height: 8),
              // Edit Pet Details Card
              _buildEditCard(context, theme, onEdit),
              const SizedBox(height: 20),
              // Section Header
              _buildSectionHeader(theme),
              // Status Options
              _buildStatusOptions(context, adoption, onStatusChange),
              const SizedBox(height: 16),
              // Delete Button
              _buildDeleteButton(context, onDelete),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHeader(dynamic adoption, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B46C1).withOpacity(0.1),
            const Color(0xFF6B46C1).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets,
              color: Color(0xFF6B46C1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage ${adoption.petName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Update details and status',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEditCard(
    BuildContext context,
    ThemeData theme,
    VoidCallback onEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6B46C1).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF6B46C1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Edit Pet Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Text(
            'CHANGE STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatusOptions(
    BuildContext context,
    dynamic adoption,
    Function(String) onStatusChange,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildStatusOption(
              context: context,
              icon: Icons.pets,
              iconColor: Colors.green,
              title: 'Available',
              subtitle: 'Pet is available for adoption',
              isSelected: adoption.status == 'available',
              onTap: () {
                Navigator.pop(context);
                onStatusChange('available');
              },
              isFirst: true,
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
            _buildStatusOption(
              context: context,
              icon: Icons.pending,
              iconColor: Colors.orange,
              title: 'Adoption Pending',
              subtitle: 'Someone is interested in adopting',
              isSelected: adoption.status == 'pending',
              onTap: () {
                Navigator.pop(context);
                onStatusChange('pending');
              },
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
            _buildStatusOption(
              context: context,
              icon: Icons.favorite,
              iconColor: Colors.red,
              title: 'Adopted',
              subtitle: 'Pet has been successfully adopted',
              isSelected: adoption.status == 'adopted',
              onTap: () {
                Navigator.pop(context);
                onStatusChange('adopted');
              },
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
            _buildStatusOption(
              context: context,
              icon: Icons.close,
              iconColor: Colors.grey,
              title: 'Closed',
              subtitle: 'Listing is no longer active',
              isSelected: adoption.status == 'closed',
              onTap: () {
                Navigator.pop(context);
                onStatusChange('closed');
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatusOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: iconColor,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDeleteButton(BuildContext context, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDelete,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Delete Listing',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
