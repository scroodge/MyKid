import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Product IDs in Google Play Console. Must match subscription ids created in Play Console.
const String kProductIdBasic = 'mykid_basic';
const String kProductIdPremium = 'mykid_premium';

/// Android application id for Play Store deep links. Must match android/app/build.gradle applicationId.
const String kGooglePlayPackageName = 'com.mykidapp.mykid_app';

/// Base64-encoded RSA public key from Play Console → Monetize → Monetization setup (License).
/// Google asks to include it in the app executable; paste the key here with all spaces removed.
/// Leave empty if you don't use license verification (e.g. subscriptions-only via Billing API).
const String kGooglePlayLicensePublicKeyBase64 =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApIB8nUhWWnpa79KAhbQ9SAwLnTxwpDOOA451wcXMKS2QkSBaIHbEXq9pdQHzYiWSvSkxW84f0VQbooLuapYCI2HsHLHEjB8wOoiknjwNNoyAAgRhw7PqfE/B5mxffyhVubDCKTxnxc4jOompR4tUXrJSV6NsGhk+uJ3srHJ2vrUZIi2N0x23DImf6rcGoA5jLRjtcvvEnNl7VJ+KFQMExvFQERglqhZmCpQlM4K74DTrsOgEzWrBcUWUcWulbmuaf8B9gKdi37NJ1TWAUBQyBXrT820qE9vjfWIvHm2OOrqC5h29pAqEH86hummYTJlEXPGZUMOwMIO8KV+y6kfa5QIDAQAB';

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
    if (!_available) {
      print('[GooglePlay] ❌ Billing not available (isAvailable=false).');
      print('[GooglePlay] Troubleshooting:');
      print('[GooglePlay]   1. Make sure Google Play Services is installed');
      print('[GooglePlay]   2. App must be installed from Play Store (not adb install)');
      print('[GooglePlay]   3. App must be uploaded to Play Console (at least Internal testing)');
      return false;
    }
    print('[GooglePlay] ✅ Billing is available, querying products...');
    await _loadProducts();
    final hasProducts = _products.isNotEmpty;
    if (!hasProducts) {
      print('[GooglePlay] ❌ No products found after query.');
      print('[GooglePlay] Troubleshooting:');
      print('[GooglePlay]   1. Check Play Console → Monetize → Subscriptions');
      print('[GooglePlay]   2. Subscriptions "mykid_basic" and "mykid_premium" must be ACTIVE (not Draft)');
      print('[GooglePlay]   3. Each subscription must have at least one ACTIVE base plan');
      print('[GooglePlay]   4. App must be uploaded to Play Console (at least Internal testing)');
      print('[GooglePlay]   5. App must be installed from Play Store (not adb install)');
      print('[GooglePlay]   6. Wait 2-3 hours after creating/activating subscriptions (Google caches)');
      print('[GooglePlay]   7. Check package name matches: com.mykidapp.mykid_app');
    } else {
      print('[GooglePlay] ✅ Initialized successfully with ${_products.length} products: ${_products.map((p) => p.id).join(", ")}');
    }
    return hasProducts;
  }

  Future<void> _loadProducts() async {
    const ids = {kProductIdBasic, kProductIdPremium};
    print('[GooglePlay] Querying products: ${ids.join(", ")}');
    final response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      print('[GooglePlay] ❌ Products NOT FOUND in Play Console: ${response.notFoundIDs.join(", ")}');
      print('[GooglePlay] ✅ Found products: ${response.productDetails.map((p) => p.id).join(", ")}');
      print('[GooglePlay] Action: Go to Play Console → Monetize → Subscriptions → Create subscriptions with IDs: ${response.notFoundIDs.join(", ")}');
      print('[GooglePlay] Make sure subscriptions are ACTIVE (not Draft) and app is uploaded to at least Internal testing.');
    } else {
      print('[GooglePlay] ✅ All products found: ${response.productDetails.map((p) => p.id).join(", ")}');
    }
    if (response.error != null) {
      print('[GooglePlay] ⚠️ Query error: ${response.error}');
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

  /// Deep link to Google Play subscription management (cancel, resubscribe, pause).
  /// See: https://developer.android.com/google/play/billing/subscriptions#pause
  static String subscriptionManagementUrl(String productId) {
    return 'https://play.google.com/store/account/subscriptions?sku=${Uri.encodeComponent(productId)}&package=${Uri.encodeComponent(kGooglePlayPackageName)}';
  }
}
