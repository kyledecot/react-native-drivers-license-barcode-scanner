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

-(void)startCapturing;

@end
