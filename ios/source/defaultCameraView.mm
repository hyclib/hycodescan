//
//  DefaultCameraView.m
//  zbar
//
//  Created by brainpoint on 14-8-9.
//
//

#import "DefaultCameraView.h"
#import "utils_camera.h"

@interface DefaultCameraView()
{
    NSTimer*    timer;
    UIImage*    bgImage;
    UIImage*    barImage;
    UIImageView* barImageView;
    UIImageView* barScanView;
    UILabel*     label;
    UIButton*     flash;
}
@end

@implementation DefaultCameraView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scanRect.size.width = 200;
        _scanRect.size.height = 200;
        _scanRect.origin.y = 100;
        
        timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
        [timer fire];
        [self onTimer:nil];
        
    }
    return self;
}

//- (void) dealloc
//{
//    [bgImage dealloc];
//    bgImage = nil;
//    [timer dealloc];
//    timer = nil;
//    [barImage dealloc];
//    barImage = nil;
//    [barImageView dealloc];
//    barImageView = nil;
//    [super dealloc];
//}

//- (void) setFrame:(CGRect)frame
//{
//    [super setFrame:frame];
//}

- (void) setScanRect:(CGRect)scanRect
{
    _scanRect = scanRect;
    _scanRect.origin.x += 10;
    _scanRect.origin.y += 10;
    _scanRect.size.width -= 20;
    _scanRect.size.height -= 20;
    
    bgImage = [self getShowImage];
    if (!barScanView)
    {
        barScanView = [[UIImageView alloc] initWithImage:bgImage];
        [self addSubview:barScanView];
    }
    barScanView.image = bgImage;
    barScanView.frame = self.bounds;
    
    if (!label)
    {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, _scanRect.origin.y+_scanRect.size.height+10, self.frame.size.width, 15)];
        label.textColor = [UIColor colorWithRed:0xd6/255.0 green:0xd6/255.0 blue:0xd6/255.0 alpha:1];
        label.text      = @"Put the barcode to scan";
        NSLocale *locale = [NSLocale currentLocale];
        NSString *localName = [locale localeIdentifier];
        if ([localName isEqualToString:@"zh-Hant"])
        {
            label.text      = @"將二維碼放入框內，即可自動掃描";
        }
        else if ([localName isEqualToString:@"zh-Hans"]
                 || [localName isEqualToString:@"zh_CN"]
                 || [localName rangeOfString:@"zh"].location == 0)
        {
            label.text      = @"将二维码放入框内，即可自动扫描";
        }
        
        label.font      = [UIFont systemFontOfSize:13];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        flash = [[UIButton alloc] init];
        UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"data:image/png;base64,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"]]];
        [flash setImage:image forState:UIControlStateNormal];
        [flash setImage:image forState:UIControlStateSelected];
        [flash addTarget:self action:@selector(tapFlash:) forControlEvents:UIControlEventTouchUpInside];
//        flash.layer.borderColor = [UIColor blackColor].CGColor;
//        flash.layer.borderWidth = 1;
//        flash.layer.cornerRadius = 13;
        [self addSubview:flash];
    }
    label.frame = CGRectMake(0, _scanRect.origin.y+_scanRect.size.height+13, self.frame.size.width, 15);
    flash.frame = CGRectMake((self.frame.size.width-26)/2, label.frame.origin.y+label.frame.size.height+10, 26, 26);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    
    CGContextRef context = CGBitmapContextCreate(nil, scanRect.size.width, 3, 8, 0, colorSpace, bitmapInfo);
    CGContextSetRGBFillColor(context, 0,1,0,1);
    CGContextSetAlpha(context, 0.8);
    CGContextFillEllipseInRect(context, CGRectMake(0, 0, scanRect.size.width, 3));
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    barImage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    if (!barImageView)
    {
        barImageView = [[UIImageView alloc] initWithImage:barImage];
        [self addSubview:barImageView];
    }
    CGRect r;
    r.origin.y = _scanRect.origin.y+6;
    r.origin.x = _scanRect.origin.x;
    r.size.width = _scanRect.size.width;
    r.size.height = 3;
    barImageView.frame = r;
    barImageView.image = barImage;
    
    if (timer)
        [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [timer fire];
}

- (void) tapFlash:(id)sender
{
    static bool on = false;
    on = !on;
    hyc::utils_camera_trunOnTorch(on);
}

- (void) onTimer:(NSTimer*)timer
{
    //dispatch_async(dispatch_get_main_queue(), ^{
        CGRect r = barImageView.frame;
        r.origin.y = _scanRect.origin.y + 6;
        r.origin.x = _scanRect.origin.x;
        r.size.width = _scanRect.size.width;
        r.size.height = 3;
        barImageView.frame = r;
        
        [UIView beginAnimations:nil context:(__bridge void * _Nullable)(barImageView)];
        [UIView setAnimationDuration:2];
        CGRect r1 = barImageView.frame;
        r1.origin.y = _scanRect.origin.y-12+_scanRect.size.height;
        barImageView.frame = r1;
        [UIView commitAnimations];
    //});
}


- (UIImage *)getShowImage {
    CGSize size = _scanRect.size;
    size.width *= [[UIScreen mainScreen] scale];
    size.height *= [[UIScreen mainScreen] scale];
    CGPoint orgin = _scanRect.origin;
    orgin.x *= [[UIScreen mainScreen] scale];
    orgin.y *= [[UIScreen mainScreen] scale];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat w = self.frame.size.width * [[UIScreen mainScreen] scale];
    CGFloat h = self.frame.size.height * [[UIScreen mainScreen] scale];
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
    {
        h += 20;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    CGContextRef context = CGBitmapContextCreate(nil, w, h, 8, 0, colorSpace, bitmapInfo);
    CGContextSetRGBFillColor(context, 0,0,0,1);
    CGContextSetAlpha(context, 0.5);
    
    CGFloat lineWidth = 4 * [[UIScreen mainScreen] scale];
    CGFloat lineLength = 12 * [[UIScreen mainScreen] scale];
    
    size.width -= lineWidth*2;
    size.height -= lineWidth*2;
    orgin.x += lineWidth;
    orgin.y += lineWidth;
    
    int index = 0;
    CGRect rects[4];
    if (orgin.y > 0)
    {
        rects[index++] = CGRectMake(0, h-orgin.y, w, orgin.y);
    }
    if (orgin.x > 0)
    {
        rects[index++] = CGRectMake(0, h-orgin.y-size.height, orgin.x, size.height);
    }
    if (orgin.x + size.width < w)
    {
        rects[index++] = CGRectMake(orgin.x+size.width, h-orgin.y-size.height, w-orgin.x-size.width, size.height);
    }
    if (orgin.y+size.height < h)
    {
        rects[index++] = CGRectMake(0, 0, w, h-orgin.y-size.height);
    }
    
    CGContextClipToRects(context, rects, index);
    CGContextFillRect(context, CGRectMake(0, 0, w, h));
    CGContextSetAlpha(context, 1);
    
    size = _scanRect.size;
    size.width *= [[UIScreen mainScreen] scale];
    size.height *= [[UIScreen mainScreen] scale];
    orgin = _scanRect.origin;
    orgin.x *= [[UIScreen mainScreen] scale];
    orgin.y *= [[UIScreen mainScreen] scale];
    
    float yoffset = orgin.y;
//    CGContextBeginPath(context);
//    CGContextSetAllowsAntialiasing(context, true);
//    CGContextSetLineWidth(context, 0.5);
//    CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
//    CGRect rect = CGRectMake(orgin.x, h-yoffset-size.height, size.width, size.height);
//    CGContextAddRect(context, rect);
//    CGContextStrokePath(context);
//    //CGContextClosePath(context);
    
    CGContextBeginPath(context);
    CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
    CGContextSetLineWidth(context, lineWidth);
    CGContextMoveToPoint(context,   orgin.x+lineWidth, h-yoffset-lineLength-lineWidth);
    CGContextAddLineToPoint(context,orgin.x+lineWidth, h-yoffset-lineWidth);
    CGContextAddLineToPoint(context,orgin.x+lineLength+lineWidth, h-yoffset-lineWidth);
    
    CGContextMoveToPoint(context,   orgin.x+lineWidth, (h-size.height-yoffset+lineLength)+lineWidth);
    CGContextAddLineToPoint(context,orgin.x+lineWidth, (h-size.height-yoffset)+lineWidth);
    CGContextAddLineToPoint(context,orgin.x+lineLength+lineWidth, (h-size.height-yoffset)+lineWidth);
    
    CGContextMoveToPoint(context,   orgin.x+size.width-lineWidth, h-yoffset-lineLength-lineWidth);
    CGContextAddLineToPoint(context,orgin.x+size.width-lineWidth, h-yoffset-lineWidth);
    CGContextAddLineToPoint(context,orgin.x+size.width-lineLength-lineWidth, h-yoffset-lineWidth);
    
    CGContextMoveToPoint(context,   orgin.x+size.width-lineWidth, (h-size.height-yoffset+lineLength)+lineWidth);
    CGContextAddLineToPoint(context,orgin.x+size.width-lineWidth, (h-size.height-yoffset)+lineWidth);
    CGContextAddLineToPoint(context,orgin.x+size.width-lineLength-lineWidth, (h-size.height-yoffset)+lineWidth);
    CGContextStrokePath(context);
    //CGContextClosePath(context);

    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *showImage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    return showImage;
}

@end
