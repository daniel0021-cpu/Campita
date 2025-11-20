import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 8),
            Text('Admin Panel'),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.domain), text: 'Buildings'),
            Tab(icon: Icon(Icons.route), text: 'Routes'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _UsersTab(),
          _BuildingsTab(),
          _RoutesTab(),
          _AnalyticsTab(),
          _SettingsTab(),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pushReplacementNamed('/'); // Go to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD TAB
// ============================================================================
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats Cards
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: const [
              _StatCard(
                title: 'Total Users',
                value: '2,847',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Buildings',
                value: '30',
                subtitle: '22 Academic • 5 Admin • 3 Facilities',
                icon: Icons.domain,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Routes Generated',
                value: '1,567',
                subtitle: 'Today',
                icon: Icons.route,
                color: Colors.orange,
              ),
              _StatCard(
                title: "Today's Traffic",
                value: '543',
                subtitle: 'Active users',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Activity
          Text(
            'Recent Activity',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activities = [
                  {'user': 'John Doe', 'action': 'Created new route', 'time': '2 mins ago'},
                  {'user': 'Jane Smith', 'action': 'Updated building info', 'time': '15 mins ago'},
                  {'user': 'Admin', 'action': 'Added new user', 'time': '1 hour ago'},
                  {'user': 'Mike Johnson', 'action': 'Generated report', 'time': '2 hours ago'},
                  {'user': 'Sarah Williams', 'action': 'Modified settings', 'time': '3 hours ago'},
                ];
                final activity = activities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(activity['user']!),
                  subtitle: Text(activity['action']!),
                  trailing: Text(
                    activity['time']!,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                Icon(icon, color: color, size: 28),
              ],
            ),
            Text(
              value,
              style: AppTextStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// USERS TAB
// ============================================================================
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with search and add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        
        // Users table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Join Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: List.generate(10, (index) {
                  return DataRow(cells: [
                    DataCell(Text('User ${index + 1}')),
                    DataCell(Text('user${index + 1}@example.com')),
                    DataCell(Text(index % 3 == 0 ? 'Admin' : 'Student')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                        ),
                      ),
                    ),
                    const DataCell(Text('2024-01-15')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BUILDINGS TAB
// ============================================================================
class _BuildingsTab extends StatelessWidget {
  const _BuildingsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Buildings Management', style: AppTextStyles.heading2),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Building'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        // Buildings table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Floors')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  _buildBuildingRow('Main Library', 'Library', '3', 'Active'),
                  _buildBuildingRow('Admin Block', 'Administrative', '2', 'Active'),
                  _buildBuildingRow('Science Lab', 'Academic', '4', 'Active'),
                  _buildBuildingRow('Sports Complex', 'Sports', '2', 'Under Maintenance'),
                  _buildBuildingRow('Student Center', 'Facilities', '3', 'Active'),
                  _buildBuildingRow('Engineering Block', 'Academic', '5', 'Active'),
                  _buildBuildingRow('Medical Center', 'Healthcare', '2', 'Active'),
                  _buildBuildingRow('Cafeteria', 'Dining', '1', 'Active'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildBuildingRow(String name, String type, String floors, String status) {
    return DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text(type)),
      DataCell(Text(floors)),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status == 'Active' ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: status == 'Active' ? Colors.green.shade700 : Colors.orange.shade700,
              fontSize: 12,
            ),
          ),
        ),
      ),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    ]);
  }
}

// ============================================================================
// ROUTES TAB
// ============================================================================
class _RoutesTab extends StatelessWidget {
  const _RoutesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Routes Overview', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          
          // Popular Routes Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular Routes', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),
                  ...List.generate(5, (index) {
                    final routes = [
                      {'from': 'Main Gate', 'to': 'Library', 'count': '234'},
                      {'from': 'Hostel A', 'to': 'Lecture Hall', 'count': '187'},
                      {'from': 'Cafeteria', 'to': 'Admin Block', 'count': '156'},
                      {'from': 'Sports Complex', 'to': 'Medical Center', 'count': '143'},
                      {'from': 'Library', 'to': 'Science Lab', 'count': '128'},
                    ];
                    final route = routes[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        child: Text('${index + 1}'),
                      ),
                      title: Text('${route['from']} → ${route['to']}'),
                      trailing: Chip(
                        label: Text('${route['count']} uses'),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // All Routes Table
          Text('All Routes', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('From')),
                DataColumn(label: Text('To')),
                DataColumn(label: Text('Distance')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('Type')),
              ],
              rows: List.generate(8, (index) {
                return DataRow(cells: [
                  DataCell(Text('Location ${index + 1}')),
                  DataCell(Text('Destination ${index + 1}')),
                  DataCell(Text('${(index + 1) * 150}m')),
                  DataCell(Text('${(index + 1) * 2} min')),
                  DataCell(Text(index % 2 == 0 ? 'Walking' : 'Cycling')),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ANALYTICS TAB
// ============================================================================
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics Dashboard', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          
          // Placeholder for charts
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildChartCard('Daily Active Users', Icons.people),
              _buildChartCard('Route Generation Trends', Icons.route),
              _buildChartCard('Building Popularity', Icons.domain),
              _buildChartCard('Peak Usage Times', Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.bodyLarge),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  'Chart Placeholder',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SETTINGS TAB
// ============================================================================
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _arFeaturesEnabled = true;
  bool _userFeedbackEnabled = true;
  bool _maintenanceMode = false;
  bool _walkingIconsEnabled = true;
  bool _voiceGuidanceEnabled = false;
  bool _autoRerouteEnabled = true;
  bool _twoFactorAuthEnabled = false;
  bool _apiRateLimitingEnabled = true;
  bool _logAdminActionsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.heading2),
          const SizedBox(height: 24),

          // General Settings
          _buildSettingsSection(
            'General Settings',
            [
              _buildSwitchTile(
                'AR Features',
                'Enable augmented reality navigation features',
                _arFeaturesEnabled,
                (value) => setState(() => _arFeaturesEnabled = value),
              ),
              _buildSwitchTile(
                'User Feedback',
                'Allow users to submit feedback and bug reports',
                _userFeedbackEnabled,
                (value) => setState(() => _userFeedbackEnabled = value),
              ),
              _buildSwitchTile(
                'Maintenance Mode',
                'Put the app in maintenance mode (users cannot access)',
                _maintenanceMode,
                (value) => setState(() => _maintenanceMode = value),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Navigation Settings
          _buildSettingsSection(
            'Navigation Settings',
            [
              _buildSwitchTile(
                'Walking Icons',
                'Show walking direction icons on the map',
                _walkingIconsEnabled,
                (value) => setState(() => _walkingIconsEnabled = value),
              ),
              _buildSwitchTile(
                'Voice Guidance',
                'Enable voice navigation instructions',
                _voiceGuidanceEnabled,
                (value) => setState(() => _voiceGuidanceEnabled = value),
              ),
              _buildSwitchTile(
                'Auto Re-route',
                'Automatically re-route when user goes off path',
                _autoRerouteEnabled,
                (value) => setState(() => _autoRerouteEnabled = value),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Security Settings
          _buildSettingsSection(
            'Security Settings',
            [
              _buildSwitchTile(
                'Two-Factor Authentication',
                'Require 2FA for admin panel access',
                _twoFactorAuthEnabled,
                (value) => setState(() => _twoFactorAuthEnabled = value),
              ),
              _buildSwitchTile(
                'API Rate Limiting',
                'Enable rate limiting for API endpoints',
                _apiRateLimitingEnabled,
                (value) => setState(() => _apiRateLimitingEnabled = value),
              ),
              _buildSwitchTile(
                'Log Admin Actions',
                'Keep detailed logs of all admin activities',
                _logAdminActionsEnabled,
                (value) => setState(() => _logAdminActionsEnabled = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
