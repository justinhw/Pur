#import "ShowcaseFilterViewController.h"
#import <CoreImage/CoreImage.h>

@implementation ShowcaseFilterViewController

#pragma mark -
#pragma mark Initialization and teardown

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc;
{
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupFilter];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Note: I needed to stop camera capture before the view went off the screen in order to prevent a crash from the camera still sending frames
    [videoCamera stopCameraCapture];
    
	[super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Note: I needed to start camera capture after the view went on the screen, when a partially transition of navigation view controller stopped capturing via viewWilDisappear.
    [videoCamera startCameraCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (void)setupFilter;
{

    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    
    videoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    self.title = @"Motion Detector";

    filter = [[GPUImageMotionDetector alloc] init];

    [videoCamera addTarget:filter];
    
    videoCamera.runBenchmark = YES;
    GPUImageView *filterView = (GPUImageView *)self.view;


    faceView = [[UIView alloc] initWithFrame:CGRectMake(200.0, 200.0, 200.0, 200.0)];
    faceView.layer.borderWidth = 3;
    faceView.layer.borderColor = [[UIColor redColor] CGColor];
    [self.view addSubview:faceView];
    faceView.hidden = YES;
    
    __unsafe_unretained ShowcaseFilterViewController * weakSelf = self;
    
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


@end
