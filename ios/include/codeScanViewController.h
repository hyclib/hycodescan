//
// Copyright(c) 1999-2014 hyrj. All rights reserved.
// qrcode.
// author:       lipengxiang
// description:  the view controller of qrcode
//


#import <UIKit/UIKit.h>

enum CodeScanType
{
    CodeScanType_All,
    CodeScanType_BarCode,
    CodeScanType_QRCode,
};

@class CodeScanViewController;

//-----------------------------------------------
// the delegate of qrcode view.
//-----------------------------------------------
@protocol CodeScanDelegate

- (void) onScanSuccess: (CodeScanViewController*)controller
                  code: (NSString*)code;

@optional

- (void) onScanViewWillAppear: (CodeScanViewController*)controller;
- (void) onScanViewWillDisappear: (CodeScanViewController*)controller;

- (void) onScanRectChange : (CodeScanViewController*)controller;
- (void) onScanViewTransition:(CodeScanViewController*)controller size:(CGSize)size;  // viewController 将旋转等变化.

@end


//-----------------------------------------------
// the simple view.
//-----------------------------------------------
@interface CodeScanViewController : UIViewController

/**
 * or call [self dismissViewControllerAnimated:YES completion:nil];
 * or call [self.navigationController popViewControllerAnimated:YES];
 */
- (void) cancel;
- (void) start;
- (void) stop;

- (void) toggleCamera;
- (void) trunOnTorch: (BOOL)on;

@property (nonatomic, assign) id<CodeScanDelegate>  delegate;
@property (nonatomic, assign) CGRect                scanRect;
@property (nonatomic, retain) UIView*               cameraOverlayView;
@property (nonatomic, assign) enum CodeScanType     codeScanType;         // default is All.

- (void) startCamera;
- (void) stopCamera;

@end
