//
//  DashboardViewController.m
//  pur
//
//  Created by Varnit Grewal on 2016-07-11.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "DashboardViewController.h"
#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import "LinearRegression.h"

@interface DashboardViewController ()
- (IBAction)fakeRestartApp:(id)sender;
- (IBAction)clearMapAssets:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *baby_plant1;
@property (weak, nonatomic) IBOutlet UIImageView *baby_plant2;
@property (weak, nonatomic) IBOutlet UIImageView *dead_tree1;
@property (weak, nonatomic) IBOutlet UIImageView *full_tree;
@property (weak, nonatomic) IBOutlet UIImageView *dead_tree2;

@property (weak, nonatomic) IBOutlet UILabel *compost;
@property (weak, nonatomic) IBOutlet UILabel *recycling;
@property (weak, nonatomic) IBOutlet UILabel *garbage;
@property (weak, nonatomic) IBOutlet UIImageView *hold_item;
@property (weak, nonatomic) IBOutlet UIImageView *arrow;
@property (weak, nonatomic) IBOutlet GPUImageView *motion_detection_view;
@property LinearRegression *sharedInstance;
@property UIView *faceView;
@end

@implementation DashboardViewController

int garbage_count;
int compost_count;
int recycling_count;

NSMutableArray *faceView_centres;
NSMutableArray *faceView_area_sizes;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Initialize elements
    faceView_centres = [[NSMutableArray alloc] init];
    faceView_area_sizes = [[NSMutableArray alloc] init];
    
    self.sharedInstance = [LinearRegression sharedInstance];
    [self setupFilter];

    UIColor *ourGrey = [UIColor colorWithRed:90.0f/255.0f green:87.0f/255.0f blue:87.0f/255.0f alpha:1.0];
    
    [_garbage setFont:[UIFont fontWithName:@"Arial" size:54 ]];
    _garbage.textColor = ourGrey;
    [_recycling setFont:[UIFont fontWithName:@"Arial" size:54 ]];
    _recycling.textColor = ourGrey;
    [_compost setFont:[UIFont fontWithName:@"Arial" size:54 ]];
    _compost.textColor = ourGrey;
    
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
    
    _baby_plant1.alpha = 0.0;
    _baby_plant2.alpha = 0.0;
    _dead_tree1.alpha = 0.0;
    _dead_tree2.alpha = 0.0;
    _full_tree.alpha = 0.0;
    
    NSString *hasBeenLoaded = [[NSUserDefaults standardUserDefaults] stringForKey:@"hasBeenLoaded"];
    if([hasBeenLoaded isEqual: @"false"] || !(hasBeenLoaded)){  //false or doesnt exist
        
        garbage_count = 0;
        compost_count = 0;
        recycling_count = 0;
        
        _compost.text = [NSString stringWithFormat:@"%d", compost_count];
        _garbage.text = [NSString stringWithFormat:@"%d", garbage_count];
        _recycling.text = [NSString stringWithFormat:@"%d", recycling_count];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"true" forKey:@"hasBeenLoaded"];
        
    }else if([hasBeenLoaded isEqual: @"true"]){
        [self updateDashboardAssets];
    }
    
}

- (void) viewDidAppear:(BOOL)animated  {
    [super viewDidAppear:animated];
    
    //hold item here - flashing
    [UIView animateWithDuration: 1.75f
                          delay:0.5f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                         _hold_item.alpha = 0.25;
                         _arrow.alpha = 0.25;
                     }
                     completion:^(BOOL finished){
                     }
     ];
}

-(void)updateDashboardAssets{
    //values and map
    NSString *garbage_type = [[NSUserDefaults standardUserDefaults] stringForKey:@"waste_type"];
    
    if ([garbage_type  isEqual: @"recycle"]) {
        recycling_count++;
        _recycling.text = [NSString stringWithFormat:@"%d", recycling_count];
        if(recycling_count == 1){
            _baby_plant1.alpha = 1.0;
        }else if(recycling_count >= 2){
            _baby_plant1.alpha = 1.0;
            _full_tree.alpha = 1.0;
        }
        
    } else if ([garbage_type  isEqual: @"compost"]) {
        compost_count++;
        _compost.text = [NSString stringWithFormat:@"%d", compost_count];
        _baby_plant2.alpha = 1.0;
        
    } else {
        garbage_count++;
        _garbage.text = [NSString stringWithFormat:@"%d", garbage_count];
        if(garbage_count == 1){
            _dead_tree1.alpha = 1.0;
        }else if(garbage_count >= 2){
            _dead_tree1.alpha = 1.0;
            _dead_tree2.alpha = 1.0;
        };
        
    }
    
    garbage_type = nil;
}

- (IBAction)fakeRestartApp:(id)sender {
    //sets value back to false as if to pretend app has never been loaded
    [[NSUserDefaults standardUserDefaults] setObject:@"false" forKey:@"hasBeenLoaded"];
}

- (IBAction)clearMapAssets:(id)sender{
    _baby_plant1.alpha = 0.0;
    _baby_plant2.alpha = 0.0;
    _dead_tree1.alpha = 0.0;
    _dead_tree2.alpha = 0.0;
    _full_tree.alpha = 0.0;
    
    garbage_count = 0;
    compost_count = 0;
    recycling_count = 0;
    
    _compost.text = [NSString stringWithFormat:@"%d", compost_count];
    _garbage.text = [NSString stringWithFormat:@"%d", garbage_count];
    _recycling.text = [NSString stringWithFormat:@"%d", recycling_count];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"View changed its geometry");
    [faceView_centres addObject:[NSValue valueWithCGPoint:CGPointMake(faceView.frame.origin.x, faceView.frame.origin.y)]];
    [faceView_area_sizes addObject:[NSNumber numberWithDouble:[self getAreaForCGRect:faceView.frame]]];
    
    // Check if a person is trying to scan their item
    if (faceView_area_sizes.count > 100 && [self objectGettingCloser:faceView_area_sizes]) {
        [faceView_area_sizes removeAllObjects];
        NSLog(@"Person approaching & resetting data from point a");
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ViewController *viewController = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        [self presentViewController:viewController animated:YES completion:nil];
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
    if (arr.count < 100) {
        return false;
    }
    
    int curr_index = (int)arr.count-100;
    
    // Fill the working array
    for (int i=0; i<100; i++) {
        double curr_area = [arr[curr_index] doubleValue];
        
        DataItem *point = [DataItem new];
        point.xValue = (double)i;
        point.yValue = curr_area;
        [self.sharedInstance addDataObject:point];
        curr_index++;
    }
    
    RegressionResult *regressionResult = [self.sharedInstance calculate];
    //NSLog(@"Slope %f", regressionResult.slope);
    
    if (regressionResult.slope > 400) {
        return true;
    }
    
    [self.sharedInstance clear];

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
