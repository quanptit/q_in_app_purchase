import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:q_common_utils/index.dart';

import 'package:q_common_utils/index.dart';
import 'package:q_in_app_purchase/src/objs.dart';
import 'dart:async';

import 'package:q_in_app_purchase/src/q_inapp_purchase_manager.dart';

/// Chỉ sử dụng cho app mà chỉ có mua gói remove ads.
class InAppPurchaseRemoveAdsManager {
  QInappPurchaseManager? _qInappPurchaseManager;
  final String productRemoveAdsId;
  VoidCallback? _callbackCompletePurchase;

  set callbackCompletePurchase(VoidCallback value) {
    _callbackCompletePurchase = value;
  }

  InAppPurchaseRemoveAdsManager({required this.productRemoveAdsId});

  QInappPurchaseManager getQInappPurchaseManager() {
    if (_qInappPurchaseManager == null) {
      _qInappPurchaseManager = QInappPurchaseManager();
      _qInappPurchaseManager?.setCallback(QInappPurchaseCallback(successPurchase: successPurchase,
      errorPurchase: errorPurchase));
    }
    return _qInappPurchaseManager!;
  }
  void successPurchaseProductRemoveAds(){
    setFlagRemoveAds();
    UiUtils.showSnackBar(LanguagesUtils.getString("success", "Success"));
  }

  void successPurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.productID == productRemoveAdsId) {
      // Remove Ads
      successPurchaseProductRemoveAds();
      _callbackCompletePurchase?.call();
    }
  }

  void errorPurchase(PurchaseDetails purchaseDetails) {
    var isHasItemRemoveAds = purchaseDetails.error?.message.contains("itemAlreadyOwned");
    if (isHasItemRemoveAds==true) {
      successPurchaseProductRemoveAds();
      return;
    }
    L.d("errorPurchase: ${purchaseDetails}");
    UiUtils.showSnackBar(LanguagesUtils.getString("has_error", "Has error occurred"));
  }

  void restoringPreviousPurchases(BuildContext context) async {
    if (await getQInappPurchaseManager().showDialogIfNotAvailable(context)) return;
    return getQInappPurchaseManager().restoringPreviousPurchases();
  }

  void buyRemoveAdsProduct(BuildContext context) async {
    if (await getQInappPurchaseManager().showDialogIfNotAvailable(context)) return;
    getQInappPurchaseManager().buyProduct(productRemoveAdsId, true);
  }

  void buyProduct(BuildContext context, String productId, bool isNonConsumable) async {
    if (await getQInappPurchaseManager().showDialogIfNotAvailable(context)) return;
    getQInappPurchaseManager().buyProduct(productId, isNonConsumable);
  }

  void dispose() {
    _qInappPurchaseManager?.dispose();
  }

  static Future<bool> hasRemoveAds() {
    return PreferencesUtils.getBool("REMOVE_ADS", defaultValue: false);
  }

  static void setFlagRemoveAds() {
    L.d("setFlagRemoveAds");
    PreferencesUtils.saveBool("REMOVE_ADS", true);
  }
}
