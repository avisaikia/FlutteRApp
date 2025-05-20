import 'package:final_project/modules/employee/models/leave_balance_model.dart';
import 'package:flutter/material.dart';

class LeaveBalanceCard extends StatelessWidget {
  final LeaveBalance leaveBalance;

  const LeaveBalanceCard({super.key, required this.leaveBalance});

  LinearGradient getRemainingLeavesGradient(double remaining, double total) {
    final percentage = (remaining / total).clamp(0.0, 1.0);
    final color = Color.lerp(Colors.red, Colors.green, percentage)!;

    return LinearGradient(
      colors: [color, color.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget buildGradientTile(
    String title,
    String value,
    LinearGradient gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String format(int value) => value.toString();

  @override
  Widget build(BuildContext context) {
    final total = leaveBalance.totalLeaves;
    final used = leaveBalance.usedLeaves;
    final remaining = leaveBalance.remainingLeaves;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave Balance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: buildGradientTile(
                    'Total Leaves',
                    format(total),
                    const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildGradientTile(
                    'Used Leaves',
                    format(used),
                    const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildGradientTile(
                    'Remaining Leaves',
                    format(remaining),
                    getRemainingLeavesGradient(
                      remaining.toDouble(),
                      total.toDouble(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
