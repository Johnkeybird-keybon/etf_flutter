import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'account_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ETF - Expense Tracker & Personal Finance'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                auth.logout();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Row(children: [
                Icon(Icons.logout), SizedBox(width: 8), Text('Logout'),
              ])),
            ],
          ),
        ],
      ),
      body: Row(children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
            NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Transactions')),
            NavigationRailDestination(icon: Icon(Icons.category), label: Text('Categories')),
            NavigationRailDestination(icon: Icon(Icons.pie_chart), label: Text('Budgets')),
            NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Reports')),
            NavigationRailDestination(icon: Icon(Icons.person), label: Text('Account')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: switch (_index) {
          0 => const DashboardScreen(),
          1 => const TransactionsScreen(),
          2 => const CategoriesScreen(),
          3 => const BudgetsScreen(),
          4 => const ReportsScreen(),
          _ => const AccountScreen(),
        }),
      ]),
    );
  }
}