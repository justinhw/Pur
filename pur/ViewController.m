//
//  ViewController.m
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ViewController.h"
#import <UNIRest.h>
#import <GPUImage.h>

@import AssetsLibrary;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *countdown;
@property (nonatomic) UIButton *takePhotoBtn;

@property NSString* token;
@property NSString* objectDescription;

@end

@interface APPViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation ViewController

AVCaptureSession *session;
AVCaptureStillImageOutput *still_image_output;

NSArray *recycling_terms;
NSArray *compost_terms;

#pragma mark - View Loading Stuff
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.47 green:0.78 blue:0.60 alpha:1.0]];
    
    [_countdown setFont:[UIFont fontWithName:@"Helvetica" size:215 ]];
    _countdown.textColor = [UIColor whiteColor];
    _countdown.text = @"3";
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(triggerCountdownValue:)
                                   userInfo:nil
                                    repeats:YES];
    
    // Initialize arrays
    recycling_terms = [NSArray arrayWithObjects:@"bottle", @"cardboard", @"paper", nil];
    compost_terms = [NSArray arrayWithObjects:@"banana", @"apple", @"fruit", @"vegetable", nil];
    
    // KVO
    [self addObserver:self forKeyPath:@"token" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"objectDescription" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void)triggerCountdownValue:(NSTimer *)timer {
    if([_countdown.text  isEqual: @"3"]){
        _countdown.text = @"2";
    }
    else if([_countdown.text  isEqual: @"2"]){
        _countdown.text = @"1";
    }
    else if([_countdown.text  isEqual: @"1"]){
        //take a picture;
        [timer invalidate];
        timer = nil;
        [self capturePhoto];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    AVCaptureDevice *input_device = [self frontFacingCameraIfAvailable];
    NSError *error;
    AVCaptureDeviceInput *device_input = [AVCaptureDeviceInput deviceInputWithDevice:input_device error:&error];
    
    if ([session canAddInput:device_input]) {
        [session addInput:device_input];
    }
    
    AVCaptureVideoPreviewLayer *preview_layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    preview_layer.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    
    [preview_layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *root_layer = [[self view] layer];
    [root_layer setMasksToBounds:YES];
    CGRect frame = frame_for_capture.frame;
    [preview_layer setFrame:frame];
    [root_layer insertSublayer:preview_layer atIndex:0];
    
    still_image_output = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *output_settings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [still_image_output setOutputSettings:output_settings];
    [session addOutput:still_image_output];
    [session startRunning];
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

- (IBAction)takePhoto:(id)sender {
    [self capturePhoto];
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
            
            // Create path.
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
            
            // Save image.
            [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
            
            NSURL *imageUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
            
            // Save image to camera roll so that we can get a path for the image to send to the API later
            if (image != nil) {
                NSString *imgDataAsString = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];;
                
                [self getTokenWithImgData:imageUrl];
            }
        }
    }];
}

// Helen: this is where we would have to trigger the garbage, recycling or compost flows
- (void)handleImageSearchResultForSearchTerm:(NSString *)search_term {
    if ([self array:compost_terms ContainsStringOrSimilar:search_term]) {
        // proceed with garbage flow
    } else if ([self array:recycling_terms ContainsStringOrSimilar:search_term]) {
        // proceed with recycling flow
    } else {
        // proceed with garbage flow
    }
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

- (NSString*)getPhotoPath:(UIImage*)image {
    if (image != nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:
                          @"test.png" ];
        NSData* data = UIImagePNGRepresentation(image);
        [data writeToFile:path atomically:YES];
        return path;
    }
    
    return @"error";
}

#pragma mark - Reverse Image Search API

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"token"]) {// calls getDescriptionWithToken whenever the "token" value is updated (i.e. new photo)
        
        double delayInSeconds = 20.0; // Mashape recommends we wait 8-10 seconds before querying, and if we don't get a return result repeat every 1-2 seconds after. After some rough testing I found 20 seconds to be stable....if we have time and enough query calls after I'll add functionality to do it 8-10 seconds after and repeat every 1-2 seconds until we get a result
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self getDescriptionWithToken];
        });
        
    } else if ([keyPath isEqualToString:@"description"]) { // call the function to implement once we get a return result here!
        
        NSLog(_objectDescription);
        [self handleImageSearchResultForSearchTerm:_objectDescription];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)getTokenWithImgData:(NSURL *)imgDataAsString {
    
    NSDictionary *headers = @{@"X-Mashape-Key": @"horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r"};
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
    
    NSDictionary *headers = @{@"X-Mashape-Key": @"horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r", @"Accept": @"application/json"};
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