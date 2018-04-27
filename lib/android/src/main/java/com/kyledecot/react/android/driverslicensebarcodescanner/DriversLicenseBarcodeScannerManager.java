package com.kyledecot.react.android.driverslicensebarcodescanner;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import android.app.Activity;
import android.util.Log;
import android.view.View;
import android.content.BroadcastReceiver;
import android.content.IntentFilter;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import com.facebook.react.bridge.Arguments;

import java.util.Map;

import javax.annotation.Nullable;

public class DriversLicenseBarcodeScannerManager extends SimpleViewManager<DriversLicenseBarcodeScanner> implements LifecycleEventListener {
    final BroadcastReceiver receiver;

    private DriversLicenseBarcodeScanner view;
    private ReactApplicationContext appContext;

    public DriversLicenseBarcodeScannerManager(ReactApplicationContext appContext) {
        super();

        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
//                Configuration newConfig = intent.getParcelableExtra("newConfig");
//                Log.d("receiver", String.valueOf(newConfig.orientation));
//
//                String orientationValue = newConfig.orientation == 1 ? "PORTRAIT" : "LANDSCAPE";
//
////                WritableMap params = Arguments.createMap();
////                params.putString("orientation", orientationValue);
////                if (ctx.hasActiveCatalystInstance()) {
////                    ctx
////                            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
////                            .emit("orientationDidChange", params);
////                }
            }
        };


        this.appContext = appContext;

    }

    @Override
    public String getName() {
        return "DriversLicenseBarcodeScanner";
    }

    @Override
    protected DriversLicenseBarcodeScanner createViewInstance(ThemedReactContext context) {
        context.addLifecycleEventListener(this);

        view = new DriversLicenseBarcodeScanner(context, this.appContext, this);



        return view;
    }

    @Override
    public void receiveCommand(DriversLicenseBarcodeScanner view, int commandId, @Nullable ReadableArray args) {
        Log.e("FOOBAR", "COMMAND RECEIVED!!!!");
    }

    @Override
    @Nullable
    public Map getExportedCustomDirectEventTypeConstants() {
        Map<String, Map<String, String>> map = MapBuilder.of(
            "onSuccess", MapBuilder.of("registrationName", "onSuccess"),
            "onError", MapBuilder.of("registrationName", "onError")
        );

        return map;
    }

    void pushEvent(ThemedReactContext context, View view, String name, WritableMap data) {
        context.getJSModule(RCTEventEmitter.class)
                .receiveEvent(view.getId(), name, data);
    }

    @ReactProp(name = "license")
    public void setLicense(DriversLicenseBarcodeScanner view, String license) {
        view.setLicense(license);
    }

    @ReactProp(name = "flash")
    public void setFlash(DriversLicenseBarcodeScanner view, boolean flash) {
        view.setFlash(flash);
    }

    @Override
    public void onHostResume() {
        final Activity activity = appContext.getCurrentActivity();

        activity.registerReceiver(receiver, new IntentFilter("onConfigurationChanged"));

        view.onResume();
    }

    @Override
    public void onHostPause() {
        final Activity activity = appContext.getCurrentActivity();

        activity.unregisterReceiver(receiver);

        view.onPause();
    }

    @Override
    public void onHostDestroy() {
        view.onDestroy();
    }
}
