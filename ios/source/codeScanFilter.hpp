//
//  codeScanFilter.hpp
//  hycodescan
//
//  Created by brainpoint on 7/30/16.
//  Copyright © 2016 citong. All rights reserved.
//

#ifndef codeScanFilter_h
#define codeScanFilter_h


// 原图.
inline UIImage* filter0Image(CGImageRef image)
{
    UIImage *scrn = [[UIImage alloc] initWithCGImage:image];
    return scrn;
}

// 低亮.
inline UIImage* filter1Image(CGImageRef image)
{
    CIImage* beginImage = [CIImage imageWithCGImage:image];
    CIFilter* filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:beginImage forKey:kCIInputImageKey];
    
    // 亮度.
    [filter setValue:[NSNumber numberWithFloat:-0.12] forKey:@"inputBrightness"];
    // 对比度.
    [filter setValue:[NSNumber numberWithFloat:1.24] forKey:@"inputContrast"];
    
    // 输出.
    CIImage* outputImage = [filter outputImage];
//
//    // 模糊.
//    filter = [CIFilter filterWithName:@"CIGaussianBlur"];
//    [filter setValue:outputImage forKey:kCIInputImageKey];
//    [filter setValue:[NSNumber numberWithFloat:0.8] forKey:@"inputRadius"];
//    outputImage = [filter outputImage];
    
    CIContext* cc = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [cc createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *scrn = [[UIImage alloc] initWithCGImage:cgimg];
    CGImageRelease(cgimg);
    
//    // 保存图片
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIImageWriteToSavedPhotosAlbum(scrn, nil, nil, nil);
//    });

    return scrn;
}

// 高亮.
inline UIImage* filter2Image(CGImageRef image)
{
    CIImage* beginImage = [CIImage imageWithCGImage:image];
    CIFilter* filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:beginImage forKey:kCIInputImageKey];
    
    // 亮度.
    [filter setValue:[NSNumber numberWithFloat:0.13] forKey:@"inputBrightness"];
    // 对比度.
    [filter setValue:[NSNumber numberWithFloat:1.3] forKey:@"inputContrast"];
    
    // 输出.
    CIImage* outputImage = [filter outputImage];
    CIContext* cc = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [cc createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *scrn = [[UIImage alloc] initWithCGImage:cgimg];
    CGImageRelease(cgimg);
    
//    // 保存图片
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIImageWriteToSavedPhotosAlbum(scrn, nil, nil, nil);
//    });
    
    return scrn;
}


#endif /* codeScanFilter_h */
