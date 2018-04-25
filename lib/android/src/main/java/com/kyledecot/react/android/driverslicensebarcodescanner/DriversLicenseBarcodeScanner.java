package com.kyledecot.react.android.driverslicensebarcodescanner;

import android.Manifest;
import android.app.Activity;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Message;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import com.manateeworks.BarcodeScanner;
import com.manateeworks.CameraManager;
import com.manateeworks.BarcodeScanner.MWResult;
import com.manateeworks.MWOverlay;

import java.io.IOException;

public class DriversLicenseBarcodeScanner extends SurfaceView implements SurfaceHolder.Callback {
    private enum State {
        STOPPED, PREVIEW, DECODING
    }

    State state = State.STOPPED;

    public static final int USE_RESULT_TYPE = BarcodeScanner.MWB_RESULT_TYPE_MW;

    // !!! Rects are in format: x, y, width, height !!!
    public static final Rect RECT_LANDSCAPE_1D = new Rect(3, 20, 94, 60);
    public static final Rect RECT_LANDSCAPE_2D = new Rect(20, 5, 60, 90);
    public static final Rect RECT_PORTRAIT_1D = new Rect(20, 3, 60, 94);
    public static final Rect RECT_PORTRAIT_2D = new Rect(20, 5, 60, 90);
    public static final Rect RECT_FULL_1D = new Rect(3, 3, 94, 94);
    public static final Rect RECT_FULL_2D = new Rect(20, 5, 60, 90);
    public static final Rect RECT_DOTCODE = new Rect(30, 20, 40, 60);

    public static final int ID_AUTO_FOCUS = 0x01;
    public static final int ID_DECODE = 0x02;
    public static final int ID_RESTART_PREVIEW = 0x04;
    public static final int ID_DECODE_SUCCEED = 0x08;
    public static final int ID_DECODE_FAILED = 0x10;

    private Handler decodeHandler;
    private boolean hasSurface;

    public static final OverlayMode OVERLAY_MODE = OverlayMode.OM_MWOVERLAY;

    private enum OverlayMode {
        OM_IMAGE, OM_MWOVERLAY, OM_NONE
    }

    private int activeThreads = 0;
    public static int MAX_THREADS = Runtime.getRuntime().availableProcessors();

    private ReactApplicationContext appContext;
    private ThemedReactContext context;
    private DriversLicenseBarcodeScannerManager manager;

    public DriversLicenseBarcodeScanner(ThemedReactContext reactContext, ReactApplicationContext appContext, DriversLicenseBarcodeScannerManager manager) {
        super(reactContext);

        this.context = reactContext;
        this.appContext = appContext;
        this.manager = manager;

        BarcodeScanner.MWBsetDirection(BarcodeScanner.MWB_SCANDIRECTION_HORIZONTAL);
        BarcodeScanner.MWBsetActiveCodes(BarcodeScanner.MWB_CODE_MASK_PDF);
        BarcodeScanner.MWBsetScanningRect(BarcodeScanner.MWB_CODE_MASK_PDF, RECT_LANDSCAPE_1D);
        BarcodeScanner.MWBsetLevel(2);
        BarcodeScanner.MWBsetResultType(USE_RESULT_TYPE);

        decodeHandler = new Handler(new Handler.Callback() {
            @Override
            public boolean handleMessage(Message msg) {
                switch (msg.what) {
                    case ID_DECODE:
                        decode((byte[]) msg.obj, msg.arg1, msg.arg2);
                        break;
                    case ID_AUTO_FOCUS:
                        autoFocus();
                        break;
                    case ID_RESTART_PREVIEW:
                        restartPreviewAndDecode();
                        break;
                    case ID_DECODE_SUCCEED:
                        stop();
                        onSuccess(((MWResult) msg.obj).text);
                        break;
                    case ID_DECODE_FAILED:
                        break;
                }
                return false;
            }
        });
    }

    private void initCamera() {
        if (ContextCompat.checkSelfPermission(getCurrentActivity(), Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            /* WHEN TARGETING ANDROID 6 OR ABOVE, PERMISSION IS NEEDED */
            if (ActivityCompat.shouldShowRequestPermissionRationale(getCurrentActivity(),
                    Manifest.permission.CAMERA)) {

                new AlertDialog.Builder(getCurrentActivity()).setMessage("You need to allow access to the Camera")
                        .setPositiveButton("OK", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                ActivityCompat.requestPermissions(getCurrentActivity(),
                                        new String[]{Manifest.permission.CAMERA}, 12322);
                            }
                        }).setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        // onBackPressed();
                    }
                }).create().show();
            } else {
                ActivityCompat.requestPermissions(getCurrentActivity(), new String[]{Manifest.permission.CAMERA},
                        12322);
            }
        } else {
            try {
                setDesiredPreviewSize();
                CameraManager.get().openDriver(getHolder(), true);

            } catch (IOException ioe) {
                return;
            } catch (RuntimeException e) {
                return;
            }

            CameraManager.init(getCurrentActivity());
            CameraManager.get().startPreview();
            restartPreviewAndDecode();
        }
    }

    public void setDesiredPreviewSize() {
        if (MAX_THREADS > 2) {
            CameraManager.setDesiredPreviewSize(1280, 720);
        } else {
            CameraManager.setDesiredPreviewSize(800, 480);
        }
    }

    public Handler getDecodeHandler() {
        return decodeHandler;
    }

    public void preview() {
        state = State.PREVIEW;
    }

    private void restartPreviewAndDecode() {
        if (isStopped()) {
            preview();
            requestPreviewFrame();
            autoFocus();
        }
    }

    public void requestPreviewFrame() {
        CameraManager.get().requestPreviewFrame(getDecodeHandler(), ID_DECODE);
    }

    public void setFlash(boolean flash) {
        CameraManager cameraManager = CameraManager.get();

        if (cameraManager == null || !cameraManager.isTorchAvailable()) {
            return;
        }

        cameraManager.setTorch(flash);
    }

    public void setLicense(String license) {
        switch (BarcodeScanner.MWBregisterSDK(license, getCurrentActivity())) {
            case BarcodeScanner.MWB_RTREG_OK:
                initCamera();
                break;
            case BarcodeScanner.MWB_RTREG_INVALID_KEY:
                onError("Registration Invalid Key");
                break;
            case BarcodeScanner.MWB_RTREG_INVALID_CHECKSUM:
                onError("Registration Invalid Checksum");
                break;
            case BarcodeScanner.MWB_RTREG_INVALID_APPLICATION:
                onError("Registration Invalid Application");
                break;
            case BarcodeScanner.MWB_RTREG_INVALID_SDK_VERSION:
                onError("Registration Invalid SDK Version");
                break;
            case BarcodeScanner.MWB_RTREG_INVALID_KEY_VERSION:
                onError("Registration Invalid Key Version");
                break;
            case BarcodeScanner.MWB_RTREG_INVALID_PLATFORM:
                onError("Registration Invalid Platform");
                break;
            case BarcodeScanner.MWB_RTREG_KEY_EXPIRED:
                onError("Registration Key Expired");
                break;
            default:
                onError("Registration Unknown Error");
                break;
        }
    }

    private void stop() {
        state = State.STOPPED;
    }

  public void onResume() {
      if (hasSurface) {
         initCamera();
      } else {
          getHolder().addCallback(this);
      }
  }

  private boolean isDecoding() {
        return state == State.DECODING;
  }

  private boolean isPreviewing() {
        return state == State.PREVIEW;
  }

  private boolean isStopped() {
    return state == State.STOPPED;
  }

  public void autoFocus() {
      if (!isPreviewing() || !isDecoding()) {
          return;
      }

      CameraManager.get().requestAutoFocus(getHandler(), ID_AUTO_FOCUS);
  }

  public void onSuccess(String value) {
        WritableMap event = Arguments.createMap();

        event.putString("value", value);

        manager.pushEvent(context, this, "onSuccess",  event);
    }

  public void onError(String value) {
    WritableMap event = Arguments.createMap();

    event.putString("value", value);

    manager.pushEvent(context, this, "onError",  event);
  }

  public void onPause() {
    stopScaner();
  }

    private void stopScaner() {
        /* Stops the scanner when the activity goes in background */
        if (OVERLAY_MODE == OverlayMode.OM_MWOVERLAY) {
            MWOverlay.removeOverlay();
        }

        CameraManager.get().stopPreview();
        CameraManager.get().closeDriver();

        stop();
        setFlash(false);
    }

  public void onDestroy() {
      Log.e("KYLEDECOT", "onDestroy");
  }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        if (!hasSurface) {
            hasSurface = true;
            CameraManager.init(getCurrentActivity());
        }
    }

    public Activity getCurrentActivity() {
        return appContext.getCurrentActivity();
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        initCamera();
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        hasSurface = false;
    }

    private void decode(final byte[] data, final int width, final int height) {
        if (activeThreads >= MAX_THREADS ||isStopped()) {
            return;
        }

        new Thread(new Runnable() {
            public void run() {
                activeThreads++;

                if (isStopped()) {
                    activeThreads--;
                    return;
                }

                MWResult mwResult = result(data, width, height);

                if (mwResult != null) {
                    stop();
                    Message message = Message.obtain(getDecodeHandler(), ID_DECODE_SUCCEED, mwResult);
                    message.arg1 = mwResult.type;
                    message.sendToTarget();
                } else {
                    Message message = Message.obtain(getDecodeHandler(), ID_DECODE_FAILED);
                    message.sendToTarget();
                }

                activeThreads--;
            }
        }).start();
    }

    private MWResult result(final byte[] data, final int width, final int height) {
        MWResult mwResult = null;
        byte[] rawResult = BarcodeScanner.MWBscanGrayscaleImage(data, width, height);

        if (rawResult != null && BarcodeScanner.MWBgetResultType() == BarcodeScanner.MWB_RESULT_TYPE_MW) {

            BarcodeScanner.MWResults results = new BarcodeScanner.MWResults(rawResult);

            if (results.count > 0) {
                mwResult = results.getResult(0);
            }

        } else if (rawResult != null && isRawResultType()) {
            mwResult = new MWResult();
            mwResult.text = rawResult.toString();
            mwResult.type = BarcodeScanner.MWBgetLastType();
        }

        return mwResult;
    }

    private boolean isRawResultType() {
        return BarcodeScanner.MWBgetResultType() == BarcodeScanner.MWB_RESULT_TYPE_RAW;
    }
}
