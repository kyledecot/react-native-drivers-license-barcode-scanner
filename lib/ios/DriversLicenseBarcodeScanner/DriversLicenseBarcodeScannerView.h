#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@interface DriversLicenseBarcodeScannerView : UIView<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) NSString *license;
@property (nonatomic, assign) BOOL torch;
@property (nonatomic, assign) BOOL active;

@end
