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
}

@end
