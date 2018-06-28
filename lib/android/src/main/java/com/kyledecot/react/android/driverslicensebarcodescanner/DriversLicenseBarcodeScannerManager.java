package com.kyledecot.react.android.driverslicensebarcodescanner;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.annotations.ReactProp;

import android.app.Activity;
import android.util.Log;
import android.view.View;
import android.content.BroadcastReceiver;
import android.content.IntentFilter;
import android.content.Context;
import android.content.Intent;

import java.util.Map;

import javax.annotation.Nullable;

public class DriversLicenseBarcodeScannerManager extends SimpleViewManager<DriversLicenseBarcodeScanner> implements LifecycleEventListener {
    final BroadcastReceiver receiver;
    private static final String BCAST_CONFIGCHANGED = "android.intent.action.CONFIGURATION_CHANGED";

    private DriversLicenseBarcodeScanner view;
    private ReactApplicationContext appContext;

    public DriversLicenseBarcodeScannerManager(final ReactApplicationContext appContext) {
        super();

        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                int orientation = getCurrentActivity().getResources().getConfiguration().orientation;
 Log.e("ORIENATION", String.format("%i", orientation));
//                view.setOrientation(90);
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

    @ReactProp(name = "torch")
    public void setTorch(DriversLicenseBarcodeScanner view, boolean torch) {
        view.setTorch(torch);
    }

    @Override
    public void onHostResume() {
        IntentFilter filter = new IntentFilter();
        filter.addAction(BCAST_CONFIGCHANGED);
        getCurrentActivity().registerReceiver(receiver, filter);

        view.onResume();
    }

    @Override
    public void onHostPause() {
        getCurrentActivity().unregisterReceiver(receiver);

        view.onPause();
    }

    @Override
    public void onHostDestroy() {
        view.onDestroy();
    }

    public Activity getCurrentActivity() {
        return appContext.getCurrentActivity();
    }
}
