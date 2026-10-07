package com.android.vending.billing;

import android.os.Bundle;

// Standard In-App Billing v3 interface. Both Cafe Bazaar (com.farsitel.bazaar)
// and Myket (ir.mservices.market) implement this exact AIDL interface.
interface IInAppBillingService {
    int isBillingSupported(int apiVersion, String packageName, String type);
    Bundle getSkuDetails(int apiVersion, String packageName, String type, in Bundle skusBundle);
    Bundle getBuyIntent(int apiVersion, String packageName, String sku, String type, String developerPayload);
    Bundle getPurchases(int apiVersion, String packageName, String type, String continuationToken);
    int consumePurchase(int apiVersion, String packageName, String purchaseToken);
}
