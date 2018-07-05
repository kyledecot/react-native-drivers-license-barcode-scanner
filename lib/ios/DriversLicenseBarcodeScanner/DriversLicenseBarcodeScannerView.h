#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <React/RCTView.h>

@class RCTEventDispatcher;

@interface DriversLicenseBarcodeScannerView : UIView <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) NSString *license;
@property (nonatomic, assign) BOOL torch;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, copy) RCTDirectEventBlock onSuccess;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@end
