#import <MapKit/MapKit.h>
#import "DriversLicenseBarcodeScannerManager.h"

@implementation DriversLicenseBarcodeScannerManager

RCT_EXPORT_MODULE()

- (UIView *)view {
    return [[MKMapView alloc] init];
}

@end
