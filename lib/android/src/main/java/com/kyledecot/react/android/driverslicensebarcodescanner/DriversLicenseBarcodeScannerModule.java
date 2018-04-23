package com.kyledecot.react.android.driverslicensebarcodescanner;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

public class DriversLicenseBarcodeScannerModule extends ReactContextBaseJavaModule {
  public DriversLicenseBarcodeScannerModule(ReactApplicationContext reactContext) {
      super(reactContext);
    }

  @Override
  public String getName() {
    return "DriversLicenseBarcodeScanner";
  }
}
