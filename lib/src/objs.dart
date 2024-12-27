import 'package:in_app_purchase/in_app_purchase.dart';

class QInappPurchaseCallback {
  void Function(PurchaseDetails purchaseDetails)? pendingPurchase;
  void Function(PurchaseDetails purchaseDetails)? errorPurchase;
  void Function(PurchaseDetails purchaseDetails) successPurchase;

  QInappPurchaseCallback({required this.successPurchase, this.pendingPurchase, this.errorPurchase});
}
