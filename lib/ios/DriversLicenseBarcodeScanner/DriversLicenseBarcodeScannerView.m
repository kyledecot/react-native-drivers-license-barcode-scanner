//
//  DriversLicenseBarcodeScannerView.m
//  DriversLicenseBarcodeScanner
//
//  Created by Kyle Decot on 4/13/18.
//  Copyright © 2018 Christopher. All rights reserved.
//

#import "DriversLicenseBarcodeScannerView.h"

@implementation DriversLicenseBarcodeScannerView

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame: frame]) {
        [self startCapturing];
    }
    
    return self;
}

-(void)startCapturing {
    NSLog(@"Capturing");
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    
    AVCaptureOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
//    captureOutput.alwaysDiscardsLateVideoFrames = true
//    captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        //    let videoSettings: [String: NSNumber] = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as Int)]
    //    captureOutput.videoSettings = videoSettings

    
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
        [previewLayer setFrame: CGRectMake(0, 0, 500, 500)]; // TODO: how do I get full screen in all orientations?
        [previewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
        
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

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    NSLog(@"Captured BUFFER");
    
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
