#import "DriversLicenseBarcodeScannerView.h"
#import "UIView+React.h"
#import "BarcodeScanner.h"
#include <mach/mach_host.h>
#import "MWResult.h"

typedef enum eMainScreenState {
    NORMAL,
    LAUNCHING_CAMERA,
    CAMERA,
    CAMERA_DECODING,
    DECODE_DISPLAY,
    CANCELLING
} MainScreenState;



#define OVERLAY_MODE OM_MWOVERLAY

#define USE_MWANALYTICS false

#define USE_MWPARSER    false
/* Parser */
/*
 *   Set the desired parser type
 *   Available options:
 *       MWP_PARSER_MASK_NONE
 *       MWP_PARSER_MASK_IUID
 *       MWP_PARSER_MASK_ISBT
 *       MWP_PARSER_MASK_AAMVA
 *       MWP_PARSER_MASK_HIBC
 *       MWP_PARSER_MASK_AUTO
 */
#define MWPARSER_MASK   MWP_PARSER_MASK_AUTO

#define USE_60_FPS      false

#if USE_MWPARSER
#import "MWParser.h"
#endif


#if USE_MWANALYTICS
#import "MWAnalytics.h"
#endif

#define PDF_OPTIMIZED   false

#define MAX_THREADS 2

#define MAX_DIGITAL_ZOOM 4

// !!! Rects are in format: x, y, width, height !!!
#define RECT_LANDSCAPE_1D       4, 20, 92, 60
#define RECT_LANDSCAPE_2D       20, 5, 60, 90
#define RECT_PORTRAIT_1D        20, 4, 60, 92
#define RECT_PORTRAIT_2D        20, 5, 60, 90
#define RECT_FULL_1D            4, 4, 92, 92
#define RECT_FULL_2D            20, 5, 60, 90
#define RECT_DOTCODE            30, 20, 40, 60

typedef NS_ENUM(NSUInteger, DriversLicenseBarcodeScannerViewState) {
    kDecoding,
    kReady,
    kScanning,
    kActive
};

@implementation DriversLicenseBarcodeScannerView {
    NSString *_license;
    BOOL _flash;
    AVCaptureDevice *_captureDevice;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureSession *_captureSession;
    AVCaptureVideoDataOutput *_captureOutput;
    AVCaptureDeviceInput *_captureDeviceInput;
    MainScreenState _state;
    int _activeThreads;
    int _availableThreads;
    unsigned char *baseAddress;
    int width;
    int height;
    int bytesPerRow;
    
    
    
    
    
    
    
    bool running;
    int activeThreads;
    int availableThreads;
    
    MainScreenState state;
    

    NSTimer *focusTimer;
    
    int param_ZoomLevel1;
    int param_ZoomLevel2;
    int zoomLevel;
    bool videoZoomSupported;
    float firstZoom;
    float secondZoom;
    float digitalZoom;
}

- (instancetype)init {
    if ((self = [super init])) {
        NSError *error;

        _activeThreads = 0;
        _availableThreads = 2; // TODO: Figure this out
        
        _license = @"";
        _state = NORMAL;
        _flash = FALSE;
        _captureDevice = [self backCamera];
        _captureOutput = [self setupCaptureOutput];
        _captureDeviceInput = [self setupCaptureDeviceInput:_captureDevice error:&error];
        _captureSession = [self setupCaptureSessionWithDevice:_captureDevice captureOutput:_captureOutput];
        _previewLayer = [self setupPreviewLayerWithCaptureSession:_captureSession];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(orientationChanged:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
        
        if (error == nil) {
            [[self layer] addSublayer: _previewLayer];
        } else {
            
        }
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) orientationChanged:(NSNotification *)notification {
    [self updatePreviewLayerOrientation];
}

- (AVCaptureVideoPreviewLayer *)setupPreviewLayerWithCaptureSession: (AVCaptureSession *)session {
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: session];

    [previewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];

    return previewLayer;
}

- (AVCaptureVideoDataOutput *)setupCaptureOutput {
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [captureOutput setAlwaysDiscardsLateVideoFrames: YES];
    [captureOutput setSampleBufferDelegate: self queue:dispatch_get_main_queue()];

    NSString *key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];

    [captureOutput setVideoSettings:videoSettings];
    
    return captureOutput;
}

- (AVCaptureSession *)setupCaptureSessionWithDevice:(AVCaptureDevice *)device captureOutput:(AVCaptureOutput *)output {

    NSError *error;
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice: device error: &error];

    if (error == nil) {
        [captureSession addInput:input];
        [captureSession addOutput:output];
        
        if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
            NSLog(@"Set preview port to 1280X720");
        } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            NSLog(@"Set preview port to 640x480");
        } else {
            NSLog(@"I'm not sure what to do here");
            abort();
        }
    } else {
        NSLog(@"ERROR: %@", [error localizedDescription]);
    }
    
    return captureSession;
}

- (AVCaptureDeviceInput *)setupCaptureDeviceInput:(AVCaptureDevice *)device error:(NSError **)error {
    return [[AVCaptureDeviceInput alloc] initWithDevice: device error: error];
}

- (void)didMoveToWindow {
    [self startCapturing];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updatePreviewLayerFrame];
}

- (void)updatePreviewLayerOrientation {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
}

- (void)updatePreviewLayerFrame {
    _previewLayer.frame = [self frame];
}

- (void)setFlash:(BOOL)flash {
    _flash = flash;
    
    [self setTorch:flash];
}

- (BOOL)flash {
    return _flash;
}

- (void)setLicense:(NSString *)license {
    _license = license;
    
    NSLog(@"SETTING THE LICENSE");
}

- (void)setTorch:(bool) torchOn {
    if ([_captureDevice isTorchModeSupported: AVCaptureTorchModeOn]) {
        NSError *error;
        
        if ([_captureDevice lockForConfiguration:&error]) {
            if (torchOn) {
                [_captureDevice setTorchMode:AVCaptureTorchModeOn];
            } else {
                [_captureDevice setTorchMode:AVCaptureTorchModeOff];
            }
            [_captureDevice unlockForConfiguration];
        } else {
            NSLog(@"ERROR SETTING TORCH: %@", [error localizedDescription]);
        }
    }
}

- (NSString *)license {
    return _license;
}

-(void)startCapturing {
    NSLog(@"Capturing");

  
        
//        long processorCount = NSProcessInfo.processInfo.processorCount;

    
        [_captureSession startRunning];
 
//        NSLog(@"Number of processors \(%s)", ProcessInfo.processInfo.processorCount);
        
    
//    if (processorCount < 2) {
        //        do {
        //            try device.lockForConfiguration()
        //            device.activeVideoMinFrameDuration = CMTimeMake(1, 15)
        //        } catch { }
        //        device.unlockForConfiguration()
        //        DLog("activeVideoMinFrameDuration: \(device.activeVideoMinFrameDuration)")
//    }
   
    //
    //    availableThreads = min(MAX_THREADS, ProcessInfo.processInfo.processorCount)
    //    activeThreads = 0
    //
    //    prevLayer = AVCaptureVideoPreviewLayer(session: captureSession) as AVCaptureVideoPreviewLayer
    //
    //    prevLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
    //    prevLayer.frame = CGRect(x: 0, y: 0, width: min(frame.size.width, frame.size.height), height: max(frame.size.width, frame.size.height))
    //
    //    prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    //
    //    layer.addSublayer(prevLayer)
    //
    //    setupCustomOverlay()
    //
    //    focusTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(reFocus), userInfo: nil, repeats: true)
}

- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    
    return nil;
}

// MARK: -
// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (state != CAMERA && state != CAMERA_DECODING) {
        return;
    }
    
    if (activeThreads >= availableThreads){
        return;
    }
    
    if (_state != CAMERA_DECODING)
    {
        _state = CAMERA_DECODING;
    }
    
    activeThreads++;
    
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //Lock the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    //Get information about the image
    baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
    int pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
    switch (pixelFormat) {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            //NSLog(@"Capture pixel format=NV12");
            bytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
            width = bytesPerRow;//CVPixelBufferGetWidthOfPlane(imageBuffer,0);
            height = (int) CVPixelBufferGetHeightOfPlane(imageBuffer,0);
            break;
        case kCVPixelFormatType_422YpCbCr8:
            //NSLog(@"Capture pixel format=UYUY422");
            bytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
            width = (int) CVPixelBufferGetWidth(imageBuffer);
            height = (int) CVPixelBufferGetHeight(imageBuffer);
            int len = width*height;
            int dstpos=1;
            for (int i=0;i<len;i++){
                baseAddress[i]=baseAddress[dstpos];
                dstpos+=2;
            }
            
            break;
        default:
            //    NSLog(@"Capture pixel format=RGB32");
            break;
    }
    
    
    unsigned char *frameBuffer = malloc(width * height);
    memcpy(frameBuffer, baseAddress, width * height);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        
        unsigned char *pResult=NULL;
        
        int resLength = MWB_scanGrayscaleImage(frameBuffer,width,height, &pResult);
        
        
        
        
        
        free(frameBuffer);
        
        
        // NSLog(@"Frame decoded. Active threads: %d", activeThreads);
        
        MWResults *mwResults = nil;
        MWResult *mwResult = nil;
        if (resLength > 0){
            
            if (_state == NORMAL){
                resLength = 0;
                free(pResult);
                
            } else {
                mwResults = [[MWResults alloc] initWithBuffer:pResult];
                if (mwResults && mwResults.count > 0){
                    mwResult = [mwResults resultAtIntex:0];
                }
                
                free(pResult);
            }
        }
        
        //CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        //ignore results less than 4 characters - probably false detection
        if (mwResult)
        {
            
            
            _state = NORMAL;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [_captureSession stopRunning];
                NSLog(@"FOUND ONE!");
            });
            
        }
        else
        {
            _state = CAMERA;
        }
        
        
        activeThreads --;
        
    });
}

@end
