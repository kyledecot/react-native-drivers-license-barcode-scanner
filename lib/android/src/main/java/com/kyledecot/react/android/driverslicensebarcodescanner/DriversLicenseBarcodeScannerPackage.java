package com.kyledecot.react.android.driverslicensebarcodescanner;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.List;
import java.util.Arrays;

public class DriversLicenseBarcodeScannerPackage implements ReactPackage {
  @Override
   public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
     return Arrays.<ViewManager>asList(
       new DriversLicenseBarcodeScannerManager()
     );
   }

   @Override
   public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
     return Arrays.<NativeModule>asList(
      new DriversLicenseBarcodeScannerModule(reactContext)
     );
   }
}
