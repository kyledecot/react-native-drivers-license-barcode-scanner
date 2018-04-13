//
//  DriversLicenseBarcodeScannerManager.m
//  DriversLicenseBarcodeScanner
//
//  Created by Kyle Decot on 4/13/18.
//  Copyright © 2018 Christopher. All rights reserved.
//
#import <MapKit/MapKit.h>
#import "DriversLicenseBarcodeScannerManager.h"

@implementation DriversLicenseBarcodeScannerManager

RCT_EXPORT_MODULE()

- (UIView *)view {
    return [[MKMapView alloc] init];
}

@end
