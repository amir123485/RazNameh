package ir.raznameh.plugin;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;

/**
 * NotifHelper: schedules 2 daily local notifications for RazNameh with
 * non-repeating rotating messages (persisted index + message pool).
 */
public final class NotifHelper {

    static final String CHANNEL_ID = "raznameh_daily";
    static final String PREFS = "raznameh_notif";
    static final int REQ_ALARM_1 = 78101;
    static final int REQ_ALARM_2 = 78102;
    static final int REQ_NOTIF_1 = 78201;
    static final int REQ_NOTIF_2 = 78202;

    private NotifHelper() {
    }

    static SharedPreferences prefs(Context ctx) {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public static void ensureChannel(Context ctx) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) return;
            NotificationChannel ch = new NotificationChannel(CHANNEL_ID,
                    "\u0627\u0639\u0644\u0627\u0646\u200c\u0647\u0627\u06cc \u0631\u0648\u0632\u0627\u0646\u0647", // "اعلان‌های روزانه"
                    NotificationManager.IMPORTANCE_DEFAULT);
            ch.setDescription("\u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u06cc \u0631\u0648\u0632\u0627\u0646\u0647\u0654 \u0641\u0627\u0644 \u0648 \u0633\u06a9\u0647"); // daily fortune & coin reminders
            ch.setShowBadge(true);
            nm.createNotificationChannel(ch);
        }
    }

    /** Slots joined payload: "h1,m1,h2,m2" + messages joined by \u0001. */
    public static void schedule(Context ctx, int h1, int m1, int h2, int m2, String joined) {
        SharedPreferences p = prefs(ctx);
        p.edit().putInt("h1", h1).putInt("m1", m1).putInt("h2", h2).putInt("m2", m2)
                .putString("msgs", joined == null ? "" : joined)
                .putBoolean("enabled", true).apply();
        armSlot(ctx, REQ_ALARM_1, h1, m1);
        armSlot(ctx, REQ_ALARM_2, h2, m2);
    }

    public static void cancel(Context ctx) {
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am != null) {
            am.cancel(pendingBroadcast(ctx, REQ_ALARM_1));
            am.cancel(pendingBroadcast(ctx, REQ_ALARM_2));
        }
        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) nm.cancelAll();
        prefs(ctx).edit().putBoolean("enabled", false).apply();
    }

    /** Arms a repeating daily alarm for one slot (h:m). */
    static void armSlot(Context ctx, int reqCode, int hour, int minute) {
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am == null) return;
        long at = nextOccurrence(hour, minute);
        PendingIntent pi = pendingBroadcast(ctx, reqCode);
        try {
            am.cancel(pi);
            if (Build.VERSION.SDK_INT >= 23) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi);
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, at, pi);
            }
        } catch (SecurityException ignored) {
        } catch (Exception ignored) {
        }
    }

    /** Re-arm both slots from prefs (used on BOOT_COMPLETED). */
    public static void rearm(Context ctx) {
        SharedPreferences p = prefs(ctx);
        if (!p.getBoolean("enabled", false)) return;
        armSlot(ctx, REQ_ALARM_1, p.getInt("h1", 11), p.getInt("m1", 0));
        armSlot(ctx, REQ_ALARM_2, p.getInt("h2", 21), p.getInt("m2", 0));
    }

    /** Fired by NotifReceiver: pick next rotating message and show it, then re-arm tomorrow. */
    public static void fire(Context ctx, int reqCode) {
        SharedPreferences p = prefs(ctx);
        if (!p.getBoolean("enabled", false)) return;
        String joined = p.getString("msgs", "");
        if (joined == null || joined.isEmpty()) return;
        String[] msgs = joined.split("\u0001");
        if (msgs.length == 0) return;
        int idx = p.getInt("idx", 0);
        String msg = msgs[idx % msgs.length].trim();
        if (msg.isEmpty()) msg = msgs[0].trim();
        p.edit().putInt("idx", (idx + 1) % Math.max(1, msgs.length)).apply();
        show(ctx, msg);
        // schedule the next day's occurrence for this slot
        if (reqCode == REQ_NOTIF_1) {
            armSlot(ctx, REQ_ALARM_1, p.getInt("h1", 11), p.getInt("m1", 0));
        } else if (reqCode == REQ_NOTIF_2) {
            armSlot(ctx, REQ_ALARM_2, p.getInt("h2", 21), p.getInt("m2", 0));
        }
    }

    static void show(Context ctx, String msg) {
        ensureChannel(ctx);
        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;
        Intent launch = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        PendingIntent content = null;
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
            content = PendingIntent.getActivity(ctx, REQ_NOTIF_1 + 10, launch, flags);
        }
        Notification.Builder b;
        if (Build.VERSION.SDK_INT >= 26) {
            b = new Notification.Builder(ctx, CHANNEL_ID);
        } else {
            b = new Notification.Builder(ctx);
        }
        b.setSmallIcon(ctx.getApplicationInfo().icon)
                .setContentTitle("\u0631\u0627\u0632\u0646\u0627\u0645\u0647 \u2726") // "رازنامه ✦"
                .setContentText(msg)
                .setStyle(new Notification.BigTextStyle().bigText(msg))
                .setAutoCancel(true)
                .setOnlyAlertOnce(true);
        if (content != null) b.setContentIntent(content);
        try {
            nm.notify(REQ_NOTIF_1, b.build());
        } catch (SecurityException ignored) {
            // POST_NOTIFICATIONS not granted on Android 13+
        } catch (Exception ignored) {
        }
    }

    static PendingIntent pendingBroadcast(Context ctx, int reqCode) {
        Intent i = new Intent(ctx, NotifReceiver.class);
        i.setAction("ir.raznameh.NOTIF_FIRE");
        i.putExtra("slot", reqCode);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
        return PendingIntent.getBroadcast(ctx, reqCode, i, flags);
    }

    static long nextOccurrence(int hour, int minute) {
        java.util.Calendar cal = java.util.Calendar.getInstance();
        long now = cal.getTimeInMillis();
        cal.set(java.util.Calendar.HOUR_OF_DAY, hour);
        cal.set(java.util.Calendar.MINUTE, minute);
        cal.set(java.util.Calendar.SECOND, 0);
        cal.set(java.util.Calendar.MILLISECOND, 0);
        if (cal.getTimeInMillis() <= now + 30_000) {
            cal.add(java.util.Calendar.DAY_OF_YEAR, 1);
        }
        return cal.getTimeInMillis();
    }
}
