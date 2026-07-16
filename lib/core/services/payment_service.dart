import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// Resultado de un intento de pago
class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? error;

  const PaymentResult._({
    required this.success,
    this.paymentIntentId,
    this.error,
  });

  factory PaymentResult.success(String paymentIntentId) =>
      PaymentResult._(success: true, paymentIntentId: paymentIntentId);

  factory PaymentResult.failure(String error) =>
      PaymentResult._(success: false, error: error);

  factory PaymentResult.cancelled() =>
      PaymentResult._(success: false, error: 'cancelled');

  bool get isCancelled => error == 'cancelled';
}

class PaymentService {
  /// Tasas de comisión efectivas. Arrancan con los valores por defecto de
  /// [AppConstants] y se sobrescriben con lo que el admin configure en
  /// Supabase (`app_settings.client_fee_rate` / `provider_fee_rate`).
  static double clientFeeRate = AppConstants.clientFee;
  static double providerFeeRate = AppConstants.providerFee;

  /// Carga las tasas de comisión reales desde `app_settings`. Si falla
  /// (sin conexión, modo demo, claves aún no creadas), se quedan los
  /// valores por defecto de [AppConstants] — nunca lanza.
  static Future<void> initialize() async {
    try {
      final rows = await SupabaseService.client
          .from('app_settings')
          .select()
          .inFilter('key', ['client_fee_rate', 'provider_fee_rate']);
      for (final row in (rows as List<dynamic>)) {
        final r = row as Map<String, dynamic>;
        final value = (r['value'] as num?)?.toDouble();
        if (value == null) continue;
        if (r['key'] == 'client_fee_rate') clientFeeRate = value;
        if (r['key'] == 'provider_fee_rate') providerFeeRate = value;
      }
    } catch (_) {
      // Se quedan los valores por defecto de AppConstants.
    }
  }

  /// Registra la intención de pago en Supabase y devuelve éxito.
  /// El cobro real se coordinará manualmente o via PayPal (próxima integración).
  static Future<PaymentResult> processPayment({
    required BuildContext context,
    required int amount,
    required String currency,
    required String description,
    required String bookingId,
  }) async {
    try {
      await SupabaseService.client.from('bookings').update({
        'payment_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return PaymentResult.success(bookingId);
    } catch (e) {
      return PaymentResult.failure('Error al confirmar la reserva: $e');
    }
  }

  /// Alias para compatibilidad
  static Future<PaymentResult> authorizePayment({
    required BuildContext context,
    required int amount,
    required String currency,
    required String description,
    required String bookingId,
  }) =>
      processPayment(
        context: context,
        amount: amount,
        currency: currency,
        description: description,
        bookingId: bookingId,
      );

  /// Marcar reserva como completada (pago capturado manualmente).
  static Future<bool> capturePayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    try {
      await SupabaseService.client.from('bookings').update({
        'payment_status': 'released',
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Modelo de comisión (Garantía YALO + Membresía de Visibilidad) ───────────
  // Tasas configurables por el admin — ver [clientFeeRate] / [providerFeeRate].
  static double clientTotal(double basePrice) =>
      basePrice * (1 + clientFeeRate);

  static double providerAmount(double basePrice) =>
      basePrice * (1 - providerFeeRate);

  static double platformFee(double basePrice) =>
      basePrice * clientFeeRate + basePrice * providerFeeRate;

  static double clientGuaranteeFee(double basePrice) =>
      basePrice * clientFeeRate;

  static double providerVisibilityFee(double basePrice) =>
      basePrice * providerFeeRate;

  static int pesosToCentavos(double pesos) => (pesos * 100).round();

  static String formatPesos(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return 'RD\$$formatted';
  }

  static String formatDollars(double amount) =>
      'US\$${amount.toStringAsFixed(2)}';

  /// @deprecated — usar formatPesos
  static String formatColones(double amount) => formatPesos(amount);

  /// @deprecated — usar pesosToCentavos
  static int colonesToCentavos(double v) => pesosToCentavos(v);
}
