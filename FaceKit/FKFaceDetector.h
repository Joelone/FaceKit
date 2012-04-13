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

struct FKFace
{
    CGPoint leftEye;
    CGPoint rightEye;
    CGPoint mouth;
    CGRect frame;
    CGPoint center;
};
typedef struct FKFace FKFace;

CGRect FKFaceAdjustFrame(CGRect faceFrame, CGRect viewFrame);
CGPoint FKFaceAdjustPoint(CGPoint facePoint, CGRect viewFrame);

typedef void(^FKFaceDetectionHandler)(FKFace face);           // Resolution independent, so values are 0-1.

@interface FKFaceDetector : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) FKFaceDetectionHandler detectionHandler;
@property (nonatomic, strong) CALayer *previewRootLayer;                                                                    // Set to nil for no preview

- (void)beginDetecting;
- (void)endDetecting;

@end
