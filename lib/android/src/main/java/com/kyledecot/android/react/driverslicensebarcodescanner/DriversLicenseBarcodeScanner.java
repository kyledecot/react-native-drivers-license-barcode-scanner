package com.kyledecot.react.android.driverslicensebarcodescanner;

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
import com.facebook.react.uimanager.SimpleViewManager;

import java.util.Map;
import java.util.Arrays;

import javax.annotation.Nullable;

public class DriversLicenseBarcodeScanner extends View {
  public DriversLicenseBarcodeScanner(ThemedReactContext reactContext) {
    super(reactContext);

    this.setBackgroundColor(100);
  }
}
