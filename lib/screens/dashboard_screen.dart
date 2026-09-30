import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/citizen_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/stat_card.dart';
import 'citizen_list_screen.dart';
import 'add_citizen_screen.dart';
import 'pdf_export_screen.dart';
import 'backup_restore_screen.dart';
import 'gs_profile_screen.dart';
import 'add_column_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CitizenProvider>().loadCitizens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final t = profile.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GSProfileScreen()),
            ),
            tooltip: t('gs_profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App subtitle
            Text(
              t('app_subtitle'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // 6-card grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  DashboardCard(
                    title: t('add_citizen'),
                    icon: Icons.person_add_rounded,
                    gradient: AppColors.dashboardGradients[0],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCitizenScreen()),
                    ).then((_) => context.read<CitizenProvider>().loadCitizens()),
                  ),
                  DashboardCard(
                    title: t('citizen_list'),
                    icon: Icons.people_rounded,
                    gradient: AppColors.dashboardGradients[1],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenListScreen()),
                    ).then((_) => context.read<CitizenProvider>().loadCitizens()),
                  ),
                  DashboardCard(
                    title: t('export_pdf'),
                    icon: Icons.picture_as_pdf_rounded,
                    gradient: AppColors.dashboardGradients[4],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PdfExportScreen()),
                    ),
                  ),
                  DashboardCard(
                    title: t('backup_data'),
                    icon: Icons.cloud_upload_rounded,
                    gradient: AppColors.dashboardGradients[5],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                    ),
                  ),
                  DashboardCard(
                    title: t('custom_columns'),
                    icon: Icons.table_chart_rounded,
                    gradient: AppColors.dashboardGradients[2],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddColumnScreen()),
                    ),
                  ),
                  DashboardCard(
                    title: t('gs_profile'),
                    icon: Icons.manage_accounts_rounded,
                    gradient: AppColors.dashboardGradients[7],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GSProfileScreen()),
                    ),
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
