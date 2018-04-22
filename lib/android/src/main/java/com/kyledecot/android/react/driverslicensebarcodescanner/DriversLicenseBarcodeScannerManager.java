package com.kyledecot.android.react.driverslicensebarcodescanner;

import com.kyledecot.react.android.driverslicensebarcodescanner.DriversLicenseBarcodeScanner;

import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.SimpleViewManager;

public class DriversLicenseBarcodeScannerManager extends SimpleViewManager<DriversLicenseBarcodeScanner> {
  public static final String REACT_CLASS = "DriversLicenseBarcodeScanner";

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  protected DriversLicenseBarcodeScanner createViewInstance(ThemedReactContext context) {
    return new DriversLicenseBarcodeScanner(context);
  }
}
