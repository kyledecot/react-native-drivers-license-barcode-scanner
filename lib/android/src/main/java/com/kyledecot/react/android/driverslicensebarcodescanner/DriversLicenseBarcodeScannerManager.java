package com.kyledecot.react.android.driverslicensebarcodescanner;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.SimpleViewManager;

public class DriversLicenseBarcodeScannerManager extends SimpleViewManager<DriversLicenseBarcodeScanner> implements LifecycleEventListener {
    private DriversLicenseBarcodeScanner view;
    private ReactApplicationContext appContext;

    public DriversLicenseBarcodeScannerManager(ReactApplicationContext appContext) {
        super();

        this.appContext = appContext;
    }

    @Override
    public String getName() {
        return "DriversLicenseBarcodeScanner";
    }

    @Override
    protected DriversLicenseBarcodeScanner createViewInstance(ThemedReactContext context) {
        context.addLifecycleEventListener(this);

        view = new DriversLicenseBarcodeScanner(context, this.appContext);

        return view;
    }

    @Override
    public void onHostResume() {
        view.onResume();
    }

    @Override
    public void onHostPause() {
        view.onPause();
    }

    @Override
    public void onHostDestroy() {
        view.onDestroy();
    }
}
