#import "DriversLicenseBarcodeScannerView.h"
#import "BarcodeScanner.h"
#import "MWResult.h"

#define MAX_THREADS 2

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
    dispatch_queue_t _captureSessionQueue;
    bool running;
    int activeThreads;
    int availableThreads;

    MainScreenState state;

    int width;
    int height;
    int bytesPerRow;
    unsigned char *baseAddress;
    NSTimer *focusTimer;
    AVCaptureDevice *_device;
    AVCaptureSession *_captureSession;
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

#pragma mark -
#pragma mark Initialization

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super initWithFrame:CGRectZero])) {
        self->_captureSession = [self configureCaptureSession];
        self->_captureSessionQueue = [self configureCaptureSessionQueue];
        self->_device = [self configureCaptureDevice];
        
        AVCaptureDeviceInput *captureInput = [self configureCaptureInputWithDevice: self->_device];
        AVCaptureVideoDataOutput *captureOutput = [self configureCaptureOutput];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
        
        [self configureDecoder];
        [self configureCaptureSessionWithInput:captureInput andOutput:captureOutput];
        [self configurePreviewLayer];

        [self startCapturing];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithCoder:aDecoder];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    AVCaptureConnection *connection = [(AVCaptureVideoPreviewLayer *)self.layer connection];
    AVCaptureVideoOrientation orientation;
    CGSize size = self.frame.size;
    int direction;
    
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            orientation = AVCaptureVideoOrientationPortrait;
            direction = MWB_SCANDIRECTION_VERTICAL;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            direction = MWB_SCANDIRECTION_HORIZONTAL;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            direction = MWB_SCANDIRECTION_HORIZONTAL;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            direction = MWB_SCANDIRECTION_VERTICAL;
            break;
    }
    
    [connection setVideoOrientation:orientation];
    MWB_setDirection(direction);
    MWB_setScanningRect(MWB_CODE_MASK_PDF, 0, 0, size.width, size.height);
}

- (CALayer *)layer
{
    return (AVCaptureVideoPreviewLayer *)[super layer];
}

- (dispatch_queue_t)configureCaptureSessionQueue
{
    return dispatch_queue_create([self->_captureSession.self.description UTF8String], NULL);
}

- (void)startCapturing {
    dispatch_async(self->_captureSessionQueue, ^{
        self->state = CAMERA;
        [self->_captureSession startRunning];
    });
}

- (AVCaptureSession *)configureCaptureSession
{
    return [[AVCaptureSession alloc] init];
}

- (AVCaptureDeviceInput *)configureCaptureInputWithDevice:(AVCaptureDevice *)device
{
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
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
    
    [layer setSession:self->_captureSession];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (void)configureCaptureSessionWithInput:(AVCaptureDeviceInput *)input andOutput:(AVCaptureOutput *)output
{
    [self->_captureSession beginConfiguration];
    
    [self->_captureSession addInput:input];
    [self->_captureSession addOutput:output];
    
    [self->_captureSession commitConfiguration];
}

- (AVCaptureDevice *)configureCaptureDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    
    return nil; // TODO: We need a _device! What should happen here?
}

- (void)configureDecoder
{
    MWB_setActiveCodes(MWB_CODE_MASK_PDF);
    MWB_setLevel(2);
    MWB_setResultType(MWB_RESULT_TYPE_MW);
}

# pragma mark -
# pragma mark deallocation

- (void)dealloc
{
    dispatch_async(_captureSessionQueue, ^{
        // TODO: Will this work if the dealloc happens before this block is ran?
        [self->_captureSession stopRunning];
    });
}

# pragma mark - Setters

- (void)setTorch:(bool)torchOn
{
    if ([self->_device isTorchModeSupported:AVCaptureTorchModeOn]) {
        NSError *error;

        if ([self->_device lockForConfiguration:&error]) {
            if (torchOn)
                [self->_device setTorchMode:AVCaptureTorchModeOn];
            else
                [self->_device setTorchMode:AVCaptureTorchModeOff];
            [self->_device unlockForConfiguration];
        } else {
            // TODO
        }
    }
}

- (void)setLicense:(NSString *)license
{
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

//- (void)layoutSubviews
//{
//    // TODO: This will not work if you go from landscape left <-> landscape right (will end up upside-down)
//
//    [super layoutSubviews];
//
//    NSLog(@"%@", NSStringFromCGRect([self frame]));
//
//
//}

- (void)stopCapturing
{
    [self->_captureSession stopRunning];
}

- (void)decode:(NSString *)text
{
    NSLog(@"%@", text);
    
//    NSString *decodeResult;
//    unsigned char * parserResult = NULL;
//    double parserRes = -1;
//    NSString *parserMask;
//
//
//    parserRes = MWP_getJSON(MWPARSER_MASK, result.encryptedResult, result.bytesLength, &parserResult);
//
//    if (parserRes >= 0){
//        decodeResult = [NSString stringWithCString:parserResult encoding:NSUTF8StringEncoding];
//
//
//    }
//
//    NSLog(@"%@", decodeResult);
}


# pragma MARK: -
# pragma MARK: AVCaptureVideoDataOutputSampleBufferDelegate

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
    view.frame = self.bounds;
}

- (MWResult *)resultFromBuffer:(uint8_t *)buffer
{
    MWResults *mwResults = [[MWResults alloc] initWithBuffer:buffer];

    if (mwResults && mwResults.count > 0) {
        return [mwResults resultAtIntex:0];
    }
    
    return NULL;
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

    if (state != CAMERA_DECODING) {
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
            height = (int) CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
            break;
        case kCVPixelFormatType_422YpCbCr8:
            //NSLog(@"Capture pixel format=UYUY422");
            bytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
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
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        unsigned char *pResult = NULL;

        int resLength = MWB_scanGrayscaleImage(frameBuffer,self->width,self->height, &pResult);
        MWResult *result;
        free(frameBuffer);

//         NSLog(@"Frame decoded. Active threads: %d", self->activeThreads);

        if (resLength > 0) {
            if (self->state == NORMAL) {
                resLength = 0;
            } else {
                result = [self resultFromBuffer:pResult];
            }
        }

        free(pResult);

        //CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        //ignore results less than 4 characters - probably false detection
        if (result) {
            self->state = CAMERA;
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                self->_onSuccess(@{ @"value" : result.text });
            });
        } else {
            self->state = CAMERA;
        }

        self->activeThreads --;
    });
}

@end
