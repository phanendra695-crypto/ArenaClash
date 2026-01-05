import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class PaymentService {
  late Razorpay _razorpay;

  PaymentService() {
    _razorpay = Razorpay();
  }

  void init({
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (_) => onSuccess());
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (_) => onFailure());
  }

  void openCheckout({
    required int amount,
    required String description,
    required String email,
  }) {
    var options = {
      'key': 'rzp_test_S09OIpiOmgMzCO', // 🔴 replace later
      'amount': amount * 100, // in paise
      'name': 'ArenaClash',
      'description': description,
      'prefill': {
        'email': email,
      },
      'theme': {
        'color': '#7C4DFF',
      }
    };

    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
