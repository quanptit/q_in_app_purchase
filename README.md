Hiện tại đang hỗ trợ cứng chỉ cho mua item Remove ADS.
Chú ý hiện tại test cho ứng dụng từ vựng tiếng anh - tienichviet. account quanptit410@gmail.com.
account khác không test được, phải release / sanbox test mới test được
### Cách sử dụng

`bool hasRemoveAds = await InAppPurchaseRemoveAdsManager.hasRemoveAds();`

### Cài đặt, tạo đối tượng
'InAppPurchaseRemoveAdsManager': chỉ xử lý cho REmove Ads. ứng dụng có nhu cầu thêm thì viết các manager tương tự
```

class _MyHomePageState extends State<MyHomePage> {
  late InAppPurchaseRemoveAdsManager inAppPurchaseRemoveAdsManager =
      InAppPurchaseRemoveAdsManager(productRemoveAdsId: "removeads");

  @override
  void dispose() {
    inAppPurchaseRemoveAdsManager.dispose();
    super.dispose();
  }

```


**Xử lý item đã mua trước đó, VD như gỡ app cài lại ...**
move Ads Action
```
 inAppPurchaseRemoveAdsManager.restoringPreviousPurchases(context);
```

### thực hiện mua item remove Ads
```
inAppPurchaseRemoveAdsManager.buyRemoveAdsProduct(context);
                  inAppPurchaseRemoveAdsManager.callbackCompletePurchase = (){
                   // Update UI remove ads
                  };
```