//
// Copyright(c) 1999-2014 hyrj. All rights reserved.
// qrcode.
// author:       lipengxiang
// description:  the view controller of qrcode
//


#import <UIKit/UIKit.h>
#import "codeScanViewController.h"

@interface CodeScanDecoder : NSObject

- (NSString*) decodeImage:(UIImage*)img;
- (NSString*) decodeImage:(UIImage*)img cropRect:(CGRect)cr;

@end
