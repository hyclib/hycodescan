//
//  readerProcess.mm
//  hycodescan
//
//  Created by brainpoint on 12/18/15.
//  Copyright © 2015 citong. All rights reserved.
//

#include <sys/utsname.h>

#import "readerProcess.h"
#import "QRCodeReader.h"
#import "codeScanFilter.hpp"

// 每帧只处理一个图片.
static bool g_needDoOneFrame = false;

inline UIImage* utils_image_fixOrientation(UIImage* image)
{
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@interface ReaderProcess()
{
    bool                _isInFoo;
    bool                _isExit;
    NSSet*              _readers;
    CodeScanViewController* _c;
    Decoder*            _decoder;
}

@end

@implementation ReaderProcess

@synthesize delegate;

- (id)init:(CodeScanViewController*)c
{
    // 判断设备版本.
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([platform isEqualToString:@"iPhone1,1"]) {
        //platform = @"iPhone";
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPhone1,2"]) {
        //platform = @"iPhone 3G";
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPhone2,1"]) {
        //platform = @"iPhone 3GS";
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPhone3,1"]||[platform isEqualToString:@"iPhone3,2"]||[platform isEqualToString:@"iPhone3,3"]) {
        //platform = @"iPhone 4";
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPhone4,1"]) {
        //platform = @"iPhone 4S";
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPhone5,1"]||[platform isEqualToString:@"iPhone5,2"]) {
        //platform = @"iPhone 5";
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPhone5,3"]||[platform isEqualToString:@"iPhone5,4"]) {
        //platform = @"iPhone 5C";
        g_needDoOneFrame = true;
    }
    
    else if ([platform isEqualToString:@"iPad4,7"]||[platform isEqualToString:@"iPad4,8"]||[platform isEqualToString:@"iPad4,9"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad4,4"]||[platform isEqualToString:@"iPad4,5"]||[platform isEqualToString:@"iPad4,6"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad4,1"]||[platform isEqualToString:@"iPad4,2"]||[platform isEqualToString:@"iPad4,3"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad3,4"]||[platform isEqualToString:@"iPad3,5"]||[platform isEqualToString:@"iPad3,6"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad3,3"]||[platform isEqualToString:@"iPad3,2"]||[platform isEqualToString:@"iPad3,1"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad2,5"]||[platform isEqualToString:@"iPad2,6"]||[platform isEqualToString:@"iPad2,7"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad2,1"]||[platform isEqualToString:@"iPad2,2"]||[platform isEqualToString:@"iPad2,3"]||[platform isEqualToString:@"iPad2,4"]) {
        g_needDoOneFrame = true;
    } else if ([platform isEqualToString:@"iPad1,1"]||[platform isEqualToString:@"iPad1,2"]) {
        g_needDoOneFrame = true;
    }
    
    
    self = [super init];
    if (self)
    {
        _c = [c retain];
        _isInFoo = false;
        _isExit = false;
        _readers = [[NSSet alloc] initWithObjects:[[QRCodeReader alloc] init], nil];
        
        _decoder = [[Decoder alloc] init];
        _decoder.readers = _readers;
        _decoder.delegate = self;
        
    }
    return self;
}

- (void)dealloc
{
    if (_c)
        [_c release];
    
    if (_readers) {
        for (int i = 0; i < _readers.allObjects.count; i++) {
            [_readers.allObjects objectAtIndex:i];
        }
        [_readers release];
    }
    
    if (_decoder) {
        _decoder.readers = nil;
        [_decoder release];
    }
    
    [super dealloc];
}


- (void)exit
{
    _isExit = true;
}

- (void)reset
{
    _isInFoo = false;
    _isExit = false;
}

- (void)onCaptureOutput:(CMSampleBufferRef)sampleBuffer
               scanRect:(CGRect)scanRect
               viewRect:(CGRect)viewRect
{
    if (_isInFoo)
        return;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    /*Get information about the image*/
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t height = CVPixelBufferGetWidth(imageBuffer);
    size_t width = CVPixelBufferGetHeight(imageBuffer);
    
    scanRect.size.width = (scanRect.size.width) * width / viewRect.size.width;
    scanRect.size.height = (scanRect.size.height) * height / viewRect.size.height;
    scanRect.size.width = floor(scanRect.size.width);
    scanRect.size.height = floor(scanRect.size.height);
    
    scanRect.size.width /= PHONE_SCALE;
    scanRect.size.height /= PHONE_SCALE;
    
    if (scanRect.size.width > width)
        scanRect.size.width = width;
    if (scanRect.size.height > height)
        scanRect.size.height = height;
    
    scanRect.origin.x = scanRect.origin.x * width / viewRect.size.width;
    scanRect.origin.y = scanRect.origin.y * height / viewRect.size.height;
    scanRect.origin.x = floor(scanRect.origin.x);
    scanRect.origin.y = floor(scanRect.origin.y);
    scanRect.origin.x += width * (PHONE_SCALE-1) / 2;
    scanRect.origin.y += height * (PHONE_SCALE-1) / 2;
    scanRect.origin.x /= PHONE_SCALE;
    scanRect.origin.y /= PHONE_SCALE;
    
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    void* free_me = 0;
    if (true) { // iOS bug?.
        uint8_t* tmp = baseAddress;
        int bytes = bytesPerRow*width;
        free_me = baseAddress = (uint8_t*)malloc(bytes);
        baseAddress[0] = 0xdb;
        memcpy(baseAddress,tmp,bytes);

//        // 加深颜色帮助扫描.
//        for (int i = 0; i < bytes; i++) {
//            uint8_t n = baseAddress[i];
//            
//            if (n < 20)
//                n = 0;
//            else
//                n -= 20;
//            baseAddress[i] = n;
//        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext =
    CGBitmapContextCreate(baseAddress, height, width, 8, bytesPerRow, colorSpace,
                          kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    
    CGImageRef capture = CGBitmapContextCreateImage(newContext);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    free(free_me);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    float t = scanRect.origin.x;
    scanRect.origin.x = scanRect.origin.y;
    scanRect.origin.y = t;
    t = scanRect.size.width;
    scanRect.size.width = scanRect.size.height;
    scanRect.size.height = scanRect.size.width;

    CGImageRef newImage = CGImageCreateWithImageInRect(capture, scanRect);
    CGImageRelease(capture);
    
    static int filterMethodIndex = 0;
    
    if (g_needDoOneFrame)
    {
        filterMethodIndex = (++filterMethodIndex) % 3;
        
        if (0 == filterMethodIndex) {
            UIImage* img0 = filter0Image(newImage);
            if ([_decoder decodeImage:img0])
            {
                [img0 release];
                CGImageRelease(newImage);
                return;
            }
            [img0 release];
        } else if (1 == filterMethodIndex) {
            UIImage* img1 = filter1Image(newImage);
            if ([_decoder decodeImage:img1])
            {
                [img1 release];
                CGImageRelease(newImage);
                return;
            }
            [img1 release];
        } else {
            UIImage* img2 = filter2Image(newImage);
            if ([_decoder decodeImage:img2])
            {
                [img2 release];
                CGImageRelease(newImage);
                return;
            }
            [img2 release];
        }
    }
    else
    {
        UIImage* img0 = filter0Image(newImage);
        if ([_decoder decodeImage:img0])
        {
            [img0 release];
            CGImageRelease(newImage);
            return;
        }
        [img0 release];
        
        UIImage* img1 = filter1Image(newImage);
        if ([_decoder decodeImage:img1])
        {
            [img1 release];
            CGImageRelease(newImage);
            return;
        }
        [img1 release];
        
        UIImage* img2 = filter2Image(newImage);
        if ([_decoder decodeImage:img2])
        {
            [img2 release];
            CGImageRelease(newImage);
            return;
        }
        [img2 release];
    } // if..else.
    
    CGImageRelease(newImage);
    
//    static int i = 0;
//    if (i++ > 25 && i < 30)
//    {
//        NSLog(@"1");
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImageWriteToSavedPhotosAlbum(scrn, nil, nil, nil);
//        });
//    }
}

#pragma mark DecoderDelegate


- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)result
{
    if (_isInFoo)
        return;
    _isInFoo = true;
    
    {
        //NSLog(@"%@", [result text]);
        NSString* code = [result text];
        
        if(code && delegate && [(NSObject*)delegate respondsToSelector:@selector(onScanSuccess:code:)])
        {
            [_c stopCamera];
            [delegate onScanSuccess:_c code:code];
            [_c startCamera];
        }
    }
    
    if (_isExit)
        return;
    
    _isInFoo = false;
}

- (void)decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason
{
    if(delegate && [(NSObject*)delegate respondsToSelector:@selector(onScanSuccess:code:)])
    {
        [delegate onScanSuccess:nil code:nil];
    }
}

@end
