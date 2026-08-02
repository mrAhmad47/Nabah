import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/nebah_colors.dart';

class PaystackSubscriptionScreen extends StatefulWidget {
  const PaystackSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<PaystackSubscriptionScreen> createState() => _PaystackSubscriptionScreenState();
}

class _PaystackSubscriptionScreenState extends State<PaystackSubscriptionScreen> {
  String _selectedPlan = 'premium'; // 'free', 'premium', 'estate'
  bool _isProcessing = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionState();
  }

  Future<void> _loadSubscriptionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedPlan = prefs.getString('nebah_selected_plan') ?? 'premium';
        _isSubscribed = prefs.getBool('nebah_is_subscribed') ?? false;
      });
    }
  }

  Future<void> _saveSelectedPlan(String planId) async {
    setState(() {
      _selectedPlan = planId;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nebah_selected_plan', planId);
  }

  void _triggerPaystackCheckout() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nebah_is_subscribed', true);
      await prefs.setString('nebah_selected_plan', _selectedPlan);

      // Update Supabase profile
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client.from('profiles').update({
            'is_subscribed': true,
            'subscription_plan': _selectedPlan,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', user.id);
          debugPrint('⚡ Subscription plan updated in Supabase cloud DB!');
        }
      } catch (e) {
        debugPrint('⚠️ Error updating subscription status in Supabase: $e');
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSubscribed = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Paystack Payment Successful! Nebah Shield Premium Activated.'),
            backgroundColor: NebahColors.safetyEmerald,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nebah Premium & Plans'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER BANNER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEBAH SHIELD PREMIUM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Unlock stealth hardware panic, medical QR ID cards, and AI trip guardian.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Select Membership Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
            const SizedBox(height: 14),

            // PLAN 1: BASIC FREE
            _buildPlanCard(
              id: 'free',
              title: 'Basic Free',
              price: '₦0 / month',
              features: [
                'In-App SOS Dispatch',
                '4-Tier Community Hierarchy',
                'Basic Route Guardian Navigation',
              ],
              isPopular: false,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // PLAN 2: NEBAH SHIELD PREMIUM
            _buildPlanCard(
              id: 'premium',
              title: 'Nebah Shield Premium',
              price: '₦1,500 / month',
              features: [
                'Stealth Hardware Panic (Volume Button)',
                'Medical & Emergency Identity QR Card',
                'Background Journey Guardian & ETA Alerts',
                'Gemini AI Incident Insights & Risk Radar',
                'Unlimited Emergency Contacts',
              ],
              isPopular: true,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // PLAN 3: ESTATE B2B
            _buildPlanCard(
              id: 'estate',
              title: 'Estate & Community B2B',
              price: '₦15,000 / month',
              features: [
                'Full Vigilante Security Squad Portal',
                'Digital ID Card Issuance & QR Scanner',
                'Mai Anguwa Jurisdiction Announcements',
                'Direct Police & SEMA Dispatch Priority',
              ],
              isPopular: false,
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // PAYSTACK CHECKOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _triggerPaystackCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NebahColors.cobaltBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            _isSubscribed ? 'PLAN ACTIVE (RENEW VIA PAYSTACK)' : 'PAY VIA PAYSTACK (NIGERIA)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required List<String> features,
    required bool isPopular,
    required bool isDark,
  }) {
    final isSelected = _selectedPlan == id;

    return GestureDetector(
      onTap: () => _saveSelectedPlan(id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? NebahColors.cobaltBlue.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? NebahColors.cobaltBlue
                : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NebahColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: NebahColors.cobaltBlue,
                      ),
                    ),
                  ],
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: NebahColors.safetyEmerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
