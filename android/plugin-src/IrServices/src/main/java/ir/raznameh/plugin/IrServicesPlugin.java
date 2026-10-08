package ir.raznameh.plugin;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;

import com.android.vending.billing.IInAppBillingService;

import ir.tapsell.mediation.Tapsell;
import ir.tapsell.mediation.ad.AdStateListener;
import ir.tapsell.mediation.ad.request.RequestResultListener;
import ir.tapsell.mediation.ad.show.AdShowCompletionState;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

import android.widget.Toast;

/**
 * IrServices: Cafe Bazaar + Myket In-App Billing v3 bridge for Godot 4.
 * Binds to the store's billing service by package name (both stores expose
 * the standard com.android.vending.billing.IInAppBillingService AIDL).
 *
 * GDScript usage:
 *   var p = Engine.get_singleton("IrServices")
 *   p.initialize("com.farsitel.bazaar")   # or "ir.mservices.market"
 *   p.billing_ready.connect(func(ok): ...)
 *   p.purchase("coin_50")
 *   p.purchase_done.connect(func(json): ...)   # json: {code, token, sku, sig}
 *   p.purchase_failed.connect(func(msg): ...)
 *   p.consume(token)
 */
public class IrServicesPlugin extends GodotPlugin {

    private static final int API_VERSION = 3;
    private static final int REQUEST_PURCHASE = 77101;

    private Godot godot;
    private Context ctx;
    private IInAppBillingService billing;
    private ServiceConnection conn;
    private String vendorPkg = "";
    private String pendingSku = "";
    private boolean binding = false;

    public IrServicesPlugin(Godot godot) {
        super(godot);
        this.godot = godot;
        this.ctx = godot.getContext();
    }

    @Override
    public String getPluginName() {
        return "IrServices";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("billing_ready", Boolean.class));
        signals.add(new SignalInfo("purchase_done", String.class));
        signals.add(new SignalInfo("purchase_failed", String.class));
        signals.add(new SignalInfo("ad_rewarded", Integer.class));
        signals.add(new SignalInfo("ad_failed", String.class));
        return signals;
    }

    @UsedByGodot
    public boolean is_bound() {
        return billing != null;
    }

    @UsedByGodot
    public void initialize(String vendorPackage) {
        if (billing != null || binding) {
            return;
        }
        vendorPkg = vendorPackage;
        try {
            Intent intent = new Intent("com.android.vending.billing.InAppBillingService.BIND");
            intent.setPackage(vendorPkg);
            conn = new ServiceConnection() {
                @Override
                public void onServiceConnected(ComponentName name, IBinder service) {
                    billing = IInAppBillingService.Stub.asInterface(service);
                    emitSignal("billing_ready", true);
                }

                @Override
                public void onServiceDisconnected(ComponentName name) {
                    billing = null;
                    emitSignal("billing_ready", false);
                }
            };
            binding = true;
            boolean ok = ctx.bindService(intent, conn, Context.BIND_AUTO_CREATE);
            if (!ok) {
                binding = false;
                emitSignal("billing_ready", false);
            }
        } catch (Exception e) {
            binding = false;
            emitSignal("billing_ready", false);
        }
    }

    @UsedByGodot
    public void purchase(String sku) {
        final Activity activity = godot.getActivity();
        if (billing == null || activity == null) {
            emitSignal("purchase_failed", "\u0627\u062a\u0635\u0627\u0644 \u0628\u0647 \u0641\u0631\u0648\u0634\u06af\u0627\u0647 \u0628\u0631\u0642\u0631\u0627\u0631 \u0646\u06cc\u0633\u062a"); // "اتصال به فروشگاه برقرار نیست"
            return;
        }
        pendingSku = sku;
        try {
            Bundle buy = billing.getBuyIntent(API_VERSION, ctx.getPackageName(), sku, "inapp", "raznameh");
            int response = getResponseCode(buy);
            if (response != 0 || !buy.containsKey("BUY_INTENT")) {
                emitSignal("purchase_failed", "RESPONSE_" + response);
                return;
            }
            PendingIntent pi = (PendingIntent) buy.getParcelable("BUY_INTENT");
            activity.startIntentSenderForResult(pi.getIntentSender(), REQUEST_PURCHASE,
                    new Intent(), 0, 0, 0);
        } catch (RemoteException | IntentSender.SendIntentException e) {
            emitSignal("purchase_failed", "EXC:" + e.getMessage());
        } catch (IllegalArgumentException e) {
            emitSignal("purchase_failed", "ARG:" + e.getMessage());
        }
    }

    @UsedByGodot
    public void consume(final String token) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (billing != null && token != null && !token.isEmpty()) {
                        billing.consumePurchase(API_VERSION, ctx.getPackageName(), token);
                    }
                } catch (RemoteException ignored) {
                }
            }
        }).start();
    }

    @UsedByGodot
    public void toast(final String message) {
        final Activity activity = godot.getActivity();
        if (activity != null) {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(activity, message, Toast.LENGTH_SHORT).show();
                }
            });
        }
    }

    // ------------------------------------------------------ Tapsell rewarded
    // Flow: requestRewardedAd(zone) -> onSuccess(adId) -> showRewardedAd(adId)
    // The Tapsell APPLICATION_KEY is baked into the merged manifest
    // (meta-data ir.tapsell.mediation.APPLICATION_KEY) by the app gradle
    // template; `appKey` from GDScript is kept for future runtime use.

    private volatile String pendingAdId = null;
    private volatile boolean adRewarded = false;

    @UsedByGodot
    public void show_rewarded_ad(final String appKey, final String zoneId) {
        final Activity activity = godot.getActivity();
        if (activity == null) {
            emitSignal("ad_failed", "\u062e\u0637\u0627\u06cc \u062f\u0627\u062e\u0644\u06cc"); // "خطای داخلی"
            return;
        }
        if (zoneId == null || zoneId.trim().isEmpty()) {
            emitSignal("ad_failed", "\u0648\u0627\u062d\u062f \u062a\u0628\u0644\u06cc\u063a \u0646\u0627\u0645\u0639\u062a\u0628\u0631"); // "واحد تبلیغ نامعتبر"
            return;
        }
        adRewarded = false;
        try {
            Tapsell.requestRewardedAd(zoneId.trim(), new RequestResultListener() {
                @Override
                public void onSuccess(final String adId) {
                    pendingAdId = adId;
                    try {
                        Tapsell.showRewardedAd(adId, activity, new AdStateListener.Rewarded() {
                            @Override
                            public void onAdClosed(AdShowCompletionState state) {
                                pendingAdId = null;
                                if (!adRewarded) {
                                    String st = "UNKNOWN";
                                    try { st = state != null ? state.name() : st; } catch (Throwable ignored) {}
                                    emitSignal("ad_failed", "CLOSED_" + st);
                                }
                            }

                            @Override
                            public void onAdImpression() {
                            }

                            @Override
                            public void onAdClicked() {
                            }

                            @Override
                            public void onRewarded() {
                                adRewarded = true;
                                emitSignal("ad_rewarded", Integer.valueOf(0));
                            }

                            @Override
                            public void onAdFailed(String message) {
                                pendingAdId = null;
                                if (!adRewarded) {
                                    emitSignal("ad_failed", message == null ? "AD_FAILED" : message);
                                }
                            }
                        });
                    } catch (Throwable t) {
                        pendingAdId = null;
                        if (!adRewarded) {
                            emitSignal("ad_failed", "SHOW:" + t.getMessage());
                        }
                    }
                }

                @Override
                public void onFailure(final String message) {
                    pendingAdId = null;
                    emitSignal("ad_failed", message == null ? "REQUEST_FAILED" : message);
                }
            });
        } catch (Throwable t) {
            emitSignal("ad_failed", "TAPSELL:" + t.getMessage());
        }
    }

    @UsedByGodot
    public boolean tapsell_busy() {
        return pendingAdId != null;
    }

    // ------------------------------------------------------ notifications

    /** Creates the notification channel (no-op below Android 8). */
    @UsedByGodot
    public void ensure_notif_channel() {
        NotifHelper.ensureChannel(ctx);
    }

    /** Schedules 2 daily notifications; msgs joined with \u0001 separator. */
    @UsedByGodot
    public void schedule_daily_notifs(final int h1, final int m1, final int h2, final int m2, final String msgs) {
        NotifHelper.schedule(ctx, h1, m1, h2, m2, msgs);
    }

    /** Cancels alarms + shown notifications and disables future ones. */
    @UsedByGodot
    public void cancel_notifs() {
        NotifHelper.cancel(ctx);
    }

    /** Requests POST_NOTIFICATIONS runtime permission (Android 13+). */
    @UsedByGodot
    public void request_notif_permission() {
        final Activity activity = godot.getActivity();
        if (activity == null) return;
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            activity.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 77177);
        }
    }

    // Called by the engine on the main thread when a started activity returns.
    public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQUEST_PURCHASE) {
            super.onMainActivityResult(requestCode, resultCode, data);
            return;
        }
        int response = getResponseBundleCode(data);
        if (response == 0 && data != null && data.hasExtra("INAPP_PURCHASE_DATA")) {
            String purchaseData = data.getStringExtra("INAPP_PURCHASE_DATA");
            String signature = data.hasExtra("INAPP_DATA_SIGNATURE")
                    ? data.getStringExtra("INAPP_DATA_SIGNATURE") : "";
            String token = extractToken(purchaseData);
            Bundle ack = new Bundle();
            ack.putString("purchase", purchaseData);
            emitSignal("purchase_done", "{\"code\":0,\"token\":\"" + safe(token)
                    + "\",\"sku\":\"" + safe(pendingSku) + "\",\"sig\":\"" + safe(signature) + "\"}");
        } else {
            emitSignal("purchase_failed", "RESPONSE_" + response);
        }
        pendingSku = "";
    }

    private static String safe(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String extractToken(String purchaseDataJson) {
        // purchaseData is a JSON string like {"orderId":"..","purchaseToken":"..","productId":".."}
        try {
            org.json.JSONObject obj = new org.json.JSONObject(purchaseDataJson);
            return obj.optString("purchaseToken", "");
        } catch (Exception e) {
            return "";
        }
    }

    private static int getResponseCode(Bundle b) {
        if (b == null) {
            return -2;
        }
        return b.getInt("RESPONSE_CODE", -1);
    }

    private static int getResponseBundleCode(Intent data) {
        if (data == null) {
            return -3;
        }
        return data.getIntExtra("RESPONSE_CODE", -1);
    }
}
