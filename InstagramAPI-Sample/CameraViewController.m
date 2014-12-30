//
//  CameraViewController.m
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/30.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <AudioToolbox/AudioServices.h>

@interface CameraViewController ()
{
    // camera variables
    BOOL isRequireTakePhoto;
    BOOL isProcessing;
    BOOL isFrontMode;
    BOOL isFlashMode;
    void *bitmap;
    AVCaptureVideoDataOutput *videoOutput;
    AVCaptureInput *captureInput ;
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    UIImage *imageBuffer;
    UIView *preView;
    float zoom;
    dispatch_queue_t queue;
    
    // buttons
    UIButton *shutterButton;
    UIButton *frontButton;
    UIButton *flashButton;
    UIButton *dismissButton;
    
    // label
    UILabel *flashLabel;
    
    // container
    UIView *buttonContainer;
}

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tabBarController.tabBar.hidden = YES;
    
    // camera
    zoom = 1.0f;
    isFlashMode=NO;
    isFrontMode=NO;
    isProcessing=NO;
    isRequireTakePhoto=NO;
    
    // imageBuffer
    size_t width = 640;//self.view.frame.size.width;
    size_t height = 480;//self.view.frame.size.height;
    size_t captureSize = width * height * 4;
    bitmap = malloc(captureSize);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef dataProviderRef = CGDataProviderCreateWithData(NULL,
                                                                     bitmap,
                                                                     captureSize,
                                                                     NULL);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       32,
                                       width * 4,
                                       colorSpace,
                                       bitmapInfo,
                                       dataProviderRef,
                                       NULL,
                                       0,
                                       kCGRenderingIntentDefault);
    imageBuffer = [UIImage imageWithCGImage:cgImage];
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(dataProviderRef);
    // AVCaptureSession
    captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *captureDevice;
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    [captureSession addInput:captureInput];
    [captureSession beginConfiguration];
    captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    [captureSession commitConfiguration];
    // output
    videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [captureSession addOutput:videoOutput];
    dispatch_queue_t videoQueue = dispatch_queue_create("myQueue", NULL);
    [videoOutput setSampleBufferDelegate:(id)self queue:videoQueue];
    // queue
    queue = dispatch_queue_create("takingPhotoQueue", DISPATCH_QUEUE_SERIAL);
    // start camera!
    [captureSession startRunning];
    
    // preview
    preView = [[UIView alloc]initWithFrame:self.view.frame];
    [preView setBackgroundColor:[UIColor cyanColor]];
    [preView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:preView];
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    [previewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
    [previewLayer setFrame: preView.frame];
    [preView.layer insertSublayer:previewLayer atIndex:0];
    
    // rotation
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    
    // container
    buttonContainer = [[UIView alloc]initWithFrame:CGRectMake(0,self.view.frame.size.height*0.82,
                                                              self.view.frame.size.width,self.view.frame.size.height*0.18)];
    [buttonContainer setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [self.view addSubview:buttonContainer];
    
    // buttons
    shutterButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [shutterButton setFrame:CGRectMake(0,0,64,64)];
    [shutterButton setCenter:CGPointMake(buttonContainer.frame.size.width*0.5,buttonContainer.frame.size.height*0.55)];
    [shutterButton setImage:[UIImage imageNamed:@"shutter.png"] forState:UIControlStateNormal];
    [shutterButton addTarget:self action:@selector(shutterButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:shutterButton];
    
    flashButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [flashButton setFrame:CGRectMake(0,0,26,26)];
    [flashButton setCenter:CGPointMake(buttonContainer.frame.size.width*0.9,buttonContainer.frame.size.height*0.74)];
    [flashButton setImage:[UIImage imageNamed:@"flash.png"] forState:UIControlStateNormal];
    [flashButton addTarget:self action:@selector(flashButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:flashButton];
    
    frontButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [frontButton setFrame:CGRectMake(0,0,45,26)];
    [frontButton setCenter:CGPointMake(buttonContainer.frame.size.width*0.9,buttonContainer.frame.size.height*0.40)];
    [frontButton setImage:[UIImage imageNamed:@"front.png"] forState:UIControlStateNormal];
    [frontButton addTarget:self action:@selector(frontButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:frontButton];
    
    dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissButton setFrame:CGRectMake(0, 0, 20, 20)];
    [dismissButton setCenter:CGPointMake(self.view.frame.origin.x + 30, self.view.frame.origin.y + 40)];
    [dismissButton setImage:[UIImage imageNamed:@"dismissButton.png"] forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismissCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissButton];
    
    
    //label
    flashLabel=[[UILabel alloc]initWithFrame:CGRectMake(0,0,30,20)];
    [flashLabel setText:NSLocalizedString(@"OFF",nil)];
    [flashLabel setCenter:CGPointMake(flashButton.center.x-30, flashButton.center.y)];
    [flashLabel setFont:[UIFont boldSystemFontOfSize:12]];
    [flashLabel setTextAlignment:NSTextAlignmentRight];
    [flashLabel setTextColor:[UIColor whiteColor]];
    [buttonContainer addSubview:flashLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.tabBarController.tabBar.hidden == NO) {
        self.tabBarController.tabBar.hidden = YES;
    }
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -Buttons
- (void)shutterButtonTouchUpInside:(UIButton *)button {
    if (!isProcessing) {
        isRequireTakePhoto = YES;
        if(isFlashMode){
            dispatch_sync(queue, ^{
                Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
                if (captureDeviceClass != nil) {
                    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
                    if ([device hasTorch] && [device hasFlash]){
                        [device lockForConfiguration:nil];
                        if (isFlashMode) {
                            [device setTorchMode:AVCaptureTorchModeOn];
                            [device setFlashMode:AVCaptureFlashModeOn];
                        } else {
                            [device setTorchMode:AVCaptureTorchModeOff];
                            [device setFlashMode:AVCaptureFlashModeOff];
                        }
                        [device unlockForConfiguration];
                    }
                }
                sleep(1);
            });
        }
    }
}

- (void)flashButtonTouchUpInside:(UIButton *)button {
    if (isFlashMode || isFrontMode) {
        isFlashMode = NO;
        [flashLabel setText:NSLocalizedString(@"OFF",nil)];
    }
    else{
        isFlashMode = YES;
        [flashLabel setText:NSLocalizedString(@"ON",nil)];
    }
}

- (void)frontButtonTouchUpInside:(UIButton *)button {
    AVCaptureDevice *captureDevice;
    if(!isFrontMode){
        captureDevice = [self frontFacingCameraIfAvailable];
        isFrontMode = YES;
    } else {
        captureDevice = [self backCamera];
        isFrontMode = NO;
    }
    [captureSession removeInput:captureInput];
    captureInput = [AVCaptureDeviceInput
                    deviceInputWithDevice:captureDevice
                    error:nil];
    [captureSession addInput:captureInput];
}


#pragma mark - change to front mode
- (void)forceToSwitchFlashOff
{
    if(isFlashMode){
        isFlashMode = NO;
        [flashLabel setText:NSLocalizedString(@"OFF",nil)];
    }
}

- (AVCaptureDevice *)frontFacingCameraIfAvailable
{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            [self forceToSwitchFlashOff];
            break;
        }
    }
    
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

- (AVCaptureDevice *)backCamera
{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionBack)
        {
            captureDevice = device;
            break;
        }
    }
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return captureDevice;
}

- (void)didRotate:(id)sender {
    //NSLog(@"changed");
}

#pragma mark - Camera

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if (isRequireTakePhoto) {
        AudioServicesPlaySystemSound(1108);
        isRequireTakePhoto = NO;
        isProcessing = YES;
        dispatch_sync(queue, ^{
            CVPixelBufferRef pixbuff = CMSampleBufferGetImageBuffer(sampleBuffer);
            if(CVPixelBufferLockBaseAddress(pixbuff, 0) == kCVReturnSuccess){
                memcpy(bitmap, CVPixelBufferGetBaseAddress(pixbuff),640 * 480 *4);
                CMAttachmentMode attachmentMode;
                CFDictionaryRef metadataRef = CMGetAttachment(sampleBuffer, CFSTR("MetadataDictionary"), &attachmentMode);
                NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)CFBridgingRelease(metadataRef)];
                [metadata setObject:[NSNumber numberWithInt:6]
                             forKey:(NSString *)kCGImagePropertyOrientation];
                
                ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
                //切り取る範囲
                CGRect rect = CGRectMake(imageBuffer.size.width*0.5 - imageBuffer.size.width*(1.0/zoom)*0.5,
                                         imageBuffer.size.height*0.5  - imageBuffer.size.height*(1.0/zoom)*0.5,
                                         imageBuffer.size.width*(1.0/zoom),
                                         imageBuffer.size.height*(1.0/zoom));
                
                CGImageRef resizedCGImage = CGImageCreateWithImageInRect(imageBuffer.CGImage, rect);
                UIImage *resizedUIImage = [UIImage imageWithCGImage:resizedCGImage];
                
                CGSize newSize = CGSizeMake(imageBuffer.size.width, imageBuffer.size.height);
                UIGraphicsBeginImageContext(newSize);
                [resizedUIImage drawInRect:CGRectMake(0, 0, imageBuffer.size.width, imageBuffer.size.height)];
                UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                [library writeImageToSavedPhotosAlbum:newImage.CGImage
                                             metadata:metadata
                                      completionBlock:^(NSURL *assetURL, NSError *error) {
                                          NSLog(@"URL:%@", assetURL);
                                          if (error) {
                                              NSLog(@"error:%@", error);
                                          }
                                          isProcessing = NO;
                                      }];
                CVPixelBufferUnlockBaseAddress(pixbuff, 0);
            }
        });
        
        if(isFlashMode){
            dispatch_sync(queue, ^{
                Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
                if (captureDeviceClass != nil) {
                    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
                    if ([device hasTorch] && [device hasFlash]){
                        [device lockForConfiguration:nil];
                        [device setTorchMode:AVCaptureTorchModeOff];
                        [device setFlashMode:AVCaptureFlashModeOff];
                        [device unlockForConfiguration];
                    }
                }
            });
        }
    }
}



#pragma mark - Dismiss

- (void)dismissCamera
{
    self.tabBarController.selectedIndex = 0;
}


@end
