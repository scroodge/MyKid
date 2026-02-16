import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Product IDs in Google Play Console. Must match subscription ids created in Play Console.
const String kProductIdBasic = 'mykid_basic';
const String kProductIdPremium = 'mykid_premium';

/// Handles Google Play Billing for subscriptions and sends verified purchases to backend.
class GooglePlaySubscriptionService {
  GooglePlaySubscriptionService()
      : _iap = InAppPurchase.instance,
        _client = Supabase.instance.client;

  final InAppPurchase _iap;
  final SupabaseClient _client;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _available = false;

  bool get isAvailable => _available;
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Initialize and query product details. Call once (e.g. when subscription screen opens on Android).
  Future<bool> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) return false;
    await _loadProducts();
    return _products.isNotEmpty;
  }

  Future<void> _loadProducts() async {
    const ids = {kProductIdBasic, kProductIdPremium};
    final response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      // Products not yet created in Play Console or wrong ids
      return;
    }
    _products = response.productDetails;
  }

  /// Start listening to purchase updates. Call after initialize().
  void listenToPurchases(void Function(List<PurchaseDetails>) onUpdate) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      onUpdate,
      onError: (Object e) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  void cancelListen() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Map plan_id (basic/premium) to product id.
  String productIdForPlan(String planId) {
    if (planId == 'premium') return kProductIdPremium;
    return kProductIdBasic;
  }

  /// Start purchase flow for the given plan. Returns the ProductDetails if found.
  ProductDetails? productDetailsForPlan(String planId) {
    final id = productIdForPlan(planId);
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Launch the native purchase flow. Caller should already be listening to purchaseStream.
  Future<bool> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Purchase token / server verification data to send to backend (Android: purchase token).
  static String? getPurchaseToken(PurchaseDetails details) {
    final data = details.verificationData.serverVerificationData;
    return data.isEmpty ? null : data;
  }

  /// Send purchase token and product id to backend for verification and subscription activation.
  Future<void> verifyAndActivate({
    required String purchaseToken,
    required String productId,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      throw Exception('Not authenticated');
    }
    final res = await _client.functions.invoke(
      'verify-google-play-purchase',
      body: {
        'purchase_token': purchaseToken,
        'product_id': productId,
      },
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (res.status != 200) {
      final err = res.data?['error'] ?? res.data?.toString() ?? 'Verification failed';
      throw Exception(err.toString());
    }
  }

  /// Call when purchase was handled (after backend confirmed) so Play stops delivering it.
  Future<void> completePurchase(PurchaseDetails details) async {
    await _iap.completePurchase(details);
  }
}
