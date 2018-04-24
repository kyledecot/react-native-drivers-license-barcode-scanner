package com.kyledecot.react.android.driverslicensebarcodescanner;

import android.Manifest;
import android.app.Activity;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.graphics.Rect;
import android.os.Handler;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ThemedReactContext;
import com.manateeworks.BarcodeScanner;
import com.manateeworks.CameraManager;
import com.manateeworks.MWParser;

import java.io.IOException;

public class DriversLicenseBarcodeScanner extends SurfaceView implements SurfaceHolder.Callback {

    public static final boolean USE_MWANALYTICS = false;
    public static final boolean PDF_OPTIMIZED = false;

    private enum State {
        STOPPED, PREVIEW, DECODING
    }

    private enum OverlayMode {
        OM_IMAGE, OM_MWOVERLAY, OM_NONE
    }

    State state = State.STOPPED;

//    public Handler getHandler() {
//        return decodeHandler;
//    }

    /* Parser */
    /*
     * MWPARSER_MASK - Set the desired parser type Available options:
     * MWParser.MWP_PARSER_MASK_ISBT MWParser.MWP_PARSER_MASK_AAMVA
     * MWParser.MWP_PARSER_MASK_IUID MWParser.MWP_PARSER_MASK_HIBC
     * MWParser.MWP_PARSER_MASK_SCM MWParser.MWP_PARSER_MASK_NONE
     */
    public static final int MWPARSER_MASK = MWParser.MWP_PARSER_MASK_NONE;

    public static final int USE_RESULT_TYPE = BarcodeScanner.MWB_RESULT_TYPE_MW;

    public static final DriversLicenseBarcodeScanner.OverlayMode OVERLAY_MODE = DriversLicenseBarcodeScanner.OverlayMode.OM_MWOVERLAY;

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

    private SurfaceHolder surfaceHolder;
    private boolean surfaceChanged = false;

    private ReactApplicationContext appContext;

    public DriversLicenseBarcodeScanner(ThemedReactContext reactContext, ReactApplicationContext appContext) {
        super(reactContext);

        this.appContext = appContext;

        Log.e("KYLEDECOT", "constructed surface view instance");
    }

    private void initCamera() {
        final Activity activity = this.appContext.getCurrentActivity();

        if (activity == null) {
            Log.e("KYLEDECOT", "No Activity Yet!");
            return;
        }

        Log.e("CAMERA", "WE DID IT!");

        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            Log.e("KYLEDECOT", "NO NO NO PERMISSIONS GRANTED");

            /* WHEN TARGETING ANDROID 6 OR ABOVE, PERMISSION IS NEEDED */
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity,
                    Manifest.permission.CAMERA)) {

                new AlertDialog.Builder(activity).setMessage("You need to allow access to the Camera")
                        .setPositiveButton("OK", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                ActivityCompat.requestPermissions(activity,
                                        new String[]{Manifest.permission.CAMERA}, 12322);
                            }
                        }).setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        // onBackPressed();
                    }
                }).create().show();
            } else {
                ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.CAMERA},
                        12322);
            }
        } else {
            Log.e("KYLEDECOT", "PERMISSIONS GRANTED ALREADY!!!!");

            try {
                // Select desired camera resoloution. Not all devices
                // supports all
                // resolutions, closest available will be chosen
                // If not selected, closest match to screen resolution will
                // be
                // chosen
                // High resolutions will slow down scanning proccess on
                // slower
                // devices

                if (MAX_THREADS > 2 || PDF_OPTIMIZED) {
                    CameraManager.setDesiredPreviewSize(1280, 720);
                } else {
                    CameraManager.setDesiredPreviewSize(800, 480);
                }

                CameraManager.get().openDriver(surfaceHolder, true);

            } catch (IOException ioe) {
//                 displayFrameworkBugMessageAndExit(ioe.getMessage());
                return;
            } catch (RuntimeException e) {
                // Barcode Scanner has seen crashes in the wild of this
                // variety:
                // java.?lang.?RuntimeException: Fail to connect to camera
                // service
//                 displayFrameworkBugMessageAndExit(e.getMessage());
                return;
            }

            Log.i("preview", "start preview.");


            CameraManager.get().startPreview();
            restartPreviewAndDecode();
////                 updateFlash();
        }
    }

    private void restartPreviewAndDecode() {
        if (state == State.STOPPED) {
            state = State.PREVIEW;
            Log.i("preview", "requestPreviewFrame.");
            CameraManager.get().requestPreviewFrame(getHandler(), ID_DECODE);
            CameraManager.get().requestAutoFocus(getHandler(), ID_AUTO_FOCUS);
        }
    }

  public void onResume() {
//    getHolder().addCallback(this);


      if (hasSurface) {
          Log.i("Init Camera", "On resume");
          initCamera();
      } else if (surfaceHolder != null) {
          // Install the callback and wait for surfaceCreated() to init the
          // camera.
          surfaceHolder.addCallback(this);
      }

      //
      int registerResult = BarcodeScanner.MWBregisterSDK("umDQbMBzRwwXVuRPBtLbzcYfPd0SVfpSoq3wVebSGtw=", this.appContext.getCurrentActivity());

      switch (registerResult) {
          case BarcodeScanner.MWB_RTREG_OK:
              Log.i("MWBregisterSDK", "Registration OK");
              break;
          case BarcodeScanner.MWB_RTREG_INVALID_KEY:
              Log.e("MWBregisterSDK", "Registration Invalid Key");
              break;
          case BarcodeScanner.MWB_RTREG_INVALID_CHECKSUM:
              Log.e("MWBregisterSDK", "Registration Invalid Checksum");
              break;
          case BarcodeScanner.MWB_RTREG_INVALID_APPLICATION:
              Log.e("MWBregisterSDK", "Registration Invalid Application");
              break;
          case BarcodeScanner.MWB_RTREG_INVALID_SDK_VERSION:
              Log.e("MWBregisterSDK", "Registration Invalid SDK Version");
              break;
          case BarcodeScanner.MWB_RTREG_INVALID_KEY_VERSION:
              Log.e("MWBregisterSDK", "Registration Invalid Key Version");
              break;
          case BarcodeScanner.MWB_RTREG_INVALID_PLATFORM:
              Log.e("MWBregisterSDK", "Registration Invalid Platform");
              break;
          case BarcodeScanner.MWB_RTREG_KEY_EXPIRED:
              Log.e("MWBregisterSDK", "Registration Key Expired");
              break;
          default:
              Log.e("MWBregisterSDK", "Registration Unknown Error");
              break;
      }

      BarcodeScanner.MWBsetDirection(BarcodeScanner.MWB_SCANDIRECTION_HORIZONTAL);
      BarcodeScanner.MWBsetActiveCodes(BarcodeScanner.MWB_CODE_MASK_PDF);
      BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_PDF, RECT_LANDSCAPE_1D);
      BarcodeScanner.MWBsetLevel(2);
      BarcodeScanner.MWBsetResultType(USE_RESULT_TYPE);

      Activity activity = appContext.getCurrentActivity();

      CameraManager.init(activity);

      hasSurface = false;
      state = State.STOPPED;
  }

  public void onPause() {
      Log.e("KYLEDECOT", "onPause");
  }

  public void onDestroy() {
      Log.e("KYLEDECOT", "onDestroy");
  }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        if (!hasSurface) {
            hasSurface = true;
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        initCamera();
        surfaceChanged = true;
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        hasSurface = false;
    }
}
