#import <MapKit/MapKit.h>
#import "DriversLicenseBarcodeScannerManager.h"
#import "DriversLicenseBarcodeScannerView.h"

@implementation DriversLicenseBarcodeScannerManager

RCT_EXPORT_MODULE()

// RCT_EXPORT_VIEW_PROPERTY(onSuccess, RCTBubblingEventBlock)
// RCT_EXPORT_VIEW_PROPERTY(onError, RCTBubblingEventBlock)
// RCT_EXPORT_VIEW_PROPERTY(license, NSString)

//RCT_EXPORT_METHOD(forceTimeout: (nonnull NSNumber *)reactTag)
//{
//    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
//        UIView *view = viewRegistry[reactTag];
//        if (![view isKindOfClass:[BarcodeScannerView class]]) {
//            RCTLog(@"expecting UIView, got: %@", view);
//        } else {
//            BarcodeScannerView *scanner = (BarcodeScannerView *)view;
//            [scanner forceTimeout];
//        }
//    }];
//}

- (UIView *)view
{
    return [[DriversLicenseBarcodeScannerView alloc] initWithFrame:CGRectZero];
}

@end
