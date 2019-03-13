//
// Copyright(c) 1999-2014 hyrj. All rights reserved.
// qrcode.
// author:       lipengxiang
// description:  the view controller of qrcode
//

#include <sys/time.h>
#import "../include/codeScanViewController.h"
#import "../include/codeScanDecoder.h"
#import "utils_camera.h"
#import "defaultCameraView.h"
#import "readerProcess.h"
#import <MobileCoreServices/MobileCoreServices.h>

static UInt64 GetMilliseconds()
{
    struct timeval tm;
    if ( 0 != gettimeofday(&tm, NULL) )
        return 0;
    
    return (tm.tv_sec) * 1000 + (tm.tv_usec)/1000;
}

@interface CodeScanViewController()
<
AVCaptureVideoDataOutputSampleBufferDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIAlertViewDelegate
>
{
    BOOL                _srcInteractivePopGestureRecognizer;
    hyc::CameraData     _cameraData;
    ReaderProcess*      _process;
    UInt64              _preScan;
    NSTimer*            _timerFocus;
    
    UIImage*            _pickerImage;
    CGFloat             _srcScreenBright;
}
@end

@implementation CodeScanViewController
@synthesize delegate = _delegate;

- (void)setDelegate:(id<CodeScanDelegate>)delegate
{
    _delegate = delegate;
    _process.delegate = delegate;
}

- (id)init
{
    self = [super init];
    if(!self)
        return(nil);
    
    [self _init];
    return(self);
}

- (id)initWithCoder: (NSCoder*) decoder
{
    self = [super initWithCoder: decoder];
    if(!self)
        return(nil);
    
    [self _init];
    return(self);
}

- (void)recoverScreenBright
{
    
//    // 屏幕亮度调节.
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        
//        const float INTERVAL   = 3;
//        float b = [UIScreen mainScreen].brightness;
//        while (b > _srcScreenBright) {
//            b -= 0.02;
//            if (b < 0)
//                b = 0;
//            
//            [UIScreen mainScreen].brightness = b;
//            [NSThread sleepForTimeInterval:INTERVAL / 100.0];
//        } // while.
    @synchronized (self) {
        [UIScreen mainScreen].brightness = _srcScreenBright;
    }
    
//    });
}

- (void)setScreenBright
{
    //
    // 屏幕亮度调节.
    _srcScreenBright = [UIScreen mainScreen].brightness;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        @synchronized (self) {
            const float BRIGHTNESS = 0.8;
            const float INTERVAL   = 3;
            while ([UIScreen mainScreen].brightness < BRIGHTNESS) {
                [UIScreen mainScreen].brightness = [UIScreen mainScreen].brightness+0.02;
                [NSThread sleepForTimeInterval:INTERVAL / 100.0];
            } // while.
            //[UIScreen mainScreen].brightness = BRIGHTNESS;
        }
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    if(_delegate && [(NSObject*)_delegate respondsToSelector:@selector(onScanViewWillAppear:)])
    {
        [_delegate onScanViewWillAppear:self];
    }
    _preScan = 0;
    NSString* preset = AVCaptureSessionPresetHigh;
//    if (self.view.bounds.size.width >= 1280)
//    {
//        preset = AVCaptureSessionPreset1280x720;
//    }
//    else if (self.view.bounds.size.width >= 640)
//    {
//        preset = AVCaptureSessionPreset640x480;
//    }
//    else if (self.view.bounds.size.width >= 320)
//    {
//        preset = AVCaptureSessionPreset352x288;i
//    }
    
    [self installDeivceCapture:preset];
    
    if ([self isPhotoLibraryAvailable]) {
        if (self.navigationItem) {
            NSLocale *locale = [NSLocale currentLocale];
            NSString *localName = [locale localeIdentifier];
            NSString *key = @"Album";
            if ([localName isEqualToString:@"zh-Hant"])
            {
                key      = @"相冊";
            }
            else if ([localName isEqualToString:@"zh-Hans"]
                || [localName isEqualToString:@"zh_CN"]
                || [localName rangeOfString:@"zh"].location == 0)
            {
                key      = @"相册";
            }
            
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(key, nil) style:UIBarButtonItemStylePlain target:self action:@selector(pickFromPicture:)];
        }
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    // 解码相册图片.
    [self decodePicker];
    
    [self setScreenBright];
    //NSLog(@"aaaa %f", _srcScreenBright);
    
    if (self.navigationController)
    {
        _srcInteractivePopGestureRecognizer = self.navigationController.interactivePopGestureRecognizer.enabled;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

//- (void)viewDidDisappear:(BOOL)animated
//{
//    //
//    // 屏幕亮度调节.
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        
//        //        const float INTERVAL   = 3;
//        //        float b = [UIScreen mainScreen].brightness;
//        //        while (b > _srcScreenBright) {
//        //            b -= 0.02;
//        //            if (b < 0)
//        //                b = 0;
//        //
//        //            [UIScreen mainScreen].brightness = b;
//        //            [NSThread sleepForTimeInterval:INTERVAL / 100.0];
//        //        } // while.
//        [UIScreen mainScreen].brightness = _srcScreenBright;
//    });
//    
//}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.navigationController)
    {
        self.navigationController.interactivePopGestureRecognizer.enabled = _srcInteractivePopGestureRecognizer;
    }
    
    [self recoverScreenBright];
    
    if(_delegate && [(NSObject*)_delegate respondsToSelector:@selector(onScanViewWillDisappear:)])
    {
        [_delegate onScanViewWillDisappear:self];
    }
    
    @synchronized(self) {
        [self uninstallDeiveCapture];
    }
    
    hyc::utils_camera_trunOnTorch(false);
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [_process reset];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         if (_cameraOverlayView && [_cameraOverlayView isKindOfClass:[DefaultCameraView class]])
         {
             
             CGRect rect = _cameraOverlayView.frame;
             rect.size = size;
             _cameraOverlayView.frame = rect;
             
             float ww;
             if (size.width >= 414)
                 ww = 270;
             else
                 ww = size.width * 4 / 6;
             
             float w = MIN(ww, MIN(size.width, size.height));
             float t = MIN(100, (size.height-w)/2);
             t = t > 0 ? t : 0;
             _scanRect = CGRectMake((size.width-w)/2, t, w, w);
             ((DefaultCameraView*)_cameraOverlayView).scanRect = _scanRect;
         }
         utils_camera_remove_layer_all(_cameraData);
         utils_camera_install_layer(_cameraData, self.view, self.interfaceOrientation);
         utils_camera_start(_cameraData);
         
         if(_delegate && [(NSObject*)_delegate respondsToSelector:@selector(onScanViewTransition:size:)])
         {
             [_delegate onScanViewTransition:self size:size];
         }
     }];
}
//
//- (void)viewDidLayoutSubviews
//{
//}

- (void)_init
{
    _process = [[ReaderProcess alloc] init:self];
    _codeScanType = CodeScanType_All;
    
    float ww;
    if ([UIScreen mainScreen].bounds.size.width >= 414)
        ww = 256;
    else
        ww = [UIScreen mainScreen].bounds.size.width * 4 / 6;
    
    float w = MIN(ww, MIN(self.view.bounds.size.width, self.view.bounds.size.height));
    float t = MIN(100, (self.view.bounds.size.height-w)/2);
    t = t > 0 ? t : 0;
    _scanRect = CGRectMake((self.view.bounds.size.width-w)/2, t, w, w);
    //_scanRect = CGRectMake(30, 130, 250, w);
    
    self.cameraOverlayView = nil;
    //[self installDeivceCapture];
    
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)]];
}

- (void)tapView:(UITapGestureRecognizer*)sender
{
    [self setFocus:[sender locationInView:self.view]];
}

- (void)setFocus:(CGPoint)pt1
{
    // 自动对焦.
    AVCaptureDevice  *captureDevice = _cameraData.deviceVideo;
    if (!captureDevice)
        return;
    
    //先进行判断是否支持控制对焦
    if (captureDevice.isFocusPointOfInterestSupported &&
        [captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        
        NSError *error = nil;
        //对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
        [captureDevice lockForConfiguration:&error];
        [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        
        if (pt1.x < _scanRect.origin.x)
            pt1.x = _scanRect.origin.x;
        if (pt1.x > _scanRect.origin.x + _scanRect.size.width)
            pt1.x = _scanRect.origin.x + _scanRect.size.width;
        if (pt1.y < _scanRect.origin.y)
            pt1.y = _scanRect.origin.y;
        if (pt1.y > _scanRect.origin.y + _scanRect.size.height)
            pt1.y = _scanRect.origin.y + _scanRect.size.height;
        
        CGPoint pt;
        pt.y = pt1.y / self.view.bounds.size.height;
        pt.x = pt1.x / self.view.bounds.size.width;
        
#ifdef DEBUG
        NSLog(@"set focus: %f %f", pt.x, pt.y);
#endif
        [captureDevice setFocusPointOfInterest:pt];
        //操作完成后，记得进行unlock。
        [captureDevice unlockForConfiguration];
    }
}

- (void) onTimerFocus:(NSTimer*)timer
{
    [self setFocus:CGPointMake(_scanRect.origin.x+_scanRect.size.width/2, _scanRect.origin.y+_scanRect.size.height/2)];
}

- (void)installDeivceCapture : (NSString*)sessionPreset
{
    [self uninstallDeiveCapture];
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    if (!hyc::utils_camera_install_device_capture(_cameraData, sessionPreset, false, captureOutput))
    {
        NSLog(@"install device capture error");
        return;
    }
    
    
    AVCaptureVideoPreviewLayer* layer = utils_camera_install_layer(_cameraData, self.view, self.interfaceOrientation);
    //utils_camera_start(_cameraData);
    //layer.anchorPoint = CGPointMake(0, 0);
    CATransform3D m1 = CATransform3DMakeScale(PHONE_SCALE, PHONE_SCALE, 1);
    //CATransform3D m2 = CATransform3DMakeTranslation(-layer.bounds.size.width/2, -layer.bounds.size.height, 0);
    layer.transform = m1;//CATransform3DConcat(m1, m2);
    
    [self setFocus:CGPointMake(_scanRect.origin.x+_scanRect.size.width/2, _scanRect.origin.y+_scanRect.size.height/2)];
    if (_timerFocus)
        [_timerFocus invalidate];
    _timerFocus = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(onTimerFocus:) userInfo:nil repeats:NO];
    [_timerFocus fire];
    
    // fix ori.
    if (self.interfaceOrientation != UIInterfaceOrientationPortrait) {
        
        if (_cameraOverlayView && [_cameraOverlayView isKindOfClass:[DefaultCameraView class]])
        {
            CGRect rect = _cameraOverlayView.frame;
            rect.size = [UIScreen mainScreen].bounds.size;
            _cameraOverlayView.frame = rect;
            
            float ww;
            if (rect.size.width >= 414)
                ww = 270;
            else
                ww = rect.size.width * 4 / 6;
            
            float w = MIN(ww, MIN(rect.size.width, rect.size.height));
            float t = MIN(100, (rect.size.height-w)/2);
            t = t > 0 ? t : 0;
            _scanRect = CGRectMake((rect.size.width-w)/2, t, w, w);
            ((DefaultCameraView*)_cameraOverlayView).scanRect = _scanRect;
            
            utils_camera_remove_layer_all(_cameraData);
            utils_camera_install_layer(_cameraData, self.view, self.interfaceOrientation);
        }
    }
    
    utils_camera_start(_cameraData);
}

- (void)uninstallDeiveCapture
{
    if (_timerFocus)
        [_timerFocus invalidate];
    
    if (_cameraData.session)
        [_cameraData.session stopRunning];

    utils_camera_remove_layer_all(_cameraData);
    _cameraData = hyc::CameraData();
}

- (void)start
{
    [_process reset];
    _preScan = 0;
    if (_cameraData.session)
        [_cameraData.session startRunning];
    else
    {
        utils_camera_remove_layer_all(_cameraData);
        [self installDeivceCapture:AVCaptureSessionPresetHigh];
    }
}

- (void)stop
{
    [self recoverScreenBright];
    [_process exit];
    if (_cameraData.session)
        [_cameraData.session stopRunning];
}

- (void)cancel
{
    [self recoverScreenBright];
    [_process exit];
    [self uninstallDeiveCapture];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggleCamera
{
    utils_camera_toggle_camera(_cameraData);
}

- (void)startCamera
{
    [_cameraData.session startRunning];
}

- (void)stopCamera
{
    [_cameraData.session stopRunning];
}

- (void)trunOnTorch: (BOOL)on
{
    hyc::utils_camera_trunOnTorch(on);
}

- (void)setScanRect:(CGRect)r
{
    if (!CGRectEqualToRect(_scanRect, r))
    {
        if (_cameraData.videoOutput)
            [((AVCaptureMetadataOutput*)_cameraData.videoOutput) setRectOfInterest:CGRectMake(_scanRect.origin.y/self.view.bounds.size.height, _scanRect.origin.x/self.view.bounds.size.width, _scanRect.size.height/self.view.bounds.size.height, _scanRect.size.width/self.view.bounds.size.width)];
        
        _scanRect = r;
        if (_delegate && [(NSObject*)_delegate respondsToSelector:@selector(onScanRectChange:)])
        {
            [_delegate onScanRectChange:self];
        }
        
        if (_cameraOverlayView && [_cameraOverlayView isKindOfClass:[DefaultCameraView class]])
        {
            ((DefaultCameraView*)_cameraOverlayView).scanRect = r;
        }
    }
}

- (void)setCodeScanType:(CodeScanType)codeScanType
{
    NSArray* arr;
    if (_codeScanType == CodeScanType_All)
    {
        arr = [NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode, nil];
    }
    else if (_codeScanType == CodeScanType_BarCode)
    {
        arr = [NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, nil];
    }
    else
    {
        arr = [NSArray arrayWithObjects:AVMetadataObjectTypeQRCode, nil];
    }
    ((AVCaptureMetadataOutput*)_cameraData.videoOutput).metadataObjectTypes = arr;
}


- (void)setCameraOverlayView: (UIView*) newview
{
    if (nil == newview)
    {
        if (nil == _cameraOverlayView)
        {
            _cameraOverlayView = [[DefaultCameraView alloc] initWithFrame:self.view.bounds];
            ((DefaultCameraView*)_cameraOverlayView).scanRect = _scanRect;
            [self.view addSubview:_cameraOverlayView];
        }
        else if (![_cameraOverlayView isKindOfClass:[DefaultCameraView class]])
        {
            [_cameraOverlayView removeFromSuperview];
            _cameraOverlayView = [[DefaultCameraView alloc] initWithFrame:self.view.bounds];
            ((DefaultCameraView*)_cameraOverlayView).scanRect = _scanRect;
            [self.view addSubview:_cameraOverlayView];
        }
    }
    else
    {
        if (_cameraOverlayView)
            [_cameraOverlayView removeFromSuperview];
        _cameraOverlayView = newview;
        [self.view addSubview:_cameraOverlayView];
    }
}


//- (void) dismissModalViewControllerAnimated: (BOOL) animated
//{
//    if(didHideStatusBar) {
//        [[UIApplication sharedApplication]
//         setStatusBarHidden: NO
//         withAnimation: UIStatusBarAnimationFade];
//        didHideStatusBar = NO;
//    }
//    [super dismissModalViewControllerAnimated: animated];
//}


- (BOOL)shouldAutorotate
{
    return NO;
}

//- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
//                                 duration: (NSTimeInterval) duration
//{
//    NSLog(@"willRotate: orient=%d #%g", (int)orient, duration);
//    rotating = YES;
//    if(readerView)
//        [readerView willRotateToInterfaceOrientation: orient
//                                            duration: duration];
//}
//
//- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) orient
//                                          duration: (NSTimeInterval) duration
//{
//    NSLog(@"willAnimateRotation: orient=%d #%g", (int)orient, duration);
//    if(helpController)
//        [helpController willAnimateRotationToInterfaceOrientation: orient
//                                                         duration: duration];
//    if(readerView)
//        [readerView setNeedsLayout];
//}
//
//- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) orient
//{
//    NSLog(@"didRotate(%d): orient=%d", rotating, (int)orient);
//    if(!rotating && readerView) {
//        // work around UITabBarController bug: willRotate is not called
//        // for non-portrait initial interface orientation
//        [readerView willRotateToInterfaceOrientation: self.interfaceOrientation
//                                            duration: 0];
//        [readerView setNeedsLayout];
//    }
//    rotating = NO;
//}


#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    UInt64 ms = GetMilliseconds();
    if (ms - _preScan > 300)
    {
        CGRect scanRect = _scanRect;
        //        if (!self.navigationController.navigationBarHidden)
        //        {
        //            scanRect.origin.y += self.navigationController.navigationBar.frame.size.height;
        //        }
        
        _preScan = ms;
        @synchronized(self) {
            [_process onCaptureOutput:sampleBuffer scanRect:scanRect viewRect:[UIScreen mainScreen].bounds];//self.view.bounds];
        }
    }
}


#pragma mark Pick from picture.

- (BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL) isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL) doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}

- (BOOL) isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)pickFromPicture :(id)sender
{
    if ([self isPhotoLibraryAvailable]) {
        [self stopCamera];
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        controller.mediaTypes = mediaTypes;
        controller.delegate = self;
        controller.allowsEditing = false;
        [self presentViewController:controller
                           animated:YES
                         completion:^(void){
                             //NSLog(@"Picker View Controller is presented");
                         }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _pickerImage = image;
    [picker dismissViewControllerAnimated:YES completion:^() {
        //UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        
    }];
}

- (void)decodePicker
{
    if (!_pickerImage)
        return;
    
    CodeScanViewController* ss = self;
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    view.layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8].CGColor;
    view.layer.cornerRadius = 5;
    UIActivityIndicatorView* activityIndicatorView = [ [ UIActivityIndicatorView  alloc ]
                                                      initWithFrame:CGRectMake(0,0,30.0,30.0)];
    activityIndicatorView.center = CGPointMake(view.bounds.size.width/2, view.bounds.size.height/2);
    [view addSubview:activityIndicatorView];
    view.center = CGPointMake(ss.cameraOverlayView.bounds.size.width/2, ss.cameraOverlayView.bounds.size.height/2);
    [activityIndicatorView startAnimating];
    [ss.cameraOverlayView addSubview:view];
    
    UIImage* image = _pickerImage;
    _pickerImage = nil;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString* ret = nil;
        
        CodeScanDecoder* decoder = [[CodeScanDecoder alloc] init];
        ret = [decoder decodeImage:image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityIndicatorView stopAnimating];
            [view removeFromSuperview];
            
            //NSLog(@"%@", [result text]);
            if (ret) {
                if(_process.delegate && [(NSObject*)_process.delegate respondsToSelector:@selector(onScanSuccess:code:)])
                {
                    [self stopCamera];
                    [_process.delegate onScanSuccess:ss code:ret];
                    [self startCamera];
                }
            }
            else {
                NSLocale *locale = [NSLocale currentLocale];
                NSString *localName = [locale localeIdentifier];
                NSString *key = @"Can't find barcode!";
                
                if ([localName isEqualToString:@"zh-Hant"])
                {
                    key      = @"找不到二維碼";
                }
                else if ([localName isEqualToString:@"zh-Hans"]
                         || [localName isEqualToString:@"zh_CN"]
                         || [localName rangeOfString:@"zh"].location == 0)
                {
                    key      = @"找不到二维码!";
                }
                
                
                UIAlertView* view = [[UIAlertView alloc] initWithTitle:key message:@"" delegate:ss cancelButtonTitle:@"ok" otherButtonTitles:nil];
                [view show];
            }
        });        
    });
}

@end
