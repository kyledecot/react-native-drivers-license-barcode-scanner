package com.kyledecot.android.react.driverslicensebarcodescanner;

import com.kyledecot.react.android.driverslicensebarcodescanner.DriversLicenseBarcodeScanner;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.LayoutShadowNode;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.uimanager.SimpleViewManager;
import android.util.Log;

import java.util.Map;
import java.util.Arrays;

import javax.annotation.Nullable;

public class DriversLicenseBarcodeScannerManager extends SimpleViewManager<DriversLicenseBarcodeScanner> {
  public static final String REACT_CLASS = "DriversLicenseBarcodeScanner";

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  // @Override
  // public void onCreate(Bundle icicle) {
  //     super.onCreate(icicle);
  //
  //   Log.i("KYLEDECOT", "onCreate overridden!");
  // }

  @Override
  protected DriversLicenseBarcodeScanner createViewInstance(ThemedReactContext context) {
    return new DriversLicenseBarcodeScanner(context);
  }
}
