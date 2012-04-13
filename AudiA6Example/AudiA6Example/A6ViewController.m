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
@synthesize imageView = _imageView;
@synthesize previewView = _previewView;

- (void)viewDidLoad
{
    _currentFrame = 1;
    [self redraw];
    
    _faceDetector = [[FKFaceDetector alloc] init];
    
    // Uncomment to add a preview layer
    _faceDetector.previewRootLayer = _previewView.layer;
    
    __block A6ViewController *blockSelf = self;
    
    _faceDetector.detectionHandler = ^(CGPoint leftEyePosition, CGPoint rightEyePosition, CGPoint mouthPosition)
    {
        if (!CGPointEqualToPoint(leftEyePosition, CGPointZero))
        {
            _leftEyeView.hidden = NO;
            _leftEyeView.center = CGPointMake(leftEyePosition.x * self.view.frame.size.width, leftEyePosition.y * self.view.frame.size.height);
        }
        else
        {
            _leftEyeView.hidden = YES;
        }
        
        if (!CGPointEqualToPoint(rightEyePosition, CGPointZero))
        {
            _rightEyeView.hidden = NO;
            _rightEyeView.center = CGPointMake(rightEyePosition.x * self.view.frame.size.width, rightEyePosition.y * self.view.frame.size.height);
        }
        else
        {
            _rightEyeView.hidden = YES;
        }
        
        if (!CGPointEqualToPoint(mouthPosition, CGPointZero))
        {
            _mouthView.hidden = NO;
            _mouthView.center = CGPointMake(mouthPosition.x * self.view.frame.size.width, mouthPosition.y * self.view.frame.size.height);
        }
        else
        {
            _mouthView.hidden = YES;
        }
        
        CGFloat averageX = (leftEyePosition.x + rightEyePosition.x) / 2.0;
        
        int changeAmount = 0;
        
        if (averageX > 0.7) changeAmount = -2;
        else if (averageX < 0.3) changeAmount = 2;
        else if (averageX > 0.55) changeAmount = -1;
        else if (averageX < 0.45) changeAmount = 1;
        
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
