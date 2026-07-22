// lib/services/razorpay_web.dart
import 'dart:js' as js;

Future<void> openRazorpayWeb({
  required double amount,
  required String currency,
  required String orderId,
  required String keyId,
  required String name,
  required String description,
  required String prefillName,
  required String prefillEmail,
  required String prefillContact,
  required String paymentMethod,
  required Function(String paymentId, String orderId, String signature) onSuccess,
  required Function(String error) onError,
}) async {
  String? rzpMethod;
  if (paymentMethod.toLowerCase().contains('upi')) rzpMethod = 'upi';
  if (paymentMethod.toLowerCase().contains('card')) rzpMethod = 'card';
  if (paymentMethod.toLowerCase().contains('net')) rzpMethod = 'netbanking';

  final prefillOptions = {
    'name': prefillName,
    'email': prefillEmail,
    'contact': prefillContact,
  };
  if (rzpMethod != null) {
    prefillOptions['method'] = rzpMethod;
  }

  final options = js.JsObject.jsify({
    'key': keyId,
    'amount': (amount * 100).toInt(),
    'currency': currency,
    'name': name,
    'description': description,
    'order_id': orderId,
    'prefill': prefillOptions,
    'theme': {
      'color': '#1B5E20' // AppTheme.primaryGreen
    },
  });

  options['handler'] = js.allowInterop((response) {
    onSuccess(
      response['razorpay_payment_id'] ?? '',
      response['razorpay_order_id'] ?? '',
      response['razorpay_signature'] ?? '',
    );
  });

  final rzp = js.JsObject(js.context['Razorpay'], [options]);
  
  rzp.callMethod('on', [
    'payment.failed',
    js.allowInterop((response) {
      onError(response['error']['description'] ?? 'Payment failed');
    })
  ]);
  
  rzp.callMethod('open');
}
