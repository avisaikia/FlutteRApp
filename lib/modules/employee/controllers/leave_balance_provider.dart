import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_balance_model.dart';

class LeaveBalanceProvider with ChangeNotifier {
  LeaveBalance? _balance;
  LeaveBalance? get balance => _balance;

  Future<void> fetchBalance(String userId) async {
    final response =
        await Supabase.instance.client
            .from('leave_balances')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    final newBalance =
        response != null
            ? LeaveBalance.fromJson(response)
            : LeaveBalance(
              id: '0',
              userId: userId,
              totalLeaves: 0,
              usedLeaves: 0,
            );

    if (_balance != newBalance) {
      _balance = newBalance;
      notifyListeners();
    }

    print('fetchBalance response: $response');
    print('Current balance: $_balance');
  }
}
