import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

extension StudiaryUserPresentation on supabase.User {
  String? get displayName {
    final metadata = userMetadata;
    final value = metadata?['full_name'] ?? metadata?['name'];
    return value?.toString();
  }

  String? get photoURL {
    final value = userMetadata?['avatar_url'] ?? userMetadata?['picture'];
    return value?.toString();
  }
}

class AuthService {
  AuthService._();

  static final client = supabase.Supabase.instance.client;
  static final google = GoogleSignIn.instance;
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static Future<void> initializeGoogle() async {
    await google.initialize(
      serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
    );
  }

  static supabase.User? get currentUser => client.auth.currentUser;

  static Stream<supabase.User?> get changes => client.auth.onAuthStateChange
      .map((state) => state.session?.user)
      .distinct((previous, current) => previous?.id == current?.id);

  static Future<void> signInWithGoogle() async {
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const supabase.AuthException(
        'Google no devolvió un token de acceso.',
        code: 'missing-google-token',
      );
    }
    await client.auth.signInWithIdToken(
      provider: supabase.OAuthProvider.google,
      idToken: idToken,
    );
  }

  static Future<void> signInWithEmail(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> createWithEmail(String email, String password) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    if (response.session == null) {
      throw const supabase.AuthException(
        'Cuenta creada. Revisa tu correo para confirmar el acceso.',
        code: 'email-not-confirmed',
      );
    }
  }

  static Future<void> signOut() async {
    await Future.wait([client.auth.signOut(), google.signOut()]);
  }
}

class CloudSnapshot {
  CloudSnapshot(this.data, this.revision, {this.saved = true});
  final Map<String, dynamic> data;
  final String? revision;
  final bool saved;
}

class CloudSyncService {
  CloudSyncService._();

  static final client = supabase.Supabase.instance.client;
  static const storageBucket = 'note-files';

  static Future<CloudSnapshot> loadSnapshot(supabase.User user) async {
    final row = await client
        .from('studiary_data')
        .select('data,updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
    return CloudSnapshot(
      Map<String, dynamic>.from((row?['data'] as Map?) ?? {}),
      row?['updated_at']?.toString(),
    );
  }

  static Future<CloudSnapshot> saveSnapshot(
    Map<String, dynamic> data,
    String? revision,
  ) async {
    final raw =
        await client.rpc(
              'save_studiary_snapshot',
              params: {'p_data': data, 'p_revision': revision},
            )
            as Map;
    return CloudSnapshot(
      Map<String, dynamic>.from(raw['data'] as Map),
      raw['revision']?.toString(),
      saved: raw['saved'] == true,
    );
  }

  static Future<Map<String, dynamic>?> load(supabase.User user) async {
    final row = await client
        .from('studiary_data')
        .select('data')
        .eq('user_id', user.id)
        .maybeSingle();
    final raw = row?['data'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static Future<void> save(
    supabase.User user,
    Map<String, dynamic> data,
  ) async {
    await client.from('studiary_data').upsert({
      'user_id': user.id,
      'data': data,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  static Future<void> deleteUserData(supabase.User user) async {
    await client.from('studiary_data').delete().eq('user_id', user.id);
  }

  static Future<String> uploadNoteFile({
    required supabase.User user,
    required String noteId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'users/${user.id}/notes/$noteId/$safeName';
    await client.storage
        .from(storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: supabase.FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
    return path;
  }

  static Future<String> createSignedUrl(String filePath) async {
    return client.storage.from(storageBucket).createSignedUrl(filePath, 3600);
  }

  static Future<void> deleteNoteFile(
    String filePath, {
    bool swallowErrors = true,
  }) async {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return;
    }
    try {
      await client.storage.from(storageBucket).remove([filePath]);
    } catch (error) {
      debugPrint('No se pudo eliminar el adjunto: $error');
      if (!swallowErrors) rethrow;
    }
  }

  static Future<void> deleteAccount() async {
    await client.functions.invoke('delete-account');
  }
}

class MonetizationService {
  MonetizationService._();

  static const bannerId = 'ca-app-pub-4170445456641284/8347543629';
  static const testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitialId = 'ca-app-pub-4170445456641284/6898730586';
  static const testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const premiumProductId = 'studiary_premium_lifetime';
  static const premiumIds = {premiumProductId};
  static const legacyPremiumIds = {
    'studiary_premium_monthly',
    'studiary_premium_yearly',
  };
  static const entitlementIds = {...premiumIds, ...legacyPremiumIds};

  static bool _canRequestAds = false;
  static final adConsent = ValueNotifier(false);
  static const testAds = bool.fromEnvironment('USE_TEST_ADS');

  static bool get canRequestAds => _canRequestAds;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    final consentInformation = ConsentInformation.instance;
    final update = Completer<void>();
    consentInformation.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!update.isCompleted) update.complete();
      },
      (_) {
        // A cached consent decision can still allow ads when the network
        // request cannot be refreshed.
        if (!update.isCompleted) update.complete();
      },
    );
    await update.future.timeout(const Duration(seconds: 15), onTimeout: () {});

    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    _canRequestAds = await consentInformation.canRequestAds();
    if (_canRequestAds) {
      await MobileAds.instance.initialize();
    }
    adConsent.value = _canRequestAds;
  }

  static Future<void> showPrivacyOptions() async {
    final requirement = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    if (requirement == PrivacyOptionsRequirementStatus.required) {
      await ConsentForm.showPrivacyOptionsForm((_) {});
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      adConsent.value = _canRequestAds;
    }
  }

  static BannerAd createBanner({
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
  }) {
    final ad = BannerAd(
      adUnitId: kReleaseMode && !testAds ? bannerId : testBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
    ad.load();
    return ad;
  }

  static Future<void> showInterstitial() async {
    if (interstitialId.isEmpty || !_canRequestAds) return;
    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: kReleaseMode && !testAds ? interstitialId : testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }
}

class PremiumService extends ChangeNotifier {
  PremiumService({required this.onPremiumChanged}) {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) {
        _handling = _handling
            .catchError((Object _) {})
            .then((_) => _handlePurchases(purchases));
      },
      onError: (Object _) {
        message = 'No se pudo consultar Google Play. Vuelve a intentarlo.';
        _notify();
      },
    );
  }

  final void Function(bool) onPremiumChanged;
  final Set<String> productIds = MonetizationService.premiumIds;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _handling = Future.value();
  Future<void>? _loadingTask;
  List<ProductDetails> products = [];
  bool storeAvailable = false,
      loading = false,
      pending = false,
      verificationReady = false;
  bool _disposed = false;
  String? message;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<Map> _server(Map<String, dynamic> body) async {
    final response = await AuthService.client.functions
        .invoke('verify-play-purchase', body: body)
        .timeout(const Duration(seconds: 25));
    if (response.data is! Map) throw StateError('Verification unavailable');
    return response.data as Map;
  }

  Future<void> refreshEntitlement() async {
    final uid = AuthService.currentUser?.id;
    if (uid == null) return;
    try {
      final result = await _server({'action': 'check'});
      if (uid != AuthService.currentUser?.id || _disposed) return;
      verificationReady = result['ready'] == true;
      if (result['premium'] is bool) {
        onPremiumChanged(result['premium'] as bool);
      }
      message = null;
    } catch (_) {
      verificationReady = false;
      message =
          'La verificación de Premium no está disponible. No se iniciará ningún cobro.';
    }
    _notify();
  }

  Future<void> loadProducts() async {
    if (_loadingTask != null) return _loadingTask;
    _loadingTask = _load();
    try {
      await _loadingTask;
    } finally {
      _loadingTask = null;
    }
  }

  Future<void> _load() async {
    loading = true;
    _notify();
    try {
      await refreshEntitlement();
      storeAvailable = await InAppPurchase.instance.isAvailable();
      if (!storeAvailable) {
        products = [];
        return;
      }
      final response = await InAppPurchase.instance.queryProductDetails(
        productIds,
      );
      products =
          response.productDetails
              .where((product) => productIds.contains(product.id))
              .toList()
            ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      if (response.error != null || products.isEmpty) {
        message ??=
            'No se encontró el plan. Comprueba la cuenta de Google Play y vuelve a intentarlo.';
      }
    } catch (_) {
      message = 'Google Play no está disponible. Comprueba tu conexión.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (pending) return;
    await refreshEntitlement();
    if (!verificationReady ||
        !productIds.contains(product.id) ||
        AuthService.currentUser == null) {
      throw StateError('Purchase verification unavailable');
    }
    pending = true;
    message = 'Esperando confirmación de Google Play…';
    _notify();
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: AuthService.currentUser!.id,
        ),
      );
      if (!started) {
        pending = false;
        message = 'La compra no se ha iniciado.';
        _notify();
      }
    } catch (_) {
      pending = false;
      _notify();
      rethrow;
    }
  }

  Future<void> restore() async {
    await refreshEntitlement();
    await InAppPurchase.instance.restorePurchases(
      applicationUserName: AuthService.currentUser?.id,
    );
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    final uid = AuthService.currentUser?.id;
    if (uid == null) return;
    for (final purchase in purchases) {
      if (!MonetizationService.entitlementIds.contains(purchase.productID)) {
        continue;
      }
      if (purchase.status == PurchaseStatus.pending) {
        pending = true;
        message =
            'Pago pendiente. Premium se activará cuando Google Play lo confirme.';
        _notify();
        continue;
      }
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        pending = false;
        message = purchase.status == PurchaseStatus.canceled
            ? 'Compra cancelada.'
            : 'No se pudo completar la compra.';
        _notify();
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      try {
        final result = await _server({
          'action': 'verify',
          'productId': purchase.productID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
        });
        if (uid != AuthService.currentUser?.id || _disposed) return;
        if (result['verified'] != true) {
          pending = false;
          message =
              'Esta compra no está activa o pertenece a otra cuenta de Studiary.';
          _notify();
          continue;
        }
        onPremiumChanged(true);
        // Only acknowledge a verified purchase. Never consume the lifetime SKU.
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        pending = false;
        message = 'Premium activado y vinculado a tu cuenta.';
        _notify();
      } catch (_) {
        pending = false;
        message =
            'No se pudo validar la compra. Conéctate y pulsa Restaurar compras para reintentarlo.';
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
