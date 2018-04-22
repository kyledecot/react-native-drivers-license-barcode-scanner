package com.kyledecot.android.react.driverslicensebarcodescanner;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Map;
import java.util.HashMap;

public class DriversLicenseBarcodeScannerModule extends ReactContextBaseJavaModule {
  public DriversLicenseBarcodeScannerModule(ReactApplicationContext reactContext) {
      super(reactContext);
    }

  @Override
  public String getName() {
    return "DriversLicenseBarcodeScanner";
  }
}
