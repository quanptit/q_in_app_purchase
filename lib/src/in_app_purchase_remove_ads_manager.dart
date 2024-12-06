import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:q_common_utils/l.dart';
import 'package:q_common_utils/preferences_utils.dart';
import 'dart:async';

import 'package:q_common_utils/ui_utils.dart';

/// Chỉ sử dụng cho app mà chỉ có mua gói remove ads.
class InAppPurchaseRemoveAdsManager {
  late VoidCallback _callbackCompletePurchase;
  late String productRemoveAdsId;

  //region singlton
  static InAppPurchaseRemoveAdsManager _singleton = InAppPurchaseRemoveAdsManager._internal();
  InAppPurchaseRemoveAdsManager._internal();

  factory InAppPurchaseRemoveAdsManager(VoidCallback callbackCompletePurchase, {required String productRemoveAdsId}) {
    _singleton._callbackCompletePurchase = callbackCompletePurchase;
    _singleton.productRemoveAdsId = productRemoveAdsId;
    return _singleton;
  }
  //endregion

  _completePurchase() {
    _StateStoreUtils.setFlagRemoveAds();
    _StateStoreUtils.removeFlagPending();
    _callbackCompletePurchase();
  }

  void buyNonConsumable(BuildContext context) async {
    if (await _StateStoreUtils.hasRemoveAds()) {
      _completePurchase();
      return;
    }
    if (await _showDialogNotAvailable(context)) {
      _StateStoreUtils.removeFlagPending();
      return;
    }

    _subscribe();

    L.d('Querying the store with queryProductDetails()');
    final response = await _getInstance().queryProductDetails({productRemoveAdsId});
    if (response.error != null) {
      UiUtils.showSnackBar('There was an error when making the purchase: '
          '${response.error}');
      return;
    }

    if (response.productDetails.length != 1) {
      L.d(
        'Products in response: '
        '${response.productDetails.map((e) => '${e.id}: ${e.title}, ').join()}',
      );
      UiUtils.showSnackBar('There was an error when making the purchase');
      return;
    }
    final productDetails = response.productDetails.single;
    L.d('Making the purchase');
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      final success = await _getInstance().buyNonConsumable(purchaseParam: purchaseParam);
      L.d('buyNonConsumable() request was sent with success: $success');
    } catch (e) {
      L.d('Problem with calling inAppPurchaseInstance.buyNonConsumable(): '
          '$e');
    }
  }

  /// gọi khi mở ứng dụng, sẽ tự check để gọi bên trong hay không
  Future<void> restorePurchasesIfHasPending(BuildContext context, {bool defaultPendingState = false}) async {
    if (!await _StateStoreUtils.needCheckPending(defaultPendingState)) return;
    if (await _StateStoreUtils.hasRemoveAds()) return;
    if (!await _getInstance().isAvailable()) {
      _StateStoreUtils.removeFlagPending();
      return;
    }
    // if (await _showDialogNotAvailable(context)) {
    //   _StateStoreUtils.removeFlagPending();
    //   return;
    // }

    L.d('========> restorePurchasesIfHasPending call');

    _subscribe();

    try {
      await _getInstance().restorePurchases();
    } catch (e) {
      L.d('Could not restore in-app purchases: $e');
    }
    L.d('In-app purchases restored');
  }

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  InAppPurchase _getInstance() {
    return InAppPurchase.instance;
  }

  /// Khi mua hay restore lại, kết quả sẽ trả về qua purchaseStream. nên cần phải lắng nghe nó để nhận kết quả.
  /// Hàm này thực hiện nhiệm vụ đó.
  void _subscribe() {
    _subscription?.cancel();
    _subscription = _getInstance().purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      L.d("onDone, _subscription cancel");
      _subscription?.cancel();
    }, onError: (dynamic error) {
      L.d('Error occurred on the purchaseStream: $error');
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    bool isEmpty = true;

    for (final purchaseDetails in purchaseDetailsList) {
      L.d('New PurchaseDetails instance received: '
          'productID=${purchaseDetails.productID}, '
          'status=${purchaseDetails.status}, '
          'purchaseID=${purchaseDetails.purchaseID}, '
          'error=${purchaseDetails.error}, '
          'pendingCompletePurchase=${purchaseDetails.pendingCompletePurchase}');

      if (purchaseDetails.productID != productRemoveAdsId) {
        L.d("The handling of the product with id "
            "'${purchaseDetails.productID}' is not implemented.");
        continue;
      }

      isEmpty = false;
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _StateStoreUtils.setFlagPending();
          break;
        case PurchaseStatus.purchased:
          _completePurchase();
          break;
        case PurchaseStatus.restored:
          if (purchaseDetails.pendingCompletePurchase) {
            // đang pending complete
            _StateStoreUtils.setFlagPending();
          } else {
            _completePurchase();
          }
          break;
        case PurchaseStatus.error:
          L.d('Error with purchase: ${purchaseDetails.error}');
          _StateStoreUtils.removeFlagPending();
          break;
        case PurchaseStatus.canceled:
          L.d('Purchase Cancel');
          _StateStoreUtils.removeFlagPending();
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        // Confirm purchase back to the store.
        await _getInstance().completePurchase(purchaseDetails);
      }
    }
    if (isEmpty) {
      _StateStoreUtils.removeFlagPending();
      return;
    }
  }

  Future<bool> _showDialogNotAvailable(BuildContext context) async {
    try {
      if (!await _getInstance().isAvailable()) {
        UiUtils.showDialogInfo(context, content: "In App Purchase not available on this device!", title: "ERROR");
        return true;
      }
    } catch (err) {
      L.e(err);
    }
    return false;
  }

  static Future<bool> hasRemoveAds() {
    return _StateStoreUtils.hasRemoveAds();
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// - Khi nhận được product được đánh dấu là pending => sẽ thêm vào list
/// Khi restore: Nếu là first restore.
class _StateStoreUtils {
  //region pending manager
  static const String _FLAG_PENDING = "FLAG_PENDING";

  /// khi lần đầu mở ứng dụng, chưa check bao giờ thì flag mặc định là true
  static Future<bool> needCheckPending(bool defaultPendingState) async {
    bool flagCheckPending = await PreferencesUtils.getBool(_FLAG_PENDING, defaultValue: defaultPendingState);
    return flagCheckPending;
  }
  //endregion

  static Future<bool> hasRemoveAds() {
    return PreferencesUtils.getBool("REMOVE_ADS", defaultValue: false);
  }

  static void setFlagRemoveAds() {
    L.d("setFlagRemoveAds");
    PreferencesUtils.saveBool("REMOVE_ADS", true);
  }

  static void setFlagPending() {
    L.d("setFlagPending");
    PreferencesUtils.saveBool(_FLAG_PENDING, true);
  }

  static void removeFlagPending() {
    L.d("removeFlagPending");
    PreferencesUtils.saveBool(_FLAG_PENDING, false);
  }
}
