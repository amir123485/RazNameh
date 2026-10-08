package ir.raznameh.plugin;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Re-arms daily notification alarms after device reboot. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null) return;
        String a = intent.getAction();
        if (a != null && (a.equals(Intent.ACTION_BOOT_COMPLETED)
                || a.equals("android.intent.action.QUICKBOOT_POWERON")
                || a.equals("android.intent.action.MY_PACKAGE_REPLACED"))) {
            NotifHelper.rearm(context);
        }
    }
}
