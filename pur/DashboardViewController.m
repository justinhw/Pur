//
//  DashboardViewController.m
//  pur
//
//  Created by Varnit Grewal on 2016-07-11.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "DashboardViewController.h"
//#import "ShowcaseFilterViewController.h"
#import <CoreImage/CoreImage.h>
@interface DashboardViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *baby_plant2;
@property (weak, nonatomic) IBOutlet UIImageView *baby_plant1;
@property (weak, nonatomic) IBOutlet UIImageView *dead_tree1;

@property (weak, nonatomic) IBOutlet UILabel *compost_kg;
@property (weak, nonatomic) IBOutlet UILabel *recycling_kg;
@property (weak, nonatomic) IBOutlet UILabel *garbage_kg;
@property (weak, nonatomic) IBOutlet UIImageView *hold_item;
@property (weak, nonatomic) IBOutlet GPUImageView *motion_detection_view;

@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupFilter];
    
    //map elements populated - initially transparent
    _baby_plant1.alpha = 0.0;
    _baby_plant2.alpha = 0.0;
    _dead_tree1.alpha = 1.0;

    UIColor *ourGrey = [UIColor colorWithRed:90.0f/255.0f green:87.0f/255.0f blue:87.0f/255.0f alpha:1.0];
    
    [_garbage_kg setFont:[UIFont fontWithName:@"Arial" size:54 ]];
    _garbage_kg.textColor = ourGrey;
    _garbage_kg.text = @"200 kg";
    
    [_recycling_kg setFont:[UIFont fontWithName:@"Arial" size:54 ]];
    _recycling_kg.textColor = ourGrey;
    _recycling_kg.text = @"150 kg";
    
    [_compost_kg setFont:[UIFont fontWithName:@"Arial" size:54 ]];
    _compost_kg.textColor = ourGrey;
    _compost_kg.text = @"50 kg";
}

- (void)setupFilter;
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    
    videoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    self.title = @"Motion Detector";
    
    filter = [[GPUImageMotionDetector alloc] init];
    
    [videoCamera addTarget:filter];
    
    videoCamera.runBenchmark = YES;
    GPUImageView *filterView = (GPUImageView *)self.motion_detection_view;
    
    
    faceView = [[UIView alloc] initWithFrame:CGRectMake(200.0, 200.0, 200.0, 200.0)];
    faceView.layer.borderWidth = 3;
    faceView.layer.borderColor = [[UIColor redColor] CGColor];
    [self.view addSubview:faceView];
    faceView.hidden = YES;
    
    __unsafe_unretained DashboardViewController * weakSelf = self;
    
    [(GPUImageMotionDetector *)filter setLowPassFilterStrength:0.75]; // values range between 0.0 & 1.0
    [(GPUImageMotionDetector *) filter setMotionDetectionBlock:^(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime) {
        if (motionIntensity > 0.01)
        {
            CGFloat motionBoxWidth = 2000.0 * motionIntensity;
            CGSize viewBounds = weakSelf.view.bounds.size;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf->faceView.frame = CGRectMake(round(viewBounds.width * motionCentroid.x - motionBoxWidth / 2.0), round(viewBounds.height * motionCentroid.y - motionBoxWidth / 2.0), motionBoxWidth, motionBoxWidth);
                weakSelf->faceView.hidden = NO;
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf->faceView.hidden = YES;
            });
        }
        
    }];
    
    [videoCamera addTarget:filterView];
    
    [videoCamera startCameraCapture];
}

- (void) viewDidAppear:(BOOL)animated  {
    [super viewDidAppear:animated];
    //hold item here - flashing
    [UIView animateWithDuration: 1.75f
                          delay:0.5f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                         _hold_item.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                     }
     ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
