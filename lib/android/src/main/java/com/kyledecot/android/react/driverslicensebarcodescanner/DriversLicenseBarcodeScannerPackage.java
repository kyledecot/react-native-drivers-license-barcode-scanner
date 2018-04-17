package com.kyledecot.android.react.driverslicensebarcodescanner;

import android.app.Activity;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class DriversLicenseBarcodeScannerPackage implements ReactPackage {
  public DriversLicenseBarcodeScannerPackage(Activity activity) {
  } // backwards compatibility

  public DriversLicenseBarcodeScannerPackage() {
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    return Arrays.<ViewManager>asList();
  }

  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    return Arrays.<NativeModule>asList(new DriversLicenseBarcodeScannerModule(reactContext));
  }

  // Deprecated RN 0.47
  public List<Class<? extends JavaScriptModule>> createJSModules() {
    return Collections.emptyList();
  }
}
