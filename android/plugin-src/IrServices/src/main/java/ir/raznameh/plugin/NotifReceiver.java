package ir.raznameh.plugin;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Receives the two daily alarm broadcasts and shows the rotating notification. */
public class NotifReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null) return;
        int slot = intent.getIntExtra("slot", NotifHelper.REQ_NOTIF_1);
        NotifHelper.fire(context, slot);
    }
}
