//
//  DriversLicenseBarcodeScannerView.m
//  DriversLicenseBarcodeScanner
//
//  Created by Kyle Decot on 4/13/18.
//  Copyright © 2018 Christopher. All rights reserved.
//

#import "DriversLicenseBarcodeScannerView.h"

@implementation DriversLicenseBarcodeScannerView {
    NSString *_license;
    BOOL _flash;
    AVCaptureDevice *_device;
}

@synthesize license;

- (instancetype)init
{
    if ((self = [super init])) {
        _license = @"";
        _flash = FALSE;
        
    }
    
    return self;
}

- (void)didMoveToWindow {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:)name:UIDeviceOrientationDidChangeNotification object:nil];
    // TODO: How/when do I remove this observer?

    NSLog(@"DID MOVE TO WINDOW");
    NSLog(@"WINDOW FRAME: %@", NSStringFromCGRect(self.window.frame));
    
    
    [self startCapturing];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSLog(@"NEW FRAME: %@", NSStringFromCGRect(self.frame));
}

- (void) didRotate:(NSNotification *)notificationl
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSLog(@"WE ROTATED");
    [self startCapturing];
}

- (void)setFlash:(BOOL)flash {
    _flash = flash;
    
    [self setTorch:flash];
    
    NSLog(@"SETTING THE FLASH");
}

- (BOOL)flash {
    return _flash;
}

- (void)setLicense:(NSString *)license {
    _license = license;
    
    NSLog(@"SETTING THE LICENSE");
}

- (void)setTorch:(bool) torchOn {
    NSLog(@"TURN THE TORCH");
    
    if ([self.device isTorchModeSupported: AVCaptureTorchModeOn]) {
        NSError *error;
        
        if ([self.device lockForConfiguration:&error]) {
            if (torchOn)
                [self.device setTorchMode:AVCaptureTorchModeOn];
            else
                [self.device setTorchMode:AVCaptureTorchModeOff];
            [self.device unlockForConfiguration];
        } else {
            
        }
    }
}

- (NSString *)license {
    return _license;
}



-(void)startCapturing {
    NSLog(@"Capturing");
    
    AVCaptureDevice *device = [self backCamera];
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [captureOutput setAlwaysDiscardsLateVideoFrames: YES];
    [captureOutput setSampleBufferDelegate: self queue:dispatch_get_main_queue()];

    NSString *key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    
    if (error != nil) {
        NSLog(@"ERROR: %@", error);
    } else {
        [captureSession addInput: input];
        
        [captureSession addOutput:captureOutput];
        
        if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            NSLog(@"Set preview port to 1280X720");
        } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            NSLog(@"Set preview port to 640x480");
        }
        
        long processorCount = NSProcessInfo.processInfo.processorCount;

        
        AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: captureSession];
        [previewLayer setFrame: self.frame]; // TODO: how do I get full screen in all orientations?
        [previewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
        
        NSLog(@"%@", NSStringFromCGRect(self.frame));
        
        [[self layer] addSublayer: previewLayer];
        
        [captureSession startRunning];
 
//        NSLog(@"Number of processors \(%s)", ProcessInfo.processInfo.processorCount);
        
        
        if (processorCount < 2) {
            //        do {
            //            try device.lockForConfiguration()
            //            device.activeVideoMinFrameDuration = CMTimeMake(1, 15)
            //        } catch { }
            //        device.unlockForConfiguration()
            //        DLog("activeVideoMinFrameDuration: \(device.activeVideoMinFrameDuration)")
        }
       
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

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
//    NSLog(@"Captured BUFFER");
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
//    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLock<#CVPixelBufferLockFlags lockFlags#>)
    
    CVPixelBufferRef baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
}

//func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//    guard (state == .active || state == .decoding) && activeThreads < availableThreads else {
//        return
//    }
//
//    registerDecoder(username: iosManateeWorksScannerUsername!, key: iosManateeWorksScannerKey!)
//    setupDecoder()
//
//    if state != .decoding {
//        state = .decoding
//    }
//
//    activeThreads += 1
//
//    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)! as CVPixelBuffer
//
//    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
//
//    //Get information about the image
//    let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
//
//    let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
//    let width: Int32 = Int32(bytesPerRow)
//    let height: Int32 = Int32(CVPixelBufferGetHeightOfPlane(pixelBuffer, 0))
//
//    let frameBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(width * height))
//    frameBuffer.initialize(from: UnsafeMutablePointer<UInt8>(baseAddress!.assumingMemoryBound(to: UInt8.self)), count: Int(width * height))
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
//
//    DispatchQueue.global(qos: .default).async {
//        var resLength: Int32 = 0
//
//        var pResult: UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
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
//            DispatchQueue.main.async {
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
//        self.activeThreads -= 1
//    }
//}

@end
