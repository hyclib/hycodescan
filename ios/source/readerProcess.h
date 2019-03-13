//
//  readerProcess.h
//  hycodescan
//
//  Created by brainpoint on 12/18/15.
//  Copyright © 2015 citong. All rights reserved.
//

#ifndef readerProcess_h
#define readerProcess_h


#import "Decoder.h"
#import "TwoDDecoderResult.h"
#import "../include/codeScanViewController.h"

@interface ReaderProcess : NSObject
<
DecoderDelegate
>

@property (nonatomic, assign) id<CodeScanDelegate>  delegate;

- (id)init:(CodeScanViewController*)c;

- (void)reset;
- (void)exit;

- (void)onCaptureOutput:(CMSampleBufferRef)sampleBuffer
               scanRect:(CGRect)scanRect
               viewRect:(CGRect)viewRect;
@end

#endif /* readerProcess_h */
