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
@property UIView *faceView;
@end

@implementation DashboardViewController

NSMutableArray *faceView_centres;
NSMutableArray *faceView_area_sizes;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize elements
    faceView_centres = [[NSMutableArray alloc] init];
    faceView_area_sizes = [[NSMutableArray alloc] init];
    
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
    
    //OBSERVERS
    [faceView addObserver:self forKeyPath:@"frame" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"transform" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"position" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"zPosition" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"anchorPoint" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"anchorPointZ" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"frame" options:0 context:NULL];
    [faceView.layer addObserver:self forKeyPath:@"transform" options:0 context:NULL];
}

- (void)setupFilter;
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];

    videoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    self.title = @"Motion Detector";
    
    filter = [[GPUImageMotionDetector alloc] init];
    
    [videoCamera addTarget:filter];
    
    videoCamera.runBenchmark = YES;
    GPUImageView *filterView = (GPUImageView *)self.motion_detection_view;
    
    
    faceView = [[UIView alloc] initWithFrame:CGRectMake(200.0, 200.0, 200.0, 200.0)];
    faceView.layer.borderWidth = 3;
    faceView.layer.borderColor = [[UIColor redColor] CGColor];
    [self.motion_detection_view addSubview:faceView];
    faceView.hidden = YES;
    
    __unsafe_unretained DashboardViewController * weakSelf = self;
    
    [(GPUImageMotionDetector *)filter setLowPassFilterStrength:0.75]; // values range between 0.0 & 1.0
    [(GPUImageMotionDetector *) filter setMotionDetectionBlock:^(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime) {
        if (motionIntensity > 0.01)
        {
            CGFloat viewFrameRatio = weakSelf.motion_detection_view.bounds.size.width / weakSelf.view.bounds.size.width;
            CGFloat motionBoxWidth = viewFrameRatio * 2000.0 * motionIntensity;
            CGSize viewBounds = weakSelf.motion_detection_view.bounds.size;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"View changed its geometry");
    [faceView_centres addObject:[NSValue valueWithCGPoint:CGPointMake(faceView.frame.origin.x, faceView.frame.origin.y)]];
    [faceView_area_sizes addObject:[NSNumber numberWithDouble:[self getAreaForCGRect:faceView.frame]]];
    
    if ([self getAreaForCGRect:faceView.frame] < [faceView_area_sizes[faceView_area_sizes.count-1] doubleValue]) {
        [faceView_area_sizes removeAllObjects];
    }
    
    // Check if a person is trying to scan their item
    if (/*faceView_centres.count > 15 && */faceView_area_sizes.count > 200 && /*[self objectMovedInStraightLine:faceView_centres] && */[self objectGettingCloser:faceView_area_sizes]) {
        NSLog(@"YAS");
        //NSLog(@"%f", [faceView_area_sizes[faceView_area_sizes.count-1] doubleValue]);
        [faceView_area_sizes removeAllObjects];
    }
}

/*- (BOOL)objectMovedInStraightLine:(NSMutableArray *) arr {
    if (arr.count < 15) {
        return false;
    }
    
    for (int i=0; i<arr.count; i++) {
        
    }
    
    return true;
}*/

- (BOOL)objectGettingCloser:(NSMutableArray *) arr {
    if (arr.count < 200) {
        return false;
    }
    
    double close_enough_area = 1000;
    
    double prev_area = [arr[arr.count-1] doubleValue];
    
    for (int i=0; i<200; i++) {
        int curr_index = (int)arr.count - 200;
        
        double curr_area = [arr[curr_index] doubleValue];
        //NSLog(@"%f", curr_area);
        
        // for simplicity, we're going to assume that the user doesn't tease the camera (i.e. moving the object back and forth)
        if (curr_area < prev_area || (i == arr.count-1 && curr_area < close_enough_area)) {
            return false;
        }
        
        curr_index += 3;
    }
    
    double last_area = [arr[arr.count-1] doubleValue];
    
    
    if (last_area >= close_enough_area) {
        NSLog(@"%f", last_area);
        return true;
    }
    
    return false;
}

- (double)getAreaForCGRect:(CGRect)rect {
    return rect.size.height * rect.size.width;
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
