//
//  DriversLicenseBarcodeScannerView.h
//  DriversLicenseBarcodeScanner
//
//  Created by Kyle Decot on 4/13/18.
//  Copyright © 2018 Christopher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface DriversLicenseBarcodeScannerView : UIView<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) NSString *license;
//@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, assign) BOOL flash;
@property (nonatomic, retain) AVCaptureDevice *device;

-(void)startCapturing;

@end
