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

import com.manateeworks.BarcodeScanner;
import com.manateeworks.BarcodeScanner.MWResult;
import com.manateeworks.CameraManager;
import com.manateeworks.MWOverlay;
import com.manateeworks.MWParser;

import java.io.IOException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import static com.manateeworks.BarcodeScanner.MWB_CODE_MASK_93;
import static com.manateeworks.BarcodeScanner.MWB_PAR_ID_VERIFY_LOCATION;
import static com.manateeworks.BarcodeScanner.MWB_PAR_VALUE_VERIFY_LOCATION_ON;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.DialogInterface;
import android.content.DialogInterface.OnKeyListener;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Display;
import android.view.KeyEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.ImageView;

import com.manateeworks.BarcodeScanner;
import com.manateeworks.BarcodeScanner.MWResult;
import com.manateeworks.CameraManager;
import com.manateeworks.MWOverlay;
import com.manateeworks.MWParser;

import java.io.IOException;


public class DriversLicenseBarcodeScanner extends View {
  public static final boolean USE_MWANALYTICS = false;
  public static final boolean PDF_OPTIMIZED = false;

  /* Parser */
  /*
  * MWPARSER_MASK - Set the desired parser type Available options:
  * MWParser.MWP_PARSER_MASK_ISBT MWParser.MWP_PARSER_MASK_AAMVA
  * MWParser.MWP_PARSER_MASK_IUID MWParser.MWP_PARSER_MASK_HIBC
  * MWParser.MWP_PARSER_MASK_SCM MWParser.MWP_PARSER_MASK_NONE
  */
  public static final int MWPARSER_MASK = MWParser.MWP_PARSER_MASK_NONE;

  public static final int USE_RESULT_TYPE = BarcodeScanner.MWB_RESULT_TYPE_MW;

  public static final OverlayMode OVERLAY_MODE = OverlayMode.OM_MWOVERLAY;

  // !!! Rects are in format: x, y, width, height !!!
  public static final Rect RECT_LANDSCAPE_1D = new Rect(3, 20, 94, 60);
  public static final Rect RECT_LANDSCAPE_2D = new Rect(20, 5, 60, 90);
  public static final Rect RECT_PORTRAIT_1D = new Rect(20, 3, 60, 94);
  public static final Rect RECT_PORTRAIT_2D = new Rect(20, 5, 60, 90);
  public static final Rect RECT_FULL_1D = new Rect(3, 3, 94, 94);
  public static final Rect RECT_FULL_2D = new Rect(20, 5, 60, 90);
  public static final Rect RECT_DOTCODE = new Rect(30, 20, 40, 60);

  private static final String MSG_CAMERA_FRAMEWORK_BUG = "Sorry, the Android camera encountered a problem: ";

  public static final int ID_AUTO_FOCUS = 0x01;
  public static final int ID_DECODE = 0x02;
  public static final int ID_RESTART_PREVIEW = 0x04;
  public static final int ID_DECODE_SUCCEED = 0x08;
  public static final int ID_DECODE_FAILED = 0x10;

  private Handler decodeHandler;
  private boolean hasSurface;
  private String package_name;

  private int activeThreads = 0;
  public static int MAX_THREADS = Runtime.getRuntime().availableProcessors();

  private ImageButton zoomButton;
  private ImageButton buttonFlash;
  private ImageView imageOverlay;

  boolean flashOn = false;

  private int zoomLevel = 0;
  private int firstZoom = 150;
  private int secondZoom = 300;


  private SurfaceHolder surfaceHolder;
  private boolean surfaceChanged = false;

  public DriversLicenseBarcodeScanner(ThemedReactContext reactContext) {
    super(reactContext);

    // int registerResult = BarcodeScanner.MWBregisterSDK("NEUk2MDE1uCn4q+GyGFy8VGeeLeIcUT5dt6REiaI5lM=", this);

    this.setBackgroundColor(100);
  }
//
//   /* Analytics */
//     /*
//      * private String encResult; private String tName; private String
// 	 * analyticsTag = "TestTag";
// 	 */
//
//     private enum State {
//         STOPPED, PREVIEW, DECODING
//     }
//
    private enum OverlayMode {
        OM_IMAGE, OM_MWOVERLAY, OM_NONE
    }
//
//     State state = State.STOPPED;
//
//     public Handler getHandler() {
//         return decodeHandler;
//     }
//
//     @Override
//     public void onCreate(Bundle icicle) {
//         super.onCreate(icicle);
//     //     surfaceChanged = false;
//     //     package_name = getPackageName();
//     //
//     //     Window window = getWindow();
//     //     window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
//     //     setContentView(getResources().getIdentifier("activity_capture", "layout", package_name));
//     //     imageOverlay = (ImageView) findViewById(R.id.imageOverlay);
//     //     // register your copy of library with given key
//     //     int registerResult = BarcodeScanner.MWBregisterSDK("SDK_Key", this);
//     //
//     //     switch (registerResult) {
//     //         case BarcodeScanner.MWB_RTREG_OK:
//     //             Log.i("MWBregisterSDK", "Registration OK");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_INVALID_KEY:
//     //             Log.e("MWBregisterSDK", "Registration Invalid Key");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_INVALID_CHECKSUM:
//     //             Log.e("MWBregisterSDK", "Registration Invalid Checksum");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_INVALID_APPLICATION:
//     //             Log.e("MWBregisterSDK", "Registration Invalid Application");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_INVALID_SDK_VERSION:
//     //             Log.e("MWBregisterSDK", "Registration Invalid SDK Version");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_INVALID_KEY_VERSION:
//     //             Log.e("MWBregisterSDK", "Registration Invalid Key Version");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_INVALID_PLATFORM:
//     //             Log.e("MWBregisterSDK", "Registration Invalid Platform");
//     //             break;
//     //         case BarcodeScanner.MWB_RTREG_KEY_EXPIRED:
//     //             Log.e("MWBregisterSDK", "Registration Key Expired");
//     //             break;
//     //
//     //         default:
//     //             Log.e("MWBregisterSDK", "Registration Unknown Error");
//     //             break;
//     //     }
//     //
//     //     // choose code type or types you want to search for
//     //     if (PDF_OPTIMIZED) {
//     //         BarcodeScanner.MWBsetDirection(BarcodeScanner.MWB_SCANDIRECTION_HORIZONTAL);
//     //         BarcodeScanner.MWBsetActiveCodes(BarcodeScanner.MWB_CODE_MASK_PDF);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_PDF, RECT_LANDSCAPE_1D);
//     //     } else {
//     //         // Our sample app is configured by default to search both directions...
//     //         BarcodeScanner.MWBsetDirection(
//     //                 BarcodeScanner.MWB_SCANDIRECTION_HORIZONTAL | BarcodeScanner.MWB_SCANDIRECTION_VERTICAL);
//     //
//     //         // Our sample app is configured by default to search all supported barcodes...
//     //         // But for better performance, only activate the symbologies your application requires...
//     //         BarcodeScanner.MWBsetActiveCodes(
//     //                 BarcodeScanner.MWB_CODE_MASK_25 | BarcodeScanner.MWB_CODE_MASK_39 | BarcodeScanner.MWB_CODE_MASK_93
//     //                         | BarcodeScanner.MWB_CODE_MASK_128 | BarcodeScanner.MWB_CODE_MASK_AZTEC
//     //                         | BarcodeScanner.MWB_CODE_MASK_DM | BarcodeScanner.MWB_CODE_MASK_EANUPC
//     //                         | BarcodeScanner.MWB_CODE_MASK_PDF | BarcodeScanner.MWB_CODE_MASK_QR
//     //                         | BarcodeScanner.MWB_CODE_MASK_CODABAR | BarcodeScanner.MWB_CODE_MASK_11
//     //                         | BarcodeScanner.MWB_CODE_MASK_MAXICODE | BarcodeScanner.MWB_CODE_MASK_POSTAL
//     //                         | BarcodeScanner.MWB_CODE_MASK_MSI | BarcodeScanner.MWB_CODE_MASK_RSS);
//     //
//     //         // set the scanning rectangle based on scan direction(format in pct:
//     //         // x, y, width, height)
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_25, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_39, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_93, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_128, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_AZTEC, RECT_FULL_2D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_DM, RECT_FULL_2D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_EANUPC, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_PDF, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_QR, RECT_FULL_2D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_RSS, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_CODABAR, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_DOTCODE, RECT_DOTCODE);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_11, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_MSI, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_MAXICODE, RECT_FULL_1D);
//     //         BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_POSTAL, RECT_FULL_1D);
//     //
//     //     }
//     //
//     //     if (OVERLAY_MODE == OverlayMode.OM_IMAGE) {
//     //         imageOverlay.setVisibility(View.VISIBLE);
//     //     }
//     //
// 		// /* Analytics */
//     //     /*
//     //      * Register with given apiUser and apiKey
// 		//  */
//     //     //
//     //     // if (USE_MWANALYTICS) {
//     //     // MWBAnalytics.init(getApplicationContext(), "apiUser", "apiKey");
//     //     // }
//     //
//     //     // For better performance, set like this for PORTRAIT scanning...
//     //     // BarcodeScanner.MWBsetDirection(BarcodeScanner.MWB_SCANDIRECTION_VERTICAL);
//     //     // set the scanning rectangle based on scan direction(format in pct: x,
//     //     // y, width, height)
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_25,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_39,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_93,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_128,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_AZTEC,
//     //     // RECT_PORTRAIT_2D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_DM,
//     //     // RECT_PORTRAIT_2D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_EANUPC,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_PDF,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_QR,
//     //     // RECT_PORTRAIT_2D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_RSS,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_CODABAR,RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_DOTCODE,RECT_DOTCODE);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_11,
//     //     // RECT_PORTRAIT_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_MSI,
//     //     // RECT_PORTRAIT_1D);
//     //
//     //     // or like this for LANDSCAPE scanning - Preferred for dense or wide
//     //     // codes...
//     //     // BarcodeScanner.MWBsetDirection(BarcodeScanner.MWB_SCANDIRECTION_HORIZONTAL);
//     //     // set the scanning rectangle based on scan direction(format in pct: x,
//     //     // y, width, height)
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_25,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_39,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_93,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_128,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_AZTEC,
//     //     // RECT_LANDSCAPE_2D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_DM,
//     //     // RECT_LANDSCAPE_2D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_EANUPC,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_PDF,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_QR,
//     //     // RECT_LANDSCAPE_2D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_RSS,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_CODABAR,RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_DOTCODE,RECT_DOTCODE);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_11,
//     //     // RECT_LANDSCAPE_1D);
//     //     // BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_MSI,
//     //     // RECT_LANDSCAPE_1D);
//     //
//     //     // set decoder effort level (1 - 5)
//     //     // for live scanning scenarios, a setting between 1 to 3 will suffice
//     //     // levels 4 and 5 are typically reserved for batch scanning
//     //     BarcodeScanner.MWBsetLevel(2);
//     //     BarcodeScanner.MWBsetResultType(USE_RESULT_TYPE);
//     //
//     //     // Set minimum result length for low-protected barcode types
//     //     BarcodeScanner.MWBsetMinLength(BarcodeScanner.MWB_CODE_MASK_25, 5);
//     //     BarcodeScanner.MWBsetMinLength(BarcodeScanner.MWB_CODE_MASK_MSI, 5);
//     //     BarcodeScanner.MWBsetMinLength(BarcodeScanner.MWB_CODE_MASK_39, 5);
//     //     BarcodeScanner.MWBsetMinLength(BarcodeScanner.MWB_CODE_MASK_CODABAR, 5);
//     //     BarcodeScanner.MWBsetMinLength(BarcodeScanner.MWB_CODE_MASK_11, 5);
//     //
//     //     // Set adittional options for GS1 and ECI
//     //     // BarcodeScanner.MWBsetParam(BarcodeScanner.MWB_CODE_MASK_DM,
//     //     // BarcodeScanner.MWB_PAR_ID_ECI_MODE,
//     //     // BarcodeScanner.MWB_PAR_VALUE_ECI_ENABLED);
//     //     // BarcodeScanner.MWBsetParam(BarcodeScanner.MWB_CODE_MASK_DM,
//     //     // BarcodeScanner.MWB_PAR_ID_RESULT_PREFIX,
//     //     // BarcodeScanner.MWB_PAR_VALUE_RESULT_PREFIX_ALWAYS);
//     //     // BarcodeScanner.MWBsetParam(BarcodeScanner.MWB_CODE_MASK_128,
//     //     // BarcodeScanner.MWB_PAR_ID_RESULT_PREFIX,
//     //     // BarcodeScanner.MWB_PAR_VALUE_RESULT_PREFIX_ALWAYS);
//     //     // BarcodeScanner.MWBsetParam(BarcodeScanner.MWB_CODE_MASK_QR,
//     //     // BarcodeScanner.MWB_PAR_ID_RESULT_PREFIX,
//     //     // BarcodeScanner.MWB_PAR_VALUE_RESULT_PREFIX_ALWAYS);
//     //
//     //     // BarcodeScanner.MWBsetFlags(BarcodeScanner.MWB_CODE_MASK_EANUPC,
//     //     // BarcodeScanner.MWB_CFG_EANUPC_DISABLE_ADDON);
//     //
//     //     CameraManager.init(getApplication());
//     //
//     //     hasSurface = false;
//     //     state = State.STOPPED;
//     //     decodeHandler = new Handler(new Handler.Callback() {
//     //
//     //         @Override
//     //         public boolean handleMessage(Message msg) {
//     //             switch (msg.what) {
//     //                 case ID_DECODE:
//     //                     decode((byte[]) msg.obj, msg.arg1, msg.arg2);
//     //                     break;
//     //
//     //                 case ID_AUTO_FOCUS:
//     //                     if (state == State.PREVIEW || state == State.DECODING) {
//     //                         CameraManager.get().requestAutoFocus(decodeHandler, ID_AUTO_FOCUS);
//     //                     }
//     //                     break;
//     //                 case ID_RESTART_PREVIEW:
//     //                     restartPreviewAndDecode();
//     //                     break;
//     //                 case ID_DECODE_SUCCEED:
//     //                     state = State.STOPPED;
//     //                     handleDecode((MWResult) msg.obj);
//     //                     break;
//     //                 case ID_DECODE_FAILED:
//     //                     break;
//     //             }
//     //             return false;
//     //         }
//     //     });
//     //
//     //     zoomButton = (ImageButton) findViewById(R.id.zoomButton);
//     //     zoomButton.setOnClickListener(new OnClickListener() {
//     //         @Override
//     //         public void onClick(View v) {
//     //
//     //             zoomLevel++;
//     //             if (zoomLevel > 2) {
//     //                 zoomLevel = 0;
//     //             }
//     //
//     //             switch (zoomLevel) {
//     //                 case 0:
//     //                     CameraManager.get().setZoom(100);
//     //                     break;
//     //                 case 1:
//     //                     CameraManager.get().setZoom(firstZoom);
//     //                     break;
//     //                 case 2:
//     //                     CameraManager.get().setZoom(secondZoom);
//     //                     break;
//     //
//     //                 default:
//     //                     break;
//     //             }
//     //
//     //         }
//     //     });
//     //     buttonFlash = (ImageButton) findViewById(R.id.flashButton);
//     //     buttonFlash.setOnClickListener(new OnClickListener() {
//     //         // @TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
//     //         @Override
//     //         public void onClick(View v) {
//     //             toggleFlash();
//     //         }
//     //     });
//     }
//
//     @Override
//     protected void onResume() {
//         // super.onResume();
//         //
//         // final SurfaceView surfaceView = (SurfaceView) findViewById(
//         //         getResources().getIdentifier("preview_view", "id", package_name));
//         // surfaceHolder = surfaceView.getHolder();
//         //
//         //
//         // recycleOverlayImage();
//         // if (OVERLAY_MODE == OverlayMode.OM_MWOVERLAY) {
//         //     MWOverlay.removeOverlay();
//         //     new Handler().postDelayed(new Runnable() {
//         //         @Override
//         //         public void run() {
//         //             MWOverlay.addOverlay(DriversLicenseBarcodeScanner.this, surfaceView);
//         //         }
//         //     }, 1);
//         // }
//         //
//         // if (hasSurface) {
//         //     Log.i("Init Camera", "On resume");
//         //     initCamera();
//         // } else {
//         //     // Install the callback and wait for surfaceCreated() to init the
//         //     // camera.
//         //     surfaceHolder.addCallback(this);
//         //     surfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
//         // }
//     }
//
//     // @SuppressLint("Override")
//     // @Override
//     // public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
//     //     /* Analytics */
//     //     /*
//     //      * else if (requestCode == 12333){ if (encResult != null && tName !=
// 		//  * null){ MWBAnalytics.MWB_sendReport(encResult, tName, analyticsTag); }
// 		//  * }
// 		//  */
//     // }
//
//     @Override
//     protected void onPause() {
//         // super.onPause();
//         // stopScaner();
//     }
//
//     @Override
//     protected void onDestroy() {
//         super.onDestroy();
//         stopScaner();
//     }
//
//     private void stopScaner() {
//         // /* Stops the scanner when the activity goes in background */
//         // if (OVERLAY_MODE == OverlayMode.OM_MWOVERLAY) {
//         //     MWOverlay.removeOverlay();
//         // }
//         //
//         // imageOverlay.setImageDrawable(null);
//         //
//         // CameraManager.get().stopPreview();
//         // CameraManager.get().closeDriver();
//         // state = State.STOPPED;
//         // flashOn = false;
//         // updateFlash();
//     }
//
//     @Override
//     public void onConfigurationChanged(Configuration config) {
//
//         // Display display = ((WindowManager) getSystemService(WINDOW_SERVICE)).getDefaultDisplay();
//         // int rotation = display.getRotation();
//         //
//         // CameraManager.get().updateCameraOrientation(rotation);
//         //
//         // super.onConfigurationChanged(config);
//     }
//
//     private void toggleFlash() {
//         // flashOn = !flashOn;
//         // updateFlash();
//     }
//
//     private void updateFlash() {
//
//         // if (!CameraManager.get().isTorchAvailable()) {
//         //     buttonFlash.setVisibility(View.GONE);
//         //     return;
//         //
//         // } else {
//         //     buttonFlash.setVisibility(View.VISIBLE);
//         // }
//         //
//         // if (flashOn) {
//         //     buttonFlash.setImageResource(R.drawable.flashbuttonon);
//         // } else {
//         //     buttonFlash.setImageResource(R.drawable.flashbuttonoff);
//         // }
//         //
//         // CameraManager.get().setTorch(flashOn);
//         //
//         // buttonFlash.postInvalidate();
//
//     }
//
//     public void surfaceCreated(SurfaceHolder holder) {
//         // if (!hasSurface) {
//         //     hasSurface = true;
//         // }
//     }
//
//     public void surfaceDestroyed(SurfaceHolder holder) {
//         // hasSurface = false;
//     }
//
//     public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
//         // Log.i("Init Camera", "On Surface changed");
//         // initCamera();
//         // surfaceChanged = true;
//     }
//
//     // @Override
//     // public boolean onKeyDown(int keyCode, KeyEvent event) {
//     //     if (keyCode == KeyEvent.KEYCODE_FOCUS || keyCode == KeyEvent.KEYCODE_CAMERA) {
//     //         // Handle these events so they don't launch the Camera app
//     //         return true;
//     //     }
//     //     return super.onKeyDown(keyCode, event);
//     // }
//
//     private void decode(final byte[] data, final int width, final int height) {
//         //
//         // if (activeThreads >= MAX_THREADS || state == State.STOPPED) {
//         //     return;
//         // }
//         //
//         // new Thread(new Runnable() {
//         //     public void run() {
//         //         activeThreads++;
//         //
//         //         byte[] rawResult = BarcodeScanner.MWBscanGrayscaleImage(data, width, height);
//         //
//         //         if (state == State.STOPPED) {
//         //             activeThreads--;
//         //             return;
//         //         }
//         //
//         //         MWResult mwResult = null;
//         //
//         //         if (rawResult != null && BarcodeScanner.MWBgetResultType() == BarcodeScanner.MWB_RESULT_TYPE_MW) {
//         //
//         //             BarcodeScanner.MWResults results = new BarcodeScanner.MWResults(rawResult);
//         //
//         //             if (results.count > 0) {
//         //                 mwResult = results.getResult(0);
//         //                 rawResult = mwResult.bytes;
//         //             }
//         //
//         //         } else if (rawResult != null
//         //                 && BarcodeScanner.MWBgetResultType() == BarcodeScanner.MWB_RESULT_TYPE_RAW) {
//         //             mwResult = new MWResult();
//         //             mwResult.bytes = rawResult;
//         //             mwResult.text = rawResult.toString();
//         //             mwResult.type = BarcodeScanner.MWBgetLastType();
//         //             mwResult.bytesLength = rawResult.length;
//         //         }
//         //
//         //         if (mwResult != null) {
//         //             state = State.STOPPED;
//         //             Message message = Message.obtain(DriversLicenseBarcodeScanner.this.getHandler(), ID_DECODE_SUCCEED, mwResult);
//         //             message.arg1 = mwResult.type;
//         //             message.sendToTarget();
//         //         } else {
//         //             Message message = Message.obtain(DriversLicenseBarcodeScanner.this.getHandler(), ID_DECODE_FAILED);
//         //             message.sendToTarget();
//         //         }
//         //
//         //         activeThreads--;
//         //     }
//         // }).start();
//     }
//
//     private void restartPreviewAndDecode() {
//         // if (state == State.STOPPED) {
//         //     state = State.PREVIEW;
//         //     Log.i("preview", "requestPreviewFrame.");
//         //     CameraManager.get().requestPreviewFrame(getHandler(), ID_DECODE);
//         //     CameraManager.get().requestAutoFocus(getHandler(), ID_AUTO_FOCUS);
//         // }
//     }
//
//     public void handleDecode(MWResult result) {
//         //
//         // String typeName = result.typeName;
//         // String barcode = result.text;
//
//         /* Parser */
//         /*
//          * Parser result handler. Edit this code for custom handling of the
// 		 * parser result. Use MWParser.MWPgetJSON(MWPARSER_MASK,
// 		 * result.encryptedResult.getBytes()); to get JSON formatted result
// 		 */
// //        if (MWPARSER_MASK != MWParser.MWP_PARSER_MASK_NONE &&
// //                BarcodeScanner.MWBgetResultType() ==
// //                        BarcodeScanner.MWB_RESULT_TYPE_MW) {
// //
// //            barcode = MWParser.MWPgetFormattedText(MWPARSER_MASK,
// //                    result.encryptedResult.getBytes());
// //            if (barcode == null) {
// //                String parserMask = "";
// //
// //                switch (MWPARSER_MASK) {
// //                    case MWParser.MWP_PARSER_MASK_AAMVA:
// //                        parserMask = "AAMVA";
// //                        break;
// //                    case MWParser.MWP_PARSER_MASK_GS1:
// //                        parserMask = "GS1";
// //                        break;
// //                    case MWParser.MWP_PARSER_MASK_ISBT:
// //                        parserMask = "ISBT";
// //                        break;
// //                    case MWParser.MWP_PARSER_MASK_IUID:
// //                        parserMask = "IUID";
// //                        break;
// //                    case MWParser.MWP_PARSER_MASK_HIBC:
// //                        parserMask = "HIBC";
// //                        break;
// //                    case MWParser.MWP_PARSER_MASK_SCM:
// //                        parserMask = "SCM";
// //                        break;
// //
// //                    default:
// //                        parserMask = "unknown";
// //                        break;
// //                }
// //
// //                barcode = result.text + "\n*Not a valid " + parserMask +
// //                        " formatted barcode";
// //            }
// //
// //        }
//         /* Parser */
//
//         //
//         // if (result.locationPoints != null && CameraManager.get().
//         //
//         //         getCurrentResolution()
//         //
//         //         != null
//         //         && OVERLAY_MODE == OverlayMode.OM_MWOVERLAY)
//         //
//         // {
//         //     MWOverlay.showLocation(result.locationPoints.points, result.imageWidth, result.imageHeight);
//         // }
//         //
//         // if (result.isGS1)
//         //
//         // {
//         //     typeName += " (GS1)";
//         // }
//         //
//         // new AlertDialog.Builder(this)
//         //         .setOnDismissListener(new DialogInterface.OnDismissListener() {
//         //             @Override
//         //             public void onDismiss(DialogInterface dialog) {
//         //                 if (decodeHandler != null) {
//         //                     decodeHandler.sendEmptyMessage(ID_RESTART_PREVIEW);
//         //                 }
//         //             }
//         //         })
//         //         .setTitle(typeName)
//         //         .setMessage(barcode)
//         //         .setNegativeButton("Close", null)
//         //         .show();
//
// 		/* Analytics */
//         /*
//          * Replace "TestTag" in order to send custom tag.
// 		 */
//         /*
//          * if (USE_MWANALYTICS) { if
// 		 * (ContextCompat.checkSelfPermission(DriversLicenseBarcodeScanner.this,
// 		 * Manifest.permission.ACCESS_FINE_LOCATION) !=
// 		 * PackageManager.PERMISSION_GRANTED) { encResult =
// 		 * result.encryptedResult; tName = typeName;
// 		 *
// 		 * if
// 		 * (ActivityCompat.shouldShowRequestPermissionRationale(DriversLicenseBarcodeScanner.
// 		 * this, Manifest.permission.ACCESS_FINE_LOCATION)) {
// 		 * MWBAnalytics.MWB_sendReport(result.encryptedResult, typeName,
// 		 * analyticsTag); } else {
// 		 * ActivityCompat.requestPermissions(DriversLicenseBarcodeScanner.this, new String[]
// 		 * { Manifest.permission.ACCESS_FINE_LOCATION }, 12333); } } else { if
// 		 * (encResult != null) { encResult = null; tName = null; }
// 		 * MWBAnalytics.MWB_sendReport(result.encryptedResult, typeName,
// 		 * analyticsTag); } }
// 		 */
//     }
//
//     private void initCamera() {
//         //
//         // if (ContextCompat.checkSelfPermission(DriversLicenseBarcodeScanner.this,
//         //         Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
//         //     /* WHEN TARGETING ANDROID 6 OR ABOVE, PERMISSION IS NEEDED */
//         //     if (ActivityCompat.shouldShowRequestPermissionRationale(DriversLicenseBarcodeScanner.this,
//         //             Manifest.permission.CAMERA)) {
//         //
//         //         new AlertDialog.Builder(DriversLicenseBarcodeScanner.this).setMessage("You need to allow access to the Camera")
//         //                 .setPositiveButton("OK", new DialogInterface.OnClickListener() {
//         //                     @Override
//         //                     public void onClick(DialogInterface dialogInterface, int i) {
//         //                         ActivityCompat.requestPermissions(DriversLicenseBarcodeScanner.this,
//         //                                 new String[]{Manifest.permission.CAMERA}, 12322);
//         //                     }
//         //                 }).setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
//         //             @Override
//         //             public void onClick(DialogInterface dialogInterface, int i) {
//         //                 onBackPressed();
//         //             }
//         //         }).create().show();
//         //     } else {
//         //         ActivityCompat.requestPermissions(DriversLicenseBarcodeScanner.this, new String[]{Manifest.permission.CAMERA},
//         //                 12322);
//         //     }
//         // } else {
//         //     try {
//         //         // Select desired camera resoloution. Not all devices
//         //         // supports all
//         //         // resolutions, closest available will be chosen
//         //         // If not selected, closest match to screen resolution will
//         //         // be
//         //         // chosen
//         //         // High resolutions will slow down scanning proccess on
//         //         // slower
//         //         // devices
//         //
//         //         if (MAX_THREADS > 2 || PDF_OPTIMIZED) {
//         //             CameraManager.setDesiredPreviewSize(1280, 720);
//         //         } else {
//         //             CameraManager.setDesiredPreviewSize(800, 480);
//         //         }
//         //
//         //         CameraManager.get().openDriver(surfaceHolder,
//         //                 (getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT));
//         //
//         //         int maxZoom = CameraManager.get().getMaxZoom();
//         //         if (maxZoom < 100) {
//         //             zoomButton.setVisibility(View.GONE);
//         //         } else {
//         //             zoomButton.setVisibility(View.VISIBLE);
//         //             if (maxZoom < 300) {
//         //                 secondZoom = maxZoom;
//         //                 firstZoom = (maxZoom - 100) / 2 + 100;
//         //
//         //             }
//         //
//         //         }
//         //     } catch (IOException ioe) {
//         //         displayFrameworkBugMessageAndExit(ioe.getMessage());
//         //         return;
//         //     } catch (RuntimeException e) {
//         //         // Barcode Scanner has seen crashes in the wild of this
//         //         // variety:
//         //         // java.?lang.?RuntimeException: Fail to connect to camera
//         //         // service
//         //         displayFrameworkBugMessageAndExit(e.getMessage());
//         //         return;
//         //     }
//         //
//         //     Log.i("preview", "start preview.");
//         //
//         //     flashOn = false;
//         //
//         //     new Handler().postDelayed(new Runnable() {
//         //
//         //         @Override
//         //         public void run() {
//         //             switch (zoomLevel) {
//         //                 case 0:
//         //                     CameraManager.get().setZoom(100);
//         //                     break;
//         //                 case 1:
//         //                     CameraManager.get().setZoom(firstZoom);
//         //                     break;
//         //                 case 2:
//         //                     CameraManager.get().setZoom(secondZoom);
//         //                     break;
//         //
//         //                 default:
//         //                     break;
//         //             }
//         //
//         //         }
//         //     }, 300);
//         //     CameraManager.get().startPreview();
//         //     restartPreviewAndDecode();
//         //     updateFlash();
//         // }
//     }
//
//     private void displayFrameworkBugMessageAndExit(String message) {
//         // AlertDialog.Builder builder = new AlertDialog.Builder(this);
//         // builder.setTitle(getResources().getIdentifier("app_name", "string", package_name));
//         // builder.setMessage(MSG_CAMERA_FRAMEWORK_BUG + message);
//         // builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
//         //     public void onClick(DialogInterface dialogInterface, int i) {
//         //         finish();
//         //     }
//         // });
//         // builder.show();
//     }
//     protected void recycleOverlayImage() {
//         // if (OVERLAY_MODE == OverlayMode.OM_IMAGE) {
//         //     ((ImageView)imageOverlay.findViewById(R.id.imageOverlay)).setImageDrawable(getResources().getDrawable(R.drawable.overlay));
//         // } else {
//         //
//         //     Drawable imageDrawable = imageOverlay.getDrawable();
//         //     imageOverlay.setImageDrawable(null);
//         //
//         //     if (imageDrawable!=null && imageDrawable instanceof BitmapDrawable) {
//         //         BitmapDrawable bitmapDrawable = ((BitmapDrawable) imageDrawable);
//         //
//         //         if (!bitmapDrawable.getBitmap().isRecycled()) {
//         //             bitmapDrawable.getBitmap().recycle();
//         //         }
//         //     }
//         // }
//     }
}
