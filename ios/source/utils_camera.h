//
//  utils_camera.h
//  eleven
//
//  Created by brainpoint on 3/23/15.
//  Copyright (c) 2015 hy. All rights reserved.
//

#ifndef eleven_utils_camera_h
#define eleven_utils_camera_h

#import <AVFoundation/AVFoundation.h>

namespace hyc {
    
    /**
     * 摄像机的信息.
     */
    struct CameraData
    {
        CameraData():session(nil), deviceVideo(nil), deviceVideoInput(nil), deviceAudio(nil), deviceAudioInput(nil), videoOutput(nil)   {
            previewLayers = [NSMutableArray new];
        }
        ~CameraData() {
            for (NSUInteger i = 0; i < previewLayers.count; i++) {
                [((AVCaptureVideoPreviewLayer*)previewLayers[i]) removeFromSuperlayer];
            }
            previewLayers = nil;
            if (session) {
                [session stopRunning];
                if (deviceAudioInput) [session removeInput:deviceAudioInput];
                if (deviceVideoInput) [session removeInput:deviceVideoInput];
                if (videoOutput)      [session removeOutput:videoOutput];
            }
            session = nil;
        }
        
        AVCaptureSession*       session;
        AVCaptureDevice*        deviceVideo;
        AVCaptureDeviceInput*   deviceVideoInput;
        AVCaptureDevice*        deviceAudio;
        AVCaptureDeviceInput*   deviceAudioInput;
        
        AVCaptureOutput*        videoOutput;
        NSMutableArray*         previewLayers;  // AVCaptureVideoPreviewLayer.
    };
    
    /**
     * 初始化摄像头信息.
     * @param sessionPreset 分辨率
     * @param captureAudio  是否采集声音
     * @param output        采集输出的类型.
     */
    bool                        utils_camera_install_device_capture(
                                                                    CameraData&     data,
                                                                    NSString*           sessionPreset = AVCaptureSessionPresetHigh,
                                                                    bool                captureAudio = true,
                                                                    AVCaptureOutput*    output = [[AVCaptureMovieFileOutput alloc] init]
                                                                    );
    
    /**
     * 将摄像头的画面安装至一个layer上.
     * @return 返回layer对象, 使用这个对象来删除.
     */
    AVCaptureVideoPreviewLayer* utils_camera_install_layer( CameraData& data, UIView* view, UIInterfaceOrientation ori = UIInterfaceOrientationPortrait );
    void                        utils_camera_remove_layer( CameraData& data, AVCaptureVideoPreviewLayer* layer );
    void                        utils_camera_remove_layer_at( CameraData& data, int index );
    void                        utils_camera_remove_layer_all( CameraData& data );
    
    /**
     * 启动/停止镜头.
     */
    inline void                        utils_camera_start( CameraData& data )  { if (data.session) [data.session startRunning]; }
    inline void                        utils_camera_stop( CameraData& data )   { if (data.session) [data.session stopRunning]; }
    
    /**
     * 使用位置获取前后摄像头.
     */
    AVCaptureDevice*            utils_camera_with_position(AVCaptureDevicePosition position);
    
    /**
     * 切换摄像头.
     */
    bool                        utils_camera_toggle_camera( CameraData& data );
    
    /**
     * 打开关闭闪光灯.
     */
    void                        utils_camera_trunOnTorch( bool on );
    
    
    
    
    
    
    inline AVCaptureDevice*    utils_camera_with_position(AVCaptureDevicePosition position)
    {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == position) {
                return device;
            }
        }
        return nil;
    }
    
    
    
    inline bool utils_camera_install_device_capture(
                                                    CameraData&     data,
                                                    NSString*           sessionPreset,
                                                    bool                captureAudio,
                                                    AVCaptureOutput*    output)
    {
        //
        // session.
        //
        data.session = [[AVCaptureSession alloc] init];
        data.session.sessionPreset = sessionPreset;
        
        //
        // video / audio input.
        //
        
        data.deviceVideo = utils_camera_with_position(AVCaptureDevicePositionBack);
        if (!data.deviceVideo)
            return false;
        
        data.deviceVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:data.deviceVideo error:nil];
        if ([data.session canAddInput:data.deviceVideoInput]) {
            [data.session addInput:data.deviceVideoInput];
        }
        
        if (captureAudio)
        {
            data.deviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            data.deviceAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:data.deviceAudio error:nil];
            if ([data.session canAddInput:data.deviceAudioInput]) {
                [data.session addInput:data.deviceAudioInput];
            }
        }
        else
        {
            data.deviceAudio = nil;
            data.deviceAudioInput = nil;
        }
        
        //
        // output.
        //
        
        data.videoOutput = output;
        //data.videoOutput.maxRecordedDuration = CMTimeMakeWithSeconds(ELEVEN_MAX_VIEDO_TIME, ELEVEN_VIDEO_FPS);

        
        if ([data.session canAddOutput:data.videoOutput]) {
            [data.session addOutput:data.videoOutput];
        }
        
        //
        // connect.
        //
        if (![data.videoOutput isKindOfClass:[AVCaptureMetadataOutput class]])
        {
            AVCaptureConnection *videoConnection = [data.videoOutput connectionWithMediaType:AVMediaTypeVideo];
            if (!videoConnection) {
                NSLog(@"take video connection failed!");
                return false;
            }
            
            if (![videoConnection isActive]) {
                NSLog(@"record video error");
                return false;
            }
        }
        
        if (captureAudio)
        {
            AVCaptureConnection *audioConnection = [data.videoOutput connectionWithMediaType:AVMediaTypeAudio];
            if (!audioConnection) {
                NSLog(@"take audio connection failed!");
                return false;
            }
            
            if (![audioConnection isActive]) {
                NSLog(@"record audio error");
                return false;
            }
        }
        
        return true;
    }
    
    
    inline AVCaptureVideoPreviewLayer* utils_camera_install_layer( CameraData& data, UIView* view, UIInterfaceOrientation ori )
    {
        if (!data.session)
        {
            NSLog(@"no avsession");
            return nil;
        }

        AVCaptureVideoPreviewLayer* previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:data.session];
        [data.previewLayers addObject:previewLayer];
        
        CALayer* viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        CGRect bounds = [viewLayer bounds];
        
        if (UIInterfaceOrientationPortrait == ori)
        {
            [previewLayer setAffineTransform:CGAffineTransformMakeRotation(0)];
            //bounds = CGRectOffset(bounds, -bounds.origin.x, -bounds.origin.y);
        }
        else if (UIInterfaceOrientationPortraitUpsideDown == ori)
        {
            [previewLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI)];
            //bounds = CGRectOffset(bounds, -bounds.origin.x, bounds.origin.y);
        }
        else if (UIInterfaceOrientationLandscapeRight == ori)
        {
            [previewLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_2)];
            //bounds = CGRectOffset(bounds, -bounds.origin.x, -bounds.origin.y);
        }
        else if (UIInterfaceOrientationLandscapeLeft == ori)
        {
            [previewLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
            //bounds = CGRectOffset(bounds, -bounds.origin.x, -bounds.origin.y);
        }

        [previewLayer setFrame:bounds];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [viewLayer insertSublayer:previewLayer below:[[viewLayer sublayers] objectAtIndex:0]];

        return previewLayer;
    }
    
    inline void utils_camera_remove_layer( CameraData& data, AVCaptureVideoPreviewLayer* layer )
    {
        for (NSUInteger i = 0; i < data.previewLayers.count; i++) {
            if (layer == (AVCaptureVideoPreviewLayer*)data.previewLayers[i])
            {
                [layer removeFromSuperlayer];
                [data.previewLayers removeObjectAtIndex:i];
                break;
            }
        }
    }
    
    inline void utils_camera_remove_layer_at( CameraData& data, int index )
    {
        if (index >= 0 && index < data.previewLayers.count)
        {
            [((AVCaptureVideoPreviewLayer*)data.previewLayers[index]) removeFromSuperlayer];
            [data.previewLayers removeObjectAtIndex:index];
        }
    }
    
    inline void utils_camera_remove_layer_all( CameraData& data )
    {
        for (NSUInteger i = 0; i < data.previewLayers.count; i++) {
            [(AVCaptureVideoPreviewLayer*)data.previewLayers[i] removeFromSuperlayer];
        }
        [data.previewLayers removeAllObjects];
    }
    
    inline bool utils_camera_toggle_camera( CameraData& _cameraData )
    {
        NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
        if (cameraCount > 1) {
            NSError *error;
            AVCaptureDeviceInput *newVideoInput;
            AVCaptureDevicePosition position = [[_cameraData.deviceVideoInput device] position];
            
            if (position == AVCaptureDevicePositionBack)
                newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:utils_camera_with_position(AVCaptureDevicePositionFront) error:&error];
            else if (position == AVCaptureDevicePositionFront)
                newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:utils_camera_with_position(AVCaptureDevicePositionBack) error:&error];
            else
                return false;
            
            if (newVideoInput != nil) {
                [_cameraData.session beginConfiguration];
                [_cameraData.session removeInput:_cameraData.deviceVideoInput];
                if ([_cameraData.session canAddInput:newVideoInput])
                {
                    [_cameraData.session addInput:newVideoInput];
                    _cameraData.deviceVideoInput = newVideoInput;
                } else {
                    [_cameraData.session addInput:_cameraData.deviceVideoInput];
                }
                [_cameraData.session commitConfiguration];
            } else if (error) {
                NSLog(@"toggle carema failed, error = %@", error);
            }
            
            return true;
        }
        
        return false;
    }
    
    inline void utils_camera_trunOnTorch( bool on )
    {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if ([device hasTorch] && [device hasFlash]){
                [device lockForConfiguration:nil];
                if (on) {
                    [device setTorchMode:AVCaptureTorchModeOn];
                    [device setFlashMode:AVCaptureFlashModeOn];
                } else {
                    [device setTorchMode:AVCaptureTorchModeOff];
                    [device setFlashMode:AVCaptureFlashModeOff];
                }
                [device unlockForConfiguration];
            }
        }
    }
    
    
}

#endif
