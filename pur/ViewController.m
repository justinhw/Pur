//
//  ViewController.m
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ViewController.h"
#import "ResultsViewController.h"
#import <UNIRest.h>
#import <CoreImage/CoreImage.h>

@import AssetsLibrary;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *countdown;
@property (nonatomic) UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progress_bar;
@property (weak, nonatomic) IBOutlet UIImageView *suggestion_text;
@property (weak, nonatomic) IBOutlet UILabel *hold_for_text;
@property NSString* token;
@property NSString* objectDescription;
@property (weak, nonatomic) IBOutlet GPUImageView *motion_detection_view;
@end

@interface APPViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation ViewController

AVCaptureSession *session;
AVCaptureStillImageOutput *still_image_output;

NSArray *recycling_terms;
NSArray *compost_terms;
GPUImageFilter *no_filter;

int count = 5;
float timerValue = 0.0;

#pragma mark - View Loading Stuff
- (void)viewDidLoad {
    [super viewDidLoad];
    count = 5;
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // hide progress bar stuff
    _progress_bar.alpha = 0.0;
    _suggestion_text.alpha = 0.0;
    
    no_filter = [[GPUImageFilter alloc] init];
    
    [self setupFilter];
    [self.view setBackgroundColor:[UIColor colorWithRed:0.47 green:0.78 blue:0.60 alpha:1.0]];
    
    [_countdown setFont:[UIFont fontWithName:@"Helvetica" size:215 ]];
    _countdown.textColor = [UIColor whiteColor];
    _countdown.text = @"5";
    
    //timer for numerical countdown
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(triggerCountdownValue:)
                                   userInfo:nil
                                    repeats:YES];
    
    // Initialize arrays
    recycling_terms = [NSArray arrayWithObjects:
                       @"bottle",
                       @"cardboard",
                       @"paper",
                       @"carton",
                       @"box",
                       @"can",
                       @"book",
                       @"metal",
                       @"glass",
                       @"sprite",
                       @"coke",
                       @"nestea",
                       @"fanta",
                       @"aluminum",
                       @"foil",
                       @"jar",
                       @"jug",
                       @"plastic",
                       @"recycle",
                       @"steel",
                       nil];
    compost_terms = [NSArray arrayWithObjects:
                     @"banana",
                     @"apple",
                     @"fruit",
                     @"vegetable",
                     @"bread",
                     @"pepper",
                     @"berry",
                     @"core",
                     @"grape",
                     @"lettuce",
                     @"food",
                     @"peel",
                     @"skin",
                     @"tomatoe",
                     @"onion",
                     @"fries",
                     @"tea bag",
                     @"compost",
                     @"meat",
                     @"burger",
                     @"bun",
                     @"rice",
                     nil];
    
    // KVO
    [self addObserver:self forKeyPath:@"token" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"objectDescription" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void)triggerCountdownValue:(NSTimer *)timer {
    if(![_countdown.text  isEqual: @"1"]){
        _countdown.text = [NSString stringWithFormat:@"%d", count];
        count--;
    }
    else if([_countdown.text  isEqual: @"1"]){
        //take a picture;
        [timer invalidate];
        timer = nil;
        
        [self takePhoto];
    }
}

- (void)setupFilter;
{
    filter = [[GPUImageMotionDetector alloc] init];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    
    videoCamera.outputImageOrientation = [UIApplication sharedApplication].statusBarOrientation;
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    self.title = @"Motion Detector";
    
    [videoCamera addTarget:filter];
    
    videoCamera.runBenchmark = YES;
    GPUImageView *filterView = (GPUImageView *)self.motion_detection_view;
    
    
    faceView = [[UIView alloc] initWithFrame:CGRectMake(200.0, 200.0, 200.0, 200.0)];
    faceView.layer.borderWidth = 3;
    faceView.layer.borderColor = [[UIColor redColor] CGColor];
    [self.motion_detection_view addSubview:faceView];
    faceView.hidden = YES;
    
    __unsafe_unretained ViewController * weakSelf = self;
    
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

- (void)viewWillAppear:(BOOL)animated {
}

#pragma mark - Camera Session
- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        return AVCaptureVideoOrientationLandscapeLeft;
    } else {
        return AVCaptureVideoOrientationLandscapeRight;
    }
}

-(AVCaptureDevice *)frontFacingCameraIfAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

-(void)takePhoto{
    [videoCamera pauseCameraCapture];
    
    // Pause the motion detection filter stuff and setup the ipad camera 
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    AVCaptureDevice *input_device = [self frontFacingCameraIfAvailable];
    NSError *error;
    AVCaptureDeviceInput *device_input = [AVCaptureDeviceInput deviceInputWithDevice:input_device error:&error];
    
    if ([session canAddInput:device_input]) {
        [session addInput:device_input];
    }
    
    still_image_output = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *output_settings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [still_image_output setOutputSettings:output_settings];
    [session addOutput:still_image_output];
    [session startRunning];
    
    [self hideCameraView];
    [self showProgressBar];
    self.progress_bar.progress = 0.0;
    [self performSelectorOnMainThread:@selector(makeMyProgressBarMove) withObject:nil waitUntilDone:NO];
    
    // Need a bit of delay so that everything has time to be setup - horrible hack though
    [self performSelector:@selector(capturePhoto) withObject:nil afterDelay:0.1];
}

- (void)capturePhoto {
    AVCaptureConnection *video_connection = nil;
    
    for (AVCaptureConnection *connection in still_image_output.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                video_connection = connection;
                
                UIDeviceOrientation device_orientation = [[UIDevice currentDevice] orientation];
                AVCaptureVideoOrientation av_capture_orientation;
                
                if ( device_orientation == UIDeviceOrientationLandscapeLeft )
                    av_capture_orientation  = AVCaptureVideoOrientationLandscapeRight;
                
                else if ( device_orientation == UIDeviceOrientationLandscapeRight )
                    av_capture_orientation  = AVCaptureVideoOrientationLandscapeLeft;
                
                [video_connection setVideoOrientation:av_capture_orientation];
                break;
            }
        }
    }
    
    [still_image_output captureStillImageAsynchronouslyFromConnection:video_connection completionHandler:^(CMSampleBufferRef image_data_sample_buffer, NSError *error) {
        if (image_data_sample_buffer != NULL) {
            NSData *image_data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:image_data_sample_buffer];
            UIImage *image = [UIImage imageWithData:image_data];
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            
            // Create path.
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
            
            // Save image.
            [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
            
            NSURL *imageUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
            
            // Save image to camera roll so that we can get a path for the image to send to the API later
            if (image != nil) {
                AudioServicesPlaySystemSound(1108);
                //NSString *imgDataAsString = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];;
                
                // TODO: uncomment this line to enable API searching
                [self getTokenWithImgData:imageUrl];
                //testing function for flow, remove this when above line gets uncommented
                //[self setValue:@"bottle" forKey:@"objectDescription"];
            }
        }
    }];
}

// Helen: this is where we would have to trigger the garbage, recycling or compost flows
- (void)handleImageSearchResultForSearchTerm:(NSString *)search_term {
    if ([self array:compost_terms ContainsStringOrSimilar:search_term]) {
        // proceed with compost flow
        [[NSUserDefaults standardUserDefaults] setObject:@"compost" forKey:@"waste_type"];
    } else if ([self array:recycling_terms ContainsStringOrSimilar:search_term]) {
        // proceed with recycling flow
        [[NSUserDefaults standardUserDefaults] setObject:@"recycle" forKey:@"waste_type"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@"garbage" forKey:@"waste_type"];
    }
    
    [self switchToResultsViewController];
}

- (void) switchToResultsViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ResultsViewController *resultsViewController = (ResultsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ResultsViewController"];
    [self presentViewController:resultsViewController animated:NO completion:nil];
}

- (BOOL)array:(NSArray *)array ContainsStringOrSimilar:(NSString *)string {
    NSArray *array_of_terms = [string componentsSeparatedByString:@" "];
    
    // May want to consider using fuzzy string matching if we have time
    for (int i=0; i<[array_of_terms count]; i++) {
        NSString *current_term = array_of_terms[i];
        
        if ([array containsObject:current_term]) {
            return true;
        }
    }
    
    return false;
}

#pragma mark - Reverse Image Search API

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"token"]) {// calls getDescriptionWithToken whenever the "token" value is updated (i.e. new photo)
        NSLog(@"Token: %@", _token);
        double delayInSeconds = 20.0; // Mashape recommends we wait 8-10 seconds before querying, and if we don't get a return result repeat every 1-2 seconds after. After some rough testing I found 20 seconds to be stable....if we have time and enough query calls after I'll add functionality to do it 8-10 seconds after and repeat every 1-2 seconds until we get a result
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self getDescriptionWithToken];
        });
        
    } else if ([keyPath isEqualToString:@"objectDescription"]) { // call the function to implement once we get a return result here!
        
        NSLog(@"Object description: %@", _objectDescription);
        [self handleImageSearchResultForSearchTerm:_objectDescription];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) hideCameraView {
    self.motion_detection_view.alpha = 0.0;
    self.countdown.alpha = 0.0;
    self.hold_for_text.alpha = 0.0;
}

- (void) showProgressBar {
    self.progress_bar.alpha = 1.0;
    self.suggestion_text.alpha = 1.0;
}

-(void)makeMyProgressBarMove {
    timerValue++;
    NSTimer *timer;
    float actual = [_progress_bar progress];
    if (actual < 1) {
        _progress_bar.progress = actual + ((float)timerValue/(float)20.0);
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(makeMyProgressBarMove) userInfo:nil repeats:NO];
    } else {
        [timer invalidate];
        NSLog(@"progress bar done");
    }
}

- (void)getTokenWithImgData:(NSURL *)imgDataAsString {
    
    NSDictionary *headers = @{@"X-Mashape-Key": @"V9GfedXBsamshd7XrQQz8xMvHvNtp1gHVLyjsnjk54QH3xCxLr"};
    NSDictionary *parameters = @{@"image_request[image]": imgDataAsString, @"image_request[locale]": @"en_US"};
    UNIUrlConnection *asyncConnection = [[UNIRest post:^(UNISimpleRequest *request) {
        [request setUrl:@"https://camfind.p.mashape.com/image_requests"];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJsonAsync:^(UNIHTTPJsonResponse *response, NSError *error) {
        NSInteger code = response.code;
        NSDictionary *responseHeaders = response.headers;
        UNIJsonNode *body = response.body;
        NSData *rawBody = response.rawBody;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:rawBody
                                                             options:kNilOptions
                                                               error:&error];
        NSString *token = [json objectForKey:@"token"];
        [self setValue:token forKey:@"token"];
    }];
}


- (void)getDescriptionWithToken {
    
    NSString *url = @"https://camfind.p.mashape.com/image_responses/";
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", url, _token];
    
    NSDictionary *headers = @{@"X-Mashape-Key": @"V9GfedXBsamshd7XrQQz8xMvHvNtp1gHVLyjsnjk54QH3xCxLr", @"Accept": @"application/json"};
    UNIUrlConnection *asyncConnection = [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:requestUrl];
        [request setHeaders:headers];
    }] asJsonAsync:^(UNIHTTPJsonResponse *response, NSError *error) {
        NSInteger code = response.code;
        NSDictionary *responseHeaders = response.headers;
        UNIJsonNode *body = response.body;
        NSData *rawBody = response.rawBody;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:rawBody
                                                             options:kNilOptions
                                                               error:&error];
        NSString *description = [json objectForKey:@"name"];
        [self setValue:description forKey:@"objectDescription"];
    }];
}

@end