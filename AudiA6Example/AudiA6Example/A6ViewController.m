//
//  A6ViewController.m
//  AudiA6Example
//
//  Created by Andy Roth on 4/13/12.
//  Copyright (c) 2012 AKQA. All rights reserved.
//

#import "A6ViewController.h"

#import "FKFaceDetector.h"

@interface A6ViewController ()
{
@private
    FKFaceDetector *_faceDetector;
    int _currentFrame;
}

@property (nonatomic, strong) IBOutlet UIView *leftEyeView;
@property (nonatomic, strong) IBOutlet UIView *rightEyeView;
@property (nonatomic, strong) IBOutlet UIView *mouthView;
@property (nonatomic, strong) IBOutlet UIView *faceView;

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *previewView;

- (void)redraw;
- (void)updateCurrentFrameBy:(int)amount;

- (IBAction)togglePreview:(UISwitch *)sender;

@end

@implementation A6ViewController

@synthesize leftEyeView = _leftEyeView;
@synthesize rightEyeView = _rightEyeView;
@synthesize mouthView = _mouthView;
@synthesize faceView = _faceView;
@synthesize imageView = _imageView;
@synthesize previewView = _previewView;

- (void)viewDidLoad
{
    _currentFrame = 1;
    [self redraw];
    
    _faceDetector = [[FKFaceDetector alloc] init];
    _faceDetector.previewRootLayer = _previewView.layer;
    
    __block A6ViewController *blockSelf = self;
    
    _faceDetector.detectionHandler = ^(FKFace face)
    {
        // Use a face struct adjusted to account for the size of the view's frame
        FKFace adjustedFace = FKFaceConvertFace(face, self.view.frame.size);
        
        _leftEyeView.center = adjustedFace.leftEye;
        _rightEyeView.center = adjustedFace.rightEye;
        _mouthView.center = adjustedFace.mouth;
        _faceView.frame = adjustedFace.frame;

        CGFloat faceX = face.center.x;
        
        int changeAmount = 0;
        
        if (faceX > 0.7) changeAmount = -2;
        else if (faceX < 0.3) changeAmount = 2;
        else if (faceX > 0.55) changeAmount = -1;
        else if (faceX < 0.45) changeAmount = 1;
        
        [blockSelf updateCurrentFrameBy:changeAmount];
    };
    
    [_faceDetector beginDetecting];
}

- (void)updateCurrentFrameBy:(int)amount
{
    _currentFrame += amount;
    
    if (_currentFrame < 1) _currentFrame += 72;
    else if (_currentFrame > 72) _currentFrame -= 72;
    
    [self redraw];
}

- (void)redraw
{
    _imageView.image = _currentFrame < 10 ? [UIImage imageNamed:[NSString stringWithFormat:@"A6_AB_0000%d.jpg", _currentFrame]] : [UIImage imageNamed:[NSString stringWithFormat:@"A6_AB_000%d.jpg", _currentFrame]];
}

- (IBAction)togglePreview:(UISwitch *)sender
{
    _previewView.hidden = !sender.on;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end
