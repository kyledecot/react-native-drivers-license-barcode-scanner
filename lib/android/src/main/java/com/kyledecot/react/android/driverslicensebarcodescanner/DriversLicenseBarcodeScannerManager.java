package com.kyledecot.react.android.driverslicensebarcodescanner;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.SimpleViewManager;

public class DriversLicenseBarcodeScannerManager extends SimpleViewManager<DriversLicenseBarcodeScanner> implements LifecycleEventListener {
    private DriversLicenseBarcodeScanner view;

    @Override
    public String getName() {
        return "DriversLicenseBarcodeScanner";
    }

    @Override
    protected DriversLicenseBarcodeScanner createViewInstance(ThemedReactContext context) {
        context.addLifecycleEventListener(this);

        view = new DriversLicenseBarcodeScanner(context);

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
