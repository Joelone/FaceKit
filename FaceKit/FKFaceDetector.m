//
//  FTFaceDetector.m
//  FaceTest
//
//  Created by Andy Roth on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FKFaceDetector.h"

CGRect FKFaceAdjustFrame(CGRect faceFrame, CGRect viewFrame)
{
    CGRect rect = CGRectMake(faceFrame.origin.x * viewFrame.size.width, faceFrame.origin.y * viewFrame.size.height, faceFrame.size.width * viewFrame.size.width, faceFrame.size.height * viewFrame.size.height);
    
    return rect;
}

CGPoint FKFaceAdjustPoint(CGPoint facePoint, CGRect viewFrame)
{
    CGPoint point = CGPointMake(facePoint.x * viewFrame.size.width, facePoint.y * viewFrame.size.height);
    
    return point;
}

@interface FKFaceDetector ()
{
@private
    AVCaptureVideoDataOutput *_videoDataOutput;
    dispatch_queue_t _videoDataOutputQueue;
    BOOL _isUsingFrontFacingCamera;
    CIDetector *_faceDetector;
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
}

- (void)processFeatures:(NSArray *)features inFrame:(CGRect)frame atOrientation:(UIDeviceOrientation)orientation;
- (void)throwErrorMessage:(NSString *)message;

@end

@implementation FKFaceDetector

@synthesize previewRootLayer = _rootLayer;
@synthesize detectionHandler = _detectionHandler;

#pragma mark - Initialization

- (void)beginDetecting
{
    if (!_session)
    {
        NSError *error = nil;
        
        // Create the Core Image face detector with low accuracy, much higher performance
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
        
        // Create the capture session
        _session = [[AVCaptureSession alloc] init];
        
        // Set the input to the device's front-facing camera
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
        {
            if (device.position == AVCaptureDevicePositionFront)
            {
                AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                _isUsingFrontFacingCamera = YES;
                
                if (error)
                {
                    [self throwErrorMessage:error.localizedDescription];
                    return;
                }
                
                if ([_session canAddInput:deviceInput])
                {
                    [_session addInput:deviceInput];
                }
                else
                {
                    [self throwErrorMessage:@"Could not add device input"];
                    return;
                }
            }
        }
        
        // Add the video data output
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        // Set the video output properties and queue to process each frame
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [_videoDataOutput setVideoSettings:rgbOutputSettings];
        [_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        _videoDataOutputQueue = dispatch_queue_create("net.roozy.facedetectorqueue", DISPATCH_QUEUE_SERIAL);
        [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
        
        if ([_session canAddOutput:_videoDataOutput])
        {
            [_session addOutput:_videoDataOutput];
        }
        else
        {
            [self throwErrorMessage:@"Could not add video data output"];
        }
        
        [[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        // Add a preview layer if necessary
        if (_rootLayer)
        {
            _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
            [_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
            [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
            [_rootLayer setMasksToBounds:YES];
            [_previewLayer setFrame:[_rootLayer bounds]];
            [_rootLayer addSublayer:_previewLayer];
        }
        
        // Start the session
        [_session startRunning];
    }
}

- (void)endDetecting
{
    [_session stopRunning];
    [_previewLayer removeFromSuperlayer];
    dispatch_release(_videoDataOutputQueue);
    
    _videoDataOutput = nil;
    _faceDetector = nil;
    _session = nil;
    _previewLayer = nil;
    _videoDataOutputQueue = nil;
}

- (void)throwErrorMessage:(NSString *)message
{
    [self endDetecting];
    
    NSError *error = [[NSError alloc] initWithDomain:@"net.roozy.FaceKit" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil]];
    @throw error;
}

#pragma mark - Video Data Output Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{	
	// Create a Core Video pixel buffer from the sample buffer, the create the Core Image from that buffer
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge_transfer NSDictionary *)attachments];

    // Convert the device's orientation to a photo's exif orientation used by Core Image
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.  
	};
	
	switch (curDeviceOrientation)
    {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (_isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (_isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    
    // Get the array of features from the current buffer's image
	NSArray *features = [_faceDetector featuresInImage:ciImage options:imageOptions];
	
    // Get the portion of the buffer that we've used
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft*/);
	
    // Process the features on the main thread
	dispatch_async(dispatch_get_main_queue(), ^(void)
    {
		[self processFeatures:features inFrame:clap atOrientation:curDeviceOrientation];
	});
}

#pragma mark - Feature Processing

- (void)processFeatures:(NSArray *)features inFrame:(CGRect)frame atOrientation:(UIDeviceOrientation)orientation
{
    for (CIFeature *feature in features)
    {
        // Look for a facial feature
        if ([feature isKindOfClass:[CIFaceFeature class]])
        {
            FKFace face;
            
            // Convert the positions of each feature to be relative, resolution independent
            CIFaceFeature *faceFeature = (CIFaceFeature *)feature;
            face.leftEye = CGPointZero;
            face.rightEye = CGPointZero;
            face.mouth = CGPointZero;
            
            // The front camera acts as a mirror, so the left and right eyes are switched
            if (faceFeature.hasLeftEyePosition)
            {
                CGFloat adjustedX = (1 - (faceFeature.leftEyePosition.y / frame.size.height));
                CGFloat adjustedY = (faceFeature.leftEyePosition.x / frame.size.width);
                face.rightEye = CGPointMake(adjustedX, adjustedY);
            }
            
            if (faceFeature.hasRightEyePosition)
            {
                CGFloat adjustedX = (1 - (faceFeature.rightEyePosition.y / frame.size.height));
                CGFloat adjustedY = (faceFeature.rightEyePosition.x / frame.size.width);
                face.leftEye = CGPointMake(adjustedX, adjustedY);
            }
            
            if (faceFeature.hasMouthPosition)
            {
                CGFloat adjustedX = (1 - (faceFeature.mouthPosition.y / frame.size.height));
                CGFloat adjustedY = (faceFeature.mouthPosition.x / frame.size.width);
                face.mouth = CGPointMake(adjustedX, adjustedY);
            }
            
            CGRect faceFrame;
            faceFrame.origin.x = MIN(MIN(face.leftEye.x, face.rightEye.x), face.mouth.x);
            faceFrame.origin.y = MIN(MIN(face.leftEye.y, face.rightEye.y), face.mouth.y);
            CGFloat maxX = MAX(MAX(face.leftEye.x, face.rightEye.x), face.mouth.x);
            CGFloat maxY = MAX(MAX(face.leftEye.y, face.rightEye.y), face.mouth.y);
            faceFrame.size.width = maxX - faceFrame.origin.x;
            faceFrame.size.height = maxY - faceFrame.origin.y;
            
            face.frame = faceFrame;
            face.center = CGPointMake(faceFrame.origin.x + (faceFrame.size.width / 2), faceFrame.origin.y + (faceFrame.size.height / 2));

            // Call the handler block
            _detectionHandler(face);
        }
    }
}

@end
