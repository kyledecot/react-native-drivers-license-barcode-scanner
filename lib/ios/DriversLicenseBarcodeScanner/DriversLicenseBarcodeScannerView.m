#import "DriversLicenseBarcodeScannerView.h"
//#import "UIView+React.h"
#import "BarcodeScanner.h"
#import "MWResult.h"

#include <mach/mach_host.h>

#define RECT_LANDSCAPE_1D 4, 20, 92, 60

typedef enum eMainScreenState {
    NORMAL,
    LAUNCHING_CAMERA,
    CAMERA,
    CAMERA_DECODING,
    DECODE_DISPLAY,
    CANCELLING
} MainScreenState;

@implementation DriversLicenseBarcodeScannerView {
    BOOL _torch;
    dispatch_queue_t captureSessionQueue;
    bool running;
    int activeThreads;
    int availableThreads;

    MainScreenState state;

    int width;
    int height;
    int bytesPerRow;
    unsigned char *baseAddress;
    NSTimer *focusTimer;
    AVCaptureDevice *device;

    int param_ZoomLevel1;
    int param_ZoomLevel2;
    int zoomLevel;
    bool videoZoomSupported;
    float firstZoom;
    float secondZoom;
    float digitalZoom;
    AVCaptureSession *captureSession;
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

#pragma mark -
#pragma mark Initialization

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super initWithFrame:CGRectZero])) {
        self->captureSession = [self configureCaptureSession];
        self->captureSessionQueue = [self configureCaptureSessionQueue];
        self->device = [self configureCaptureDevice];
        
        AVCaptureDeviceInput *captureInput = [self configureCaptureInputWithDevice: self->device];
        AVCaptureVideoDataOutput *captureOutput = [self configureCaptureOutput];

        [self configureDecoder];
        [self configureCaptureSessionWithInput:captureInput andOutput:captureOutput];
        [self configurePreviewLayer];

        [self startCapturing];
    } else {
        NSLog(@"NOPE");
    }
    
    return self;
}

- (CALayer *)layer
{
    return (AVCaptureVideoPreviewLayer *)[super layer];
}

- (dispatch_queue_t)configureCaptureSessionQueue
{
    return dispatch_queue_create([self->captureSession.self.description UTF8String], NULL);
}

- (void)startCapturing {
    dispatch_async(self->captureSessionQueue, ^{
        self->state = CAMERA;
        [self->captureSession startRunning];
    });
}

- (AVCaptureSession *)configureCaptureSession
{
    return [[AVCaptureSession alloc] init];
}

- (AVCaptureDeviceInput *)configureCaptureInputWithDevice:(AVCaptureDevice *)device
{
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self->device error:&error];
    
    if (error != NULL) {
        NSString *description = error.localizedDescription;
        NSLog(@"%@", description);
        
        abort(); // TODO: What to do here?
    }
    
    return captureInput;
}

- (AVCaptureVideoDataOutput *)configureCaptureOutput
{
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];

    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()]; // TODO: Should this be on the main queue?
    
    return captureOutput;
}

- (void)configurePreviewLayer
{
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
    
    [layer setSession:self->captureSession];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (void)configureCaptureSessionWithInput:(AVCaptureDeviceInput *)input andOutput:(AVCaptureOutput *)output
{
    [self->captureSession beginConfiguration];
    
    [self->captureSession addInput:input];
    [self->captureSession addOutput:output];
    
    [self->captureSession commitConfiguration];
}

- (AVCaptureDevice *)configureCaptureDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    
    return nil; // TODO: We need a device! What should happen here?
}

- (void)configureDecoder
{
    MWB_setActiveCodes(MWB_CODE_MASK_PDF);
    MWB_setDirection(MWB_SCANDIRECTION_HORIZONTAL);
    MWB_setScanningRect(MWB_CODE_MASK_PDF, RECT_LANDSCAPE_1D);
    MWB_setLevel(2);
    MWB_setResultType(MWB_RESULT_TYPE_MW);
}

# pragma mark -
# pragma mark deallocation

- (void)dealloc
{
    dispatch_async(captureSessionQueue, ^{
        // TODO: Will this work if the dealloc happens before this block is ran?
        [self->captureSession stopRunning];
    });
}

# pragma mark - Setters

- (void)setTorch:(bool)torchOn
{
    if ([self->device isTorchModeSupported:AVCaptureTorchModeOn]) {
        NSError *error;

        if ([self->device lockForConfiguration:&error]) {
            if (torchOn)
                [self->device setTorchMode:AVCaptureTorchModeOn];
            else
                [self->device setTorchMode:AVCaptureTorchModeOff];
            [self->device unlockForConfiguration];
        } else {
            // TODO
        }
    }
}

- (void)setLicense:(NSString *)license
{
//    [self onError];
    
    switch (MWB_registerSDK([license UTF8String])) {
        case MWB_RTREG_OK:
            NSLog(@"Registration OK");
            break;
        case MWB_RTREG_INVALID_KEY:
            NSLog(@"Registration Invalid Key");
            break;
        case MWB_RTREG_INVALID_CHECKSUM:
            NSLog(@"Registration Invalid Checksum");
            break;
        case MWB_RTREG_INVALID_APPLICATION:
            NSLog(@"Registration Invalid Application");
            break;
        case MWB_RTREG_INVALID_SDK_VERSION:
            NSLog(@"Registration Invalid SDK Version");
            break;
        case MWB_RTREG_INVALID_KEY_VERSION:
            NSLog(@"Registration Invalid Key Version");
            break;
        case MWB_RTREG_INVALID_PLATFORM:
            NSLog(@"Registration Invalid Platform");
            break;
        case MWB_RTREG_KEY_EXPIRED:
            NSLog(@"Registration Key Expired");
            break;

        default:
            NSLog(@"Registration Unknown Error");
            break;
    }
}

# pragma mark -
# pragma mark Lifecycle

- (void)removeFromSuperview
{
  // TODO We should stop capturing, remove focus timers, etc
}

- (void)layoutSubviews
{
    // TODO: This will not work if you go from landscape left <-> landscape right (will end up upside-down)
    
    [super layoutSubviews];
    
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            [[(AVCaptureVideoPreviewLayer *)self.layer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];

            break;
        case UIDeviceOrientationLandscapeLeft:
            [[(AVCaptureVideoPreviewLayer *)self.layer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            break;
        case UIDeviceOrientationLandscapeRight:
            [[(AVCaptureVideoPreviewLayer *)self.layer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [[(AVCaptureVideoPreviewLayer *)self.layer connection] setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
        default:
            break;
    }
}

- (void)stopCapturing
{
    [self->captureSession stopRunning];
}

# pragma MARK: -
# pragma MARK: AVCaptureVideoDataOutputSampleBufferDelegate

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{

    
    view.frame = self.bounds;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (state != CAMERA && state != CAMERA_DECODING) {
        NSLog(@"WRONG STATE");
        return;
    }

    // TODO: Put this back in!
//    if (activeThreads >= availableThreads){
//        NSLog(@"NOT ENOUGH THREADS");
//        return;
//    }

    if (state != CAMERA_DECODING)
    {
        state = CAMERA_DECODING;
    }

    activeThreads++;
    
//    NSLog(@"LOOKING...");

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
        unsigned char *pResult = NULL;

        int resLength = MWB_scanGrayscaleImage(frameBuffer,self->width,self->height, &pResult);

        free(frameBuffer);

//         NSLog(@"Frame decoded. Active threads: %d", self->activeThreads);

        MWResults *mwResults = nil;
        MWResult *mwResult = nil;
        if (resLength > 0){

            if (self->state == NORMAL){
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
        if (mwResult) {
            self->state = CAMERA;
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
//
                
                NSLog(@"%@", mwResult.text);
//                [self stopCapturing];
            });

        } else {
            self->state = CAMERA;
        }

        self->activeThreads --;

    });
}

@end
