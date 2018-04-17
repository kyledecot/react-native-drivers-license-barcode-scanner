package com.kyledecot.android.react.driverslicensebarcodescanner.example;

import android.app.Application;

import com.kyledecot.android.react.driverslicensebarcodescanner.DriversLicenseBarcodeScannerPackage;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.soloader.SoLoader;

import java.util.Arrays;
import java.util.List;

public class ExampleApplication extends Application implements ReactApplication {
  private final ReactNativeHost reactNativeHost = new ReactNativeHost(this) {
    @Override public boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected String getJSMainModuleName() {
      return "example/index";
    }

    @Override protected List<ReactPackage> getPackages() {
      return Arrays.asList(
          new MainReactPackage(),
          new DriversLicenseBarcodeScannerPackage());
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
    return reactNativeHost;
  }

  @Override
  public void onCreate() {
    super.onCreate();
    SoLoader.init(this, /* native exopackage */ false);
  }
}
