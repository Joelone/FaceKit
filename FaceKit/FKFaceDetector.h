//
//  FTFaceDetector.h
//  FaceTest
//
//  Created by Andy Roth on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

typedef void(^FKFaceDetectionHandler)(CGPoint leftEyePosition, CGPoint rightEyePosition, CGPoint mouthPosition);           // Resolution independent, so values are 0-1.

@interface FKFaceDetector : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) FKFaceDetectionHandler detectionHandler;
@property (nonatomic, strong) CALayer *previewRootLayer;                                                                    // Set to nil for no preview

- (void)beginDetecting;
- (void)endDetecting;

@end
