import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:q_common_utils/index.dart';

import 'objs.dart';

class QInappPurchaseManager {
  QInappPurchaseCallback? qinappPurchaseCallback;
  StreamSubscription<List<PurchaseDetails>>? _purchaseStream;

  //Sigleton
  static late final QInappPurchaseManager _instance = QInappPurchaseManager._internal();

  QInappPurchaseManager._internal();

  factory QInappPurchaseManager() {
    return _instance;
  }

  void setCallback(QInappPurchaseCallback? qinappPurchaseCallback) {
    _instance.qinappPurchaseCallback = qinappPurchaseCallback;
  }

  Future<bool> isAvailablePurchaseService() async {
    return InAppPurchase.instance.isAvailable();
  }

  /// return true if show dialog
  Future<bool> showDialogIfNotAvailable(BuildContext context) async {
    try {
      if (!await InAppPurchase.instance.isAvailable()) {
        UiUtils.showDialogInfo(context, content: "In App Purchase not available on this device!", title: "ERROR");
        return true;
      }
    } catch (err) {
      L.e(err);
    }
    return false;
  }

  void buyProduct(String productId, bool isNonConsumable) async {
    _listenInAppPurchaseStream();
    var productDetails = await _getProductForBuy(productId);
    if (productDetails != null) {
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      L.d('Making the purchase ${isNonConsumable ? "NonConsumable" : "Consumable"} id: ${purchaseParam.productDetails.id}');
      if (isNonConsumable)
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      else
        await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  /// Cac product da mua, se duoc tai ve, thuc hien cac event nhu mua binh thuong
  void restoringPreviousPurchases() async {
    _listenInAppPurchaseStream();
    await InAppPurchase.instance.restorePurchases();
  }

  /// Lay product dang  sale tuong ung tren store.
  Future<ProductDetails?> _getProductForBuy(String productId) async {
    L.d('_getProductForBuy: $productId');
    final response = await InAppPurchase.instance.queryProductDetails({productId});
    if (response.error != null) {
      UiUtils.showSnackBar('There was an error when making the purchase: '
          '${response.error}');
      return null;
    }

    if (response.productDetails.length != 1) {
      L.d(
        'Products in response: '
        '${response.productDetails.map((e) => '${e.id}: ${e.title}, ').join()}',
      );
      UiUtils.showSnackBar('There was an error when making the purchase');
      return null;
    }
    return response.productDetails.single;
  }

  // All Event listen in here
  void _listenInAppPurchaseStream() {
    _purchaseStream?.cancel();
    _purchaseStream = InAppPurchase.instance.purchaseStream.listen((purchaseDetailsList) {
      _purchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      L.d("onDone, _subscription cancel");
      _purchaseStream?.cancel();
    }, onError: (dynamic error) {
      L.e('Error occurred on the purchaseStream: $error');
      _purchaseStream?.cancel();
    });
  }

  Future<void> _purchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      L.d('New PurchaseDetails instance received: '
          'productID=${purchaseDetails.productID}, '
          'status=${purchaseDetails.status}, '
          'purchaseID=${purchaseDetails.purchaseID}, '
          'error=${purchaseDetails.error}, '
          'pendingCompletePurchase=${purchaseDetails.pendingCompletePurchase}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (qinappPurchaseCallback?.pendingPurchase != null) {
          qinappPurchaseCallback?.pendingPurchase?.call(purchaseDetails);
        } else {
          UiUtils.showSnackBar("Pending");
        }
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          L.d('Error with purchase: ${purchaseDetails.error}');
          if (qinappPurchaseCallback?.errorPurchase != null) {
            qinappPurchaseCallback?.errorPurchase?.call(purchaseDetails);
          } else {
            UiUtils.showSnackBar('Error with purchase: ${purchaseDetails.error}');
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          L.d("successPurchase ${purchaseDetails.productID}");
          qinappPurchaseCallback?.successPurchase.call(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void dispose() {
    try {
      _purchaseStream?.cancel();
      qinappPurchaseCallback = null;
    } on Exception catch (e) {
      L.e(e);
    }
  }
}
