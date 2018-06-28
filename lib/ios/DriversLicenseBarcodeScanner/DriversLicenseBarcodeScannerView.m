#import "DriversLicenseBarcodeScannerView.h"
#import "UIView+React.h"
#import "BarcodeScanner.h"
#import "MWResult.h"

#include <mach/mach_host.h>

#define RECT_LANDSCAPE_1D 4, 20, 92, 60

@implementation DriversLicenseBarcodeScannerView {
    BOOL _torch;
    AVCaptureSession *_captureSession;
    dispatch_queue_t captureSessionQueue;
    AVCaptureDevice *_device;
    AVCaptureVideoPreviewLayer *_prevLayer;
    bool running;
    int activeThreads;
    int availableThreads;

    MainScreenState state;

    int width;
    int height;
    int bytesPerRow;
    unsigned char *baseAddress;
    NSTimer *focusTimer;

    int param_ZoomLevel1;
    int param_ZoomLevel2;
    int zoomLevel;
    bool videoZoomSupported;
    float firstZoom;
    float secondZoom;
    float digitalZoom;
}

@synthesize license = _license;
@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize device = _device;
@synthesize state;
@synthesize focusTimer;

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (CALayer *)layer {
    return (AVCaptureVideoPreviewLayer *)[super layer];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.captureSession = [[AVCaptureSession alloc] init];
        
        captureSessionQueue = dispatch_queue_create([self.captureSession.self.description UTF8String], NULL);
        NSError *error;
        self.device = [self backCamera];
        AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        
        [self.captureSession beginConfiguration];
        
        
        if (error != NULL) {
            NSString *description = error.localizedDescription;
            NSLog(@"%@", description);
            
            abort(); // TODO: What to do here?
        }
        
        [self.captureSession addInput:captureInput];
        [self.captureSession addOutput:captureOutput];
        
        [self.captureSession commitConfiguration];
        
        
        [(AVCaptureVideoPreviewLayer *)self.layer setSession:self.captureSession];
        [(AVCaptureVideoPreviewLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()]; // TODO: Should this be on the main queue?
        dispatch_async(captureSessionQueue, ^{
            self->state = CAMERA;
            [self->_captureSession startRunning];
        });
    }
    return self;
}

- (void)dealloc
{
    dispatch_async(captureSessionQueue, ^{
        // TODO: Will this work if the dealloc happens before this block is ran?
        [self->_captureSession stopRunning];
    });
}

#pragma mark -
#pragma mark Initialization

- (void)initDecoder {
    MWB_setActiveCodes(MWB_CODE_MASK_PDF);
    MWB_setDirection(MWB_SCANDIRECTION_HORIZONTAL);
    MWB_setScanningRect(MWB_CODE_MASK_PDF, RECT_LANDSCAPE_1D);
    MWB_setLevel(2);
    MWB_setResultType(MWB_RESULT_TYPE_MW);
}

- (void) setTorch: (bool) torchOn {
    if ([self.device isTorchModeSupported:AVCaptureTorchModeOn]) {
        NSError *error;

        if ([self.device lockForConfiguration:&error]) {
            if (torchOn)
                [self.device setTorchMode:AVCaptureTorchModeOn];
            else
                [self.device setTorchMode:AVCaptureTorchModeOff];
            [self.device unlockForConfiguration];
        } else {
            // TODO
        }
    }
}

- (void)setLicense:(NSString *)license {
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
    
    // TODO: We could probably do this in the initializer
    [self initDecoder];
}


- (void)stopScanning {
    [self.captureSession stopRunning];
    self.state = NORMAL;
}

- (void)layoutSubviews {
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

- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }

    return nil;
}

# PRAGMA MARK: -
# PRAGMA MARK: AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
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



        unsigned char *pResult=NULL;

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
        if (mwResult)
        {


            self->state = CAMERA;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
//                [self->_captureSession stopRunning];
                NSLog(@"%@", mwResult);

            });

        }
        else
        {
            self->state = CAMERA;
        }


        self->activeThreads --;

    });
}

@end
