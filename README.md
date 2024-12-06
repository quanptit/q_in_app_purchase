Hiện tại đang hỗ trợ cứng chỉ cho mua item Remove ADS
### Cách sử dụng

`bool hasRemoveAds = await InAppPurchaseRemoveAdsManager.hasRemoveAds();`

**Thực hiện các item đang mua mà chưa được xử lý. Thường gọi ở screen đầu tiên của ứng dụng**
```
@override
  void initState() {
    super.initState();
    AdsManager adsManager = context.read<AdsManager>();
    Future.delayed(
      const Duration(seconds: 3),
      () => InAppPurchaseRemoveAdsManager(() {
        adsManager.setRemoveAds();
      }, productRemoveAdsId: KeysRef.productRemoveAdsId)
          .restorePurchasesIfHasPending(context),
    );
  }
```

### Remove Ads Action
```
void btnRemoveAdsClick(BuildContext context) {
    L.d("btnRemoveAdsClick");
    // PreferencesUtils.saveBool("REMOVE_ADS", true);//TODOs
    AdsManager adsManager = context.read<AdsManager>();
    InAppPurchaseRemoveAdsManager(() {
      adsManager.setRemoveAds();
      UiUtils.showSnackBar(S.current.success);
    }, productRemoveAdsId: KeysRef.productRemoveAdsId)
        .buyNonConsumable(context);
  }
```