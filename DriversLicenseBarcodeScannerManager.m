//
//  DriversLicenseBarcodeScanner.m
//  DriversLicenseBarcodeScanner
//
//  Created by Kyle Decot on 4/12/18.
//  Copyright © 2018 Kyle Decot. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <React/RCTViewManager.h>

@interface DriversLicenseBarcodeScannerManager : RCTViewManager
@end

@implementation DriversLicenseBarcodeScannerManager

RCT_EXPORT_MODULE();

- (UIView *)view {
    return [[MKMapView alloc] init];
}

@end
