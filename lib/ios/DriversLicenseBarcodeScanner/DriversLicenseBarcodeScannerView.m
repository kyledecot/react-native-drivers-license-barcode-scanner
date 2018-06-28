#import "DriversLicenseBarcodeScannerView.h"
#import "UIView+React.h"
#import "BarcodeScanner.h"
#import "MWResult.h"

#include <mach/mach_host.h>

//
//@class MWResult;
//
//@interface DecoderResult : NSObject {
//    BOOL succeeded;
//    MWResult *mwResult;
//}
//
//@property (nonatomic, assign) BOOL succeeded;
//@property (nonatomic, retain) MWResult *result;
//
//+(DecoderResult *)createSuccess:(MWResult *)result;
//+(DecoderResult *)createFailure;
//
//@end
//
//@implementation DecoderResult
//
//@synthesize succeeded;
//@synthesize result;
//
//+(DecoderResult *)createSuccess:(MWResult *)result {
//    DecoderResult *obj = [[DecoderResult alloc] init];
//    if (obj != nil) {
//        obj.succeeded = YES;
//        obj.result = result;
//    }
//    return obj;
//}
//
//+(DecoderResult *)createFailure {
//    DecoderResult *obj = [[DecoderResult alloc] init];
//    if (obj != nil) {
//        obj.succeeded = NO;
//        obj.result = nil;
//    }
//    return obj;
//}
//
//- (void)dealloc {
//#if !__has_feature(objc_arc)
//    [super dealloc];
//#endif
//    self.result = nil;
//}
//
//
//
//
//@end
//
//
////#import "MWResult.h"
//
//
//#define OVERLAY_MODE OM_MWOVERLAY
//
//#define USE_MWANALYTICS false
//
//#define USE_MWPARSER    false
///* Parser */
///*
// *   Set the desired parser type
// *   Available options:
// *       MWP_PARSER_MASK_NONE
// *       MWP_PARSER_MASK_IUID
// *       MWP_PARSER_MASK_ISBT
// *       MWP_PARSER_MASK_AAMVA
// *       MWP_PARSER_MASK_HIBC
// *       MWP_PARSER_MASK_AUTO
// */
//#define MWPARSER_MASK   MWP_PARSER_MASK_AUTO
//
//#define USE_60_FPS      false
//
//#if USE_MWPARSER
//#import "MWParser.h"
//#endif
//
////#if OVERLAY_MODE == OM_MWOVERLAY
////#import "MWOverlay.h"
////#endif
//
//
//#if USE_MWANALYTICS
//#import "MWAnalytics.h"
//#endif
//
//#define PDF_OPTIMIZED   false
//
//#define MAX_THREADS 2
//
//#define MAX_DIGITAL_ZOOM 4
//
//// !!! Rects are in format: x, y, width, height !!!
#define RECT_LANDSCAPE_1D       4, 20, 92, 60
//#define RECT_LANDSCAPE_2D       20, 5, 60, 90
//#define RECT_PORTRAIT_1D        20, 4, 60, 92
//#define RECT_PORTRAIT_2D        20, 5, 60, 90
//#define RECT_FULL_1D            4, 4, 92, 92
//#define RECT_FULL_2D            20, 5, 60, 90
//#define RECT_DOTCODE            30, 20, 40, 60
//
//static NSString *DecoderResultNotification = @"DecoderResultNotification";
//
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

    //Set minimum result length for low-protected barcode types
    MWB_setMinLength(MWB_CODE_MASK_25, 5);
    MWB_setMinLength(MWB_CODE_MASK_MSI, 5);
    MWB_setMinLength(MWB_CODE_MASK_39, 5);
    MWB_setMinLength(MWB_CODE_MASK_CODABAR, 5);
    MWB_setMinLength(MWB_CODE_MASK_11, 5);

    //Use MWResult class instead of barcode raw byte array as result
    MWB_setResultType(MWB_RESULT_TYPE_MW);

    //get and print Library version
    int ver = MWB_getLibVersion();
    int v1 = (ver >> 16);
    int v2 = (ver >> 8) & 0xff;
    int v3 = (ver & 0xff);
    NSString *libVersion = [NSString stringWithFormat:@"%d.%d.%d", v1, v2, v3];
    NSLog(@"Lib version: %@", libVersion);
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
    [self initDecoder];
//    [self initCapture];
//    [self startScanning];
}
//
//- (void)initCapture
//{
//    /*We setup the input*/
//    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//
//    //Comment out this line if you want to use front camera
//    //self.device = [self frontCamera];
//    NSError *error;
//    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
//
//    if (error != NULL) {
//        NSLog(@"ERROR: %@", [error localizedDescription]);
//    }
//
//    /*We setupt the output*/
//    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
//    captureOutput.alwaysDiscardsLateVideoFrames = YES;
//    //captureOutput.minFrameDuration = CMTimeMake(1, 10); Uncomment it to specify a minimum duration for each video frame
//    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
//    // Set the video output to store frame in BGRA (It is supposed to be faster)
//
//    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
//    // Set the video output to store frame in 422YpCbCr8(It is supposed to be faster)
//
//    //************************Note this line
//    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
//
//    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
//    [captureOutput setVideoSettings:videoSettings];
//
//    //And we create a capture session
//    self.captureSession = [[AVCaptureSession alloc] init];
//    //We add input and output
//    [self.captureSession addInput:captureInput];
//    [self.captureSession addOutput:captureOutput];
//
//    float resX = 640;
//    float resY = 480;
//
//    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
//    {
//        NSLog(@"Set preview port to 1280X720");
//        resX = 1280;
//        resY = 720;
//        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
//    } else
//        //set to 640x480 if 1280x720 not supported on device
//        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
//        {
//            NSLog(@"Set preview port to 640X480");
//            self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
//        }
//
//
//    // Limit camera FPS to 15 for single core devices (iPhone 4 and older) so more CPU power is available for decoder
//    host_basic_info_data_t hostInfo;
//    mach_msg_type_number_t infoCount;
//    infoCount = HOST_BASIC_INFO_COUNT;
//    host_info( mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount ) ;
//
//    if (hostInfo.max_cpus < 2){
//        [self.device lockForConfiguration:nil];
//        [self.device setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
//        [self.device unlockForConfiguration];
//    }
//#if USE_60_FPS
//    else{
//        for(AVCaptureDeviceFormat *vFormat in [self.device formats] )
//        {
//            CMFormatDescriptionRef description= vFormat.formatDescription;
//            float maxrate=((AVFrameRateRange*)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
//            float minrate=((AVFrameRateRange*)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).minFrameRate;
//            CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(description);
//
//            if(maxrate>59 && CMFormatDescriptionGetMediaSubType(description)==kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange &&
//               dimension.width == resX && dimension.height == resY)
//            {
//                if ( YES == [self.device lockForConfiguration:NULL] )
//                {
//                    self.device.activeFormat = vFormat;
//                    [self.device setActiveVideoMinFrameDuration:CMTimeMake(10,minrate * 10)];
//                    [self.device setActiveVideoMaxFrameDuration:CMTimeMake(10,600)];
//                    [self.device unlockForConfiguration];
//
//                    NSLog(@"formats  %@ %@ %@",vFormat.mediaType,vFormat.formatDescription,vFormat.videoSupportedFrameRateRanges);
//                    //break;
//                }
//            }
//        }
//    }
//#endif
//
//    NSLog(@"hostInfo.max_cpus %d",hostInfo.max_cpus);
//    availableThreads = MIN(MAX_THREADS, hostInfo.max_cpus);
//    activeThreads = 0;
//
//    /*We add the preview layer*/
//
//    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
//
//
////    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
////        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
//        self.prevLayer.frame = CGRectMake(0, 0, 400, 400);
////    }
////    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
////        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
////        self.prevLayer.frame = CGRectMake(0, 0, MAX(self.view.frame.size.width,self.view.frame.size.height), MIN(self.view.frame.size.width,self.view.frame.size.height));
////    }
//
//
////    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
////        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
////        self.prevLayer.frame = CGRectMake(0, 0, MIN(self.view.frame.size.width,self.view.frame.size.height), MAX(self.view.frame.size.width,self.view.frame.size.height));
////    }
////    if (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
////        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
////        self.prevLayer.frame = CGRectMake(0, 0, MIN(self.view.frame.size.width,self.view.frame.size.height), MAX(self.view.frame.size.width,self.view.frame.size.height));
////    }
////
//
//    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.layer addSublayer: self.prevLayer];
////#if OVERLAY_MODE == OM_MWOVERLAY
////    [MWOverlay addToPreviewLayer:self.prevLayer];
////    [imageOverlay setHidden:YES];
////#elif OVERLAY_MODE == OM_IMAGE
////    [imageOverlay setHidden:NO];
////    [self.view bringSubviewToFront:imageOverlay];
////#else
////    [imageOverlay removeFromSuperview];
////#endif
//
//    videoZoomSupported = false;
//
//    if ([self.device respondsToSelector:@selector(setActiveFormat:)] &&
//        [self.device.activeFormat respondsToSelector:@selector(videoMaxZoomFactor)] &&
//        [self.device respondsToSelector:@selector(setVideoZoomFactor:)]){
//
//        float maxZoom = 0;
//        if ([self.device.activeFormat respondsToSelector:@selector(videoZoomFactorUpscaleThreshold)]){
//            maxZoom = self.device.activeFormat.videoZoomFactorUpscaleThreshold;
//        } else {
//            maxZoom = self.device.activeFormat.videoMaxZoomFactor;
//        }
//
//        float maxZoomTotal = self.device.activeFormat.videoMaxZoomFactor;
//
//        if ([self.device respondsToSelector:@selector(setVideoZoomFactor:)] && maxZoomTotal > 1.1){
//            videoZoomSupported = true;
//
//
//
//            if (param_ZoomLevel1 != 0 && param_ZoomLevel2 != 0){
//
//                if (param_ZoomLevel1 > maxZoomTotal * 100){
//                    param_ZoomLevel1 = (int)(maxZoomTotal * 100);
//                }
//                if (param_ZoomLevel2 > maxZoomTotal * 100){
//                    param_ZoomLevel2 = (int)(maxZoomTotal * 100);
//                }
//
//                firstZoom = 0.01 * param_ZoomLevel1;
//                secondZoom = 0.01 * param_ZoomLevel2;
//
//
//            } else {
//
//                if (maxZoomTotal > 2){
//
//                    if (maxZoom > 1.0 && maxZoom <= 2.0){
//                        firstZoom = maxZoom;
//                        secondZoom = maxZoom * 2;
//                    } else
//                        if (maxZoom > 2.0){
//                            firstZoom = 2.0;
//                            secondZoom = 4.0;
//                        }
//
//                }
//            }
//
//
//        }
//
//
//    }
//
////    self.focusTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(reFocus) userInfo:nil repeats:YES];
//}
//
//- (void) onVideoStart: (NSNotification*) note
//{
//    if(running)
//        return;
//    running = YES;
//
//    // lock device and set focus mode
//    NSError *error = nil;
//    if([self.device lockForConfiguration: &error])
//    {
//        if([self.device isFocusModeSupported: AVCaptureFocusModeContinuousAutoFocus])
//            self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
//    }
//}
//
//- (void) onVideoStop: (NSNotification*) note
//{
//    if(!running)
//        return;
//    [self.device unlockForConfiguration];
//    running = NO;
//}
//
//#pragma mark -
//#pragma mark AVCaptureSession delegate
//
//- (void)captureOutput:(AVCaptureOutput *)captureOutput
//didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
//       fromConnection:(AVCaptureConnection *)connection
//{
//    if (state != CAMERA && state != CAMERA_DECODING) {
//        return;
//    }
//
//    if (activeThreads >= availableThreads){
//        return;
//    }
//
//    if (self.state != CAMERA_DECODING)
//    {
//        self.state = CAMERA_DECODING;
//    }
//
//    activeThreads++;
//
//
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    //Lock the image buffer
//    CVPixelBufferLockBaseAddress(imageBuffer,0);
//    //Get information about the image
//    baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
//    int pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
//    switch (pixelFormat) {
//        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
//            //NSLog(@"Capture pixel format=NV12");
//            bytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
//            width = bytesPerRow;//CVPixelBufferGetWidthOfPlane(imageBuffer,0);
//            height = (int) CVPixelBufferGetHeightOfPlane(imageBuffer,0);
//            break;
//        case kCVPixelFormatType_422YpCbCr8:
//            //NSLog(@"Capture pixel format=UYUY422");
//            bytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
//            width = (int) CVPixelBufferGetWidth(imageBuffer);
//            height = (int) CVPixelBufferGetHeight(imageBuffer);
//            int len = width*height;
//            int dstpos=1;
//            for (int i=0;i<len;i++){
//                baseAddress[i]=baseAddress[dstpos];
//                dstpos+=2;
//            }
//
//            break;
//        default:
//            //    NSLog(@"Capture pixel format=RGB32");
//            break;
//    }
//
//
//    unsigned char *frameBuffer = malloc(width * height);
//    memcpy(frameBuffer, baseAddress, width * height);
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//
//
//        unsigned char *pResult=NULL;
//
//        int resLength = MWB_scanGrayscaleImage(frameBuffer,self->width,self->height, &pResult);
//
//        free(frameBuffer);
//
//
//         NSLog(@"Frame decoded. Active threads: %d", self->activeThreads);
//
////        MWResults *mwResults = nil;
////        MWResult *mwResult = nil;
//        if (resLength > 0){
//
//            if (self.state == NORMAL){
//                resLength = 0;
//                free(pResult);
//
//            } else {
////                mwResults = [[MWResults alloc] initWithBuffer:pResult];
////                if (mwResults && mwResults.count > 0){
////                    mwResult = [mwResults resultAtIntex:0];
////                }
//
//                free(pResult);
//            }
//        }
//
//        //CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//
//        //ignore results less than 4 characters - probably false detection
////        if (mwResult)
////        {
//
//
//            self.state = NORMAL;
//            dispatch_async(dispatch_get_main_queue(), ^(void) {
//                [self.captureSession stopRunning];
////#if OVERLAY_MODE == OM_MWOVERLAY
////                [MWOverlay showLocation:mwResult.locationPoints.points imageWidth:mwResult.imageWidth imageHeight:mwResult.imageHeight];
////#endif
////                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
////                DecoderResult *notificationResult = [DecoderResult createSuccess:mwResult];
////                [center postNotificationName:DecoderResultNotification object: notificationResult];
//            });
////
////        }
////        else
////        {
////            self.state = CAMERA;
////        }
//
//
//        self->activeThreads --;
//
//    });
//
//}
//
//#define MAX_IMAGE_SIZE 1600
//
//- (unsigned char*)UIImageToGrayscaleByteArray:(UIImage*)image newWidth: (int*)newWidth newHeight: (int*)newHeight{
//
//    int targetWidth = image.size.width;
//    int targetHeight = image.size.height;
//    float scale = 1.0;
//
//    if (targetWidth > MAX_IMAGE_SIZE || targetHeight > MAX_IMAGE_SIZE){
//        targetWidth /= 2;
//        targetHeight /= 2;
//        scale *= 2;
//
//    }
//
//    *newWidth = targetWidth;
//
//    *newHeight = targetHeight;
//
//    unsigned char *imageData = (unsigned char*)(malloc( targetWidth*targetHeight));
//
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//
//    CGImageRef imageRef = [image CGImage];
//    CGContextRef bitmap = CGBitmapContextCreate( imageData,
//                                                targetWidth,
//                                                targetHeight,
//                                                8,
//                                                targetWidth,
//                                                colorSpace,
//                                                0);
//
//    CGContextDrawImage( bitmap, CGRectMake(0, 0, targetWidth, targetHeight), imageRef);
//
//    CGContextRelease( bitmap);
//
//    CGColorSpaceRelease( colorSpace);
//
//    return imageData;
//
//}
//
//-(void) scanImage:(UIImage *)image {
//    int newWidth, newHeight;
//
//    unsigned char *grayscaleImageArray = [self UIImageToGrayscaleByteArray:image newWidth:&newWidth newHeight:&newHeight];
//    unsigned char *pResult=NULL;
//    int resLength = MWB_scanGrayscaleImage(grayscaleImageArray,newWidth,newHeight, &pResult);
//
//    if (resLength > 0) {
//        MWResults *mwResults = [[MWResults alloc] initWithBuffer:pResult];
//        if (mwResults && mwResults.count > 0){
//            MWResult *mwResult = [mwResults resultAtIntex:0];
//            if (mwResult != nil) {
//                // At this point, you have a successfuly scanned image
//
//            }
//        }
//    }
//}
//
//- (void)dealloc {
//#if !__has_feature(objc_arc)
//    [super dealloc];
//#endif
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
//- (void) startScanning {
//    self.state = LAUNCHING_CAMERA;
//    [self.captureSession startRunning];
//    self.prevLayer.hidden = NO;
//    self.state = CAMERA;
////    if ([self.device isTorchModeSupported:AVCaptureTorchModeOn])
////        [self bringSubviewToFront:flashButton];
////    if (videoZoomSupported){
////        zoomButton.hidden = NO;
////        [self.view bringSubviewToFront:zoomButton];
////    } else {
////        zoomButton.hidden = YES;
////    }
////    [self.view bringSubviewToFront:closeButton];
//    /*  NSError *error;
//     if ([self.device lockForConfiguration:&error]) {
//     [self.device setExposureModeCustomWithDuration:CMTimeMake(1, 10) ISO:AVCaptureISOCurrent completionHandler:nil];
//     [self.device unlockForConfiguration];
//     }*/
//
//}
//
//- (void)stopScanning {
//    [self.captureSession stopRunning];
//    self.state = NORMAL;
//    self.prevLayer.hidden = YES;
//
//
//}
//
- (void)decodeResultNotification: (NSNotification *)notification {
}
    
    //
//    if ([notification.object isKindOfClass:[DecoderResult class]])
//    {
//        DecoderResult *obj = (DecoderResult*)notification.object;
//        if (obj.succeeded)
//        {
//
//            self.state = DECODE_DISPLAY;
//
//
//            NSString *typeName = obj.result.typeName;
//            if (obj.result.isGS1){
//
//                typeName = [NSString stringWithFormat:@"%@ (GS1)", typeName];
//            }
//            NSString *decodeResult;
//
//#if USE_MWPARSER && MWPARSER_MASK != MWP_PARSER_MASK_NONE
//            if(!(MWPARSER_MASK == MWP_PARSER_MASK_GS1 && !obj.result.isGS1)){
//
//
//                unsigned char * parserResult = NULL;
//                double parserRes = -1;
//                NSString *parserMask;
//
//
//
//                //USE THIS CODE FOR JSONFORMATTED RESULT
//
//                parserRes = MWP_getJSON(MWPARSER_MASK, obj.result.encryptedResult, obj.result.bytesLength, &parserResult);
//
//                decodeResult = obj.result.text;
//
//                //use jsonString to get the JSON formatted result
//                if (parserRes >= 0){
//                    decodeResult = [NSString stringWithCString:parserResult encoding:NSUTF8StringEncoding];
//                }
//
//                //
//
//                /*
//                 //USE THIS CODE FOR TEXT FORMATTED RESULT
//
//                 parserRes = MWP_getFormattedText(MWPARSER_MASK, obj.result.encryptedResult, obj.result.bytesLength, &parserResult);
//                 if (parserRes >= 0){
//                 decodeResult = [NSString stringWithCString:parserResult encoding:NSUTF8StringEncoding];
//                 }
//                 */
//                //
//
//
//
//
//
//                NSLog(@"%f",parserRes);
//                if (parserRes >= 0){
//
//                    switch (MWPARSER_MASK) {
//                        case MWP_PARSER_MASK_GS1:
//                            parserMask = @"GS1";
//                            break;
//                        case MWP_PARSER_MASK_IUID:
//                            parserMask = @"IUID";
//                            break;
//                        case MWP_PARSER_MASK_ISBT:
//                            parserMask = @"ISBT";
//                            break;
//                        case MWP_PARSER_MASK_AAMVA:
//                            parserMask = @"AAMVA";
//                            break;
//                        case MWP_PARSER_MASK_HIBC:
//                            parserMask = @"HIBC";
//                            break;
//                        case MWP_PARSER_MASK_SCM:
//                            parserMask = @"SCM";
//                            break;
//                        default:
//                            parserMask = nil;
//                            break;
//                    }
//
//                    if(parserMask)
//                        typeName = [NSString stringWithFormat:@"%@ (%@)", typeName, parserMask];
//
//                }else{
//                    decodeResult = obj.result.text;
//                }
//            }else{
//                decodeResult = obj.result.text;
//            }
//
//
//
//#else
//            decodeResult = obj.result.text;
//#endif
//
//
//            UIAlertView * messageDlg = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Format: %@",typeName] message:decodeResult
//                                                                 delegate:self cancelButtonTitle:nil otherButtonTitles:@"Close", nil];
//            [messageDlg show];
//        }
//    }
//}
//
//
//
////- (instancetype)init {
////    if ((self = [super init])) {
////        NSError *error;
////
////        _activeThreads = 0;
////        _availableThreads = 2; // TODO: Figure this out
////
////        _license = @"";
////        _state = NORMAL;
////        _torch = FALSE;
////        _captureDevice = [self backCamera];
////        _captureOutput = [self setupCaptureOutput];
////        _captureDeviceInput = [self setupCaptureDeviceInput:_captureDevice error:&error];
////        _captureSession = [self setupCaptureSessionWithDevice:_captureDevice captureOutput:_captureOutput];
////        _previewLayer = [self setupPreviewLayerWithCaptureSession:_captureSession];
////
////        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
////        [[NSNotificationCenter defaultCenter]
////         addObserver:self selector:@selector(orientationChanged:)
////         name:UIDeviceOrientationDidChangeNotification
////         object:[UIDevice currentDevice]];
////
////        if (error == nil) {
////            [[self layer] addSublayer: _previewLayer];
////        } else {
////
////        }
////    }
////
////    return self;
////}
////
////-(void)dealloc {
////    [[NSNotificationCenter defaultCenter] removeObserver:self];
////}
////
////- (void) orientationChanged:(NSNotification *)notification {
////    [self updatePreviewLayerOrientation];
////}
////
////- (AVCaptureVideoPreviewLayer *)setupPreviewLayerWithCaptureSession: (AVCaptureSession *)session {
////    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: session];
////
////    [previewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
////
////    return previewLayer;
////}
////
////- (AVCaptureVideoDataOutput *)setupCaptureOutput {
////    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
////
////    [captureOutput setAlwaysDiscardsLateVideoFrames: YES];
////    [captureOutput setSampleBufferDelegate: self queue:dispatch_get_main_queue()];
////
////    NSString *key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
////    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
////    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
////
////    [captureOutput setVideoSettings:videoSettings];
////
////    return captureOutput;
////}
////
////- (AVCaptureSession *)setupCaptureSessionWithDevice:(AVCaptureDevice *)device captureOutput:(AVCaptureOutput *)output {
////
////    NSError *error;
////    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
////    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice: device error: &error];
////
////    if (error == nil) {
////        [captureSession addInput:input];
////        [captureSession addOutput:output];
////
////        if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
////            [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
////            NSLog(@"Set preview port to 1280X720");
////        } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
////            [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
////            NSLog(@"Set preview port to 640x480");
////        } else {
////            NSLog(@"I'm not sure what to do here");
////            abort();
////        }
////    } else {
////        NSLog(@"ERROR: %@", [error localizedDescription]);
////    }
////
////    return captureSession;
////}
////
////- (AVCaptureDeviceInput *)setupCaptureDeviceInput:(AVCaptureDevice *)device error:(NSError **)error {
////    return [[AVCaptureDeviceInput alloc] initWithDevice: device error: error];
////}
////
////- (void)didMoveToWindow {
////    [self startCapturing];
////}
////
////- (void)layoutSubviews {
////    [super layoutSubviews];
////
////    NSLog(@"Laying out the subviews");
////
////    [self updatePreviewLayerFrame];
////}
////
- (void)layoutSubviews {
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
////
////- (void)updatePreviewLayerFrame {
////    _previewLayer.frame = [self frame];
////}
////
////- (BOOL)torch {
////    return _torch;
////}
////
////- (void)setLicense:(NSString *)license {
////    _license = license;
////
////    NSLog(@"SETTING THE LICENSE");
////}
////
////
////- (NSString *)license {
////    return _license;
////}
////
////-(void)startCapturing {
////    NSLog(@"Capturing");
////
////
////
//////        long processorCount = NSProcessInfo.processInfo.processorCount;
////
////
////        [_captureSession startRunning];
////
//////        NSLog(@"Number of processors \(%s)", ProcessInfo.processInfo.processorCount);
////
////
//////    if (processorCount < 2) {
////        //        do {
////        //            try device.lockForConfiguration()
////        //            device.activeVideoMinFrameDuration = CMTimeMake(1, 15)
////        //        } catch { }
////        //        device.unlockForConfiguration()
////        //        DLog("activeVideoMinFrameDuration: \(device.activeVideoMinFrameDuration)")
//////    }
////
////    //
////    //    availableThreads = min(MAX_THREADS, ProcessInfo.processInfo.processorCount)
////    //    activeThreads = 0
////    //
////    //    prevLayer = AVCaptureVideoPreviewLayer(session: captureSession) as AVCaptureVideoPreviewLayer
////    //
////    //    prevLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
////    //    prevLayer.frame = CGRect(x: 0, y: 0, width: min(frame.size.width, frame.size.height), height: max(frame.size.width, frame.size.height))
////    //
////    //    prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
////    //
////    //    layer.addSublayer(prevLayer)
////    //
////    //    setupCustomOverlay()
////    //
////    //    focusTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(reFocus), userInfo: nil, repeats: true)
////}
////
- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }

    return nil;
}
////
////// MARK: -
////// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
////
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
