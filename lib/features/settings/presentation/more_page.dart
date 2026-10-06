import 'package:flutter/material.dart';

import '../../../widgets/app_components.dart';
import '../../analytics/reports_page.dart';
import '../../management/expenses_page.dart';
import '../../management/products_page.dart';
import '../../calculator/presentation/everyday_calculator_page.dart';
import '../../qazi/presentation/qazi_composition_page.dart';
import 'settings_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) => pageContent(
        title: 'Boshqaruv',
        subtitle: 'Qazi, xarajatlar, zaxira va sozlamalar',
        children: [
          SectionCard(
            title: 'Kundalik hisob-kitob',
            child: _NavigationTile(
              icon: Icons.calculate_outlined,
              title: 'Oddiy kalkulyator',
              subtitle: 'Amallar va oldingi hisoblar tarixi',
              page: const EverydayCalculatorPage(),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Ishlab chiqarish',
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.restaurant_outlined,
                  title: 'Qazi tarkibi',
                  subtitle: 'Real o‘lchov va tarixiy tahlil',
                  page: const QaziCompositionPage(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Xarajatlar',
                  subtitle: 'Kunlik va oylik sarflar',
                  page: const ExpensesPage(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Mahsulotlar',
                  subtitle: 'Zaxira va birlik narxlari',
                  page: const ProductsPage(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.description_outlined,
                  title: 'Hisobotlar',
                  subtitle: 'Davr bo‘yicha jamlanma',
                  page: const ReportsPage(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Ilova',
            child: _NavigationTile(
              icon: Icons.settings_outlined,
              title: 'Sozlamalar va zaxira',
              subtitle: 'Ko‘rinish, ma’lumotlarni saqlash va tiklash',
              page: const SettingsPage(),
            ),
          ),
        ],
      );
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => pushPage(context, page),
      );
}
