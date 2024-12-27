import 'package:flutter/material.dart';
import 'package:q_common_utils/l.dart';
import 'package:q_common_utils/ui_utils.dart';
import 'package:q_in_app_purchase/q_in_app_purchase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      scaffoldMessengerKey: snackbarKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late InAppPurchaseRemoveAdsManager inAppPurchaseRemoveAdsManager =
      InAppPurchaseRemoveAdsManager(productRemoveAdsId: "removeads");

  @override
  void dispose() {
    inAppPurchaseRemoveAdsManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
                onPressed: () async {
                  inAppPurchaseRemoveAdsManager.restoringPreviousPurchases(context);
                  // InAppPurchaseRemoveAdsManager(() {
                  //   // Complete callback
                  //   L.d("restorePurchasesIfHasPending Complete");
                  // }, productRemoveAdsId: "removeads")
                  //     .restorePurchasesIfHasPending(context);
                },
                child: const Text('Restore')),
            FilledButton(
                onPressed: () async {
                  inAppPurchaseRemoveAdsManager.buyRemoveAdsProduct(context);
                  inAppPurchaseRemoveAdsManager.callbackCompletePurchase = (){
                    UiUtils.showSnackBar("Buy TEst 1 Success");
                  };
                  // InAppPurchaseRemoveAdsManager(() {
                  //   L.d("buyNonConsumable Complete");
                  //   testIAPFuctuon();
                  //
                  //   // Complete callback
                  // }, productRemoveAdsId: "test1")
                  //     .buyNonConsumable(context);
                },
                child: const Text('Buy Remove ADS')),
            FilledButton(
                onPressed: () async {
                  inAppPurchaseRemoveAdsManager.buyProduct(context, "test1", false);
                  inAppPurchaseRemoveAdsManager.callbackCompletePurchase = (){
                    UiUtils.showSnackBar("Buy TEst 1 Success");
                  };
                  // InAppPurchaseRemoveAdsManager(() {
                  //   L.d("buyNonConsumable Complete");
                  //   testIAPFuctuon();
                  //
                  //   // Complete callback
                  // }, productRemoveAdsId: "test1")
                  //     .buyNonConsumable(context);
                },
                child: const Text('Buy Consume 100 Gold')),
            FilledButton(
                onPressed: () async {
                  // InAppPurchaseRemoveAdsManager(() {
                  //   // Complete callback
                  //   L.d("buyNonConsumable Complete");
                  // }, productRemoveAdsId: "vip_user")
                  //     .buyNonConsumable(context);
                },
                child: const Text('Buy Vipuser')),
          ],
        ),
      ),
    );
  }
}
