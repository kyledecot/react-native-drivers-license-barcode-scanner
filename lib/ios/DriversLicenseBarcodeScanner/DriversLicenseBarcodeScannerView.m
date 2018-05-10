#import "DriversLicenseBarcodeScannerView.h"
#import "UIView+React.h"
#import "BarcodeScanner.h"

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
    DriversLicenseBarcodeScannerViewState _state;
    int _activeThreads;
    int _availableThreads;
    
}

- (instancetype)init {
    if ((self = [super init])) {
        NSError *error;

        _activeThreads = 0;
        _availableThreads = 2; // TODO: Figure this out
        
        _license = @"";
        _state = kReady;
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
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
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
    if ((_state != kActive || _state != kDecoding) && _activeThreads >= _availableThreads) {
        return;
    }

    //
    //    registerDecoder(username: iosManateeWorksScannerUsername!, key: iosManateeWorksScannerKey!)
    //    setupDecoder()
    //

    if (_state != kDecoding) {
        _state = kDecoding;
    }

    _activeThreads ++;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    CVPixelBufferRef baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    long bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int width = (int) bytesPerRow;
    int height = (int) CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    unsigned char *frameBuffer = malloc(width * height);
    memcpy(frameBuffer, baseAddress, width * height);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        unsigned char *pResult = NULL;
        
        int resLength = MWB_scanGrayscaleImage(frameBuffer,width,height, &pResult);
        free(frameBuffer);

        //
        //        resLength = MWB_scanGrayscaleImage(frameBuffer, width, height, &pResult)
        //
        //        frameBuffer.deallocate(capacity: Int(width * height))
        //
        //        var mwResults: MWResults! = nil
        //        var mwResult: MWResult! = nil
        //        if resLength > 0 {
        //            if self.state == .standby {
        //                resLength = 0
        //                free(pResult)
        //            } else {
        //                mwResults =  MWResults(buffer: pResult, length: Int(resLength))
        //                if mwResults != nil && mwResults.count > 0 {
        //                    mwResult = mwResults.results.object(at: 0) as! MWResult
        //                }
        //                free(pResult)
        //            }
        //        }
        //
        //        if let mwResult = mwResult {
        //            self.state = .standby
        //
        //            self.captureSession.stopRunning()
        //

        dispatch_async(dispatch_get_main_queue(), ^{
//            [self->_captureSession stopRunning];
            //                self.captureSession.stopRunning()
            //
            //                let license = DriverLicense()
            //                let success = license.parseDLString(mwResult.text, hideSerialAlert: false)
            //                if !success {
            //                    Analytics.driverLicenseParseError(rawLicense: mwResult.text)
            //                }
            //                self.fireOnLicenseScanned(driverLicense: license, barcode: mwResult.text, parsed: success)
            //            }
            //        } else {
            //            self.state = .active
            //        }
            self->_activeThreads --;
        });
    });
}

@end
