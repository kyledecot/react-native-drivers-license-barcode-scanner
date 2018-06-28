#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

typedef enum eMainScreenState {
    NORMAL,
    LAUNCHING_CAMERA,
    CAMERA,
    CAMERA_DECODING,
    DECODE_DISPLAY,
    CANCELLING
} MainScreenState;

@interface DriversLicenseBarcodeScannerView : UIView<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) NSString *license;
@property (nonatomic, assign) BOOL torch;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, retain) AVCaptureDevice *device;

@property (nonatomic, assign) MainScreenState state;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, retain) NSTimer *focusTimer;

- (void)initCapture;
- (void) startScanning;
- (void) stopScanning;

@end
