package com.kyledecot.android.react.driverslicensebarcodescanner;

import android.view.View;

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

import java.util.Map;

import javax.annotation.Nullable;

public class DriversLicenseBarcodeScannerManager extends ViewGroupManager<DriversLicenseBarcodeScanner> {
  private final ReactApplicationContext appContext;

  @Override
  protected DriversLicenseBarcodeScanner createViewInstance(ThemedReactContext context) {
    return new DriversLicenseBarcodeScanner(context, this.appContext);
  }
}
