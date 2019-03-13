//
//  codeScanDecoder.m
//  hycodescan
//
//  Created by brainpoint on 3/19/16.
//  Copyright © 2016 citong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../include/codeScanDecoder.h"
#import "Decoder.h"
#import "TwoDDecoderResult.h"
#import "QRCodeReader.h"
#import "codeScanFilter.hpp"

inline static UIImage* utils_image_set_size(UIImage* image, CGSize size)
{
    UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
}

@interface CodeScanDecoder()
{
    NSSet*              _readers;
    Decoder*            _decoder;
}

@end

@implementation CodeScanDecoder

-(id) init
{
    self = [super init];
    if (self) {
        _readers = [[NSSet alloc] initWithObjects:[[QRCodeReader alloc] init], nil];
        
        _decoder = [[Decoder alloc] init];
        _decoder.readers = _readers;
        _decoder.delegate = nil;
    }
    return self;
}

- (void)dealloc
{
    if (_readers) {
        for (int i = 0; i < _readers.allObjects.count; i++) {
            [_readers.allObjects objectAtIndex:i];
        }
        [_readers release];
    }
    
    if (_decoder)
        [_decoder release];

    [super dealloc];
    
}

- (NSString*) decodeImage:(UIImage*)img
{
    NSString* ss = [self decodeImage:img cropRect:CGRectMake(0, 0, img.size.width, img.size.height)];
    return ss;
}

- (NSString*) decodeImage:(UIImage*)img cropRect:(CGRect)cr
{
    UIImage* pImg = img;
    //UIImage* ppImg = nil;
    if (pImg.size.width > MAX_PIC_SIZE || pImg.size.height > MAX_PIC_SIZE) {
        float factor = MAX_PIC_SIZE / MAX(pImg.size.width, pImg.size.height);
        CGSize s = CGSizeMake(floor(pImg.size.width*factor), floor(pImg.size.height*factor));
        cr.origin = CGPointMake(floor(cr.origin.x*factor), floor(cr.origin.y*factor));
        cr.size = CGSizeMake(floor(cr.size.width*factor), floor(cr.size.height*factor));
        pImg = utils_image_set_size(pImg, s);
        //ppImg = pImg;
    }
    
    NSString* ret = nil;
    UIImage* img0 = filter0Image(pImg.CGImage);
    ret = [_decoder decodeImageRet:img0 cropRect:cr];
    if (nil != ret)
    {
        [img0 release];
        return ret;
    }
    [img0 release];
    
    UIImage* img1 = filter1Image(pImg.CGImage);
    ret=[_decoder decodeImageRet:img1 cropRect:cr];
    if (nil != ret)
    {
        [img1 release];
        return ret;
    }
    [img1 release];
    
    UIImage* img2 = filter2Image(pImg.CGImage);
    ret=[_decoder decodeImageRet:img2 cropRect:cr];
    if (nil != ret)
    {
        [img2 release];
        return ret;
    }
    [img2 release];
    
    return ret;
}

@end
