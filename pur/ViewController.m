//
//  ViewController.m
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic) UIButton *takePhotoBtn;
@end

@interface APPViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation ViewController

AVCaptureSession *session;
AVCaptureStillImageOutput *still_image_output;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    [self getDescriptionWithToken];
    
    /*AVCaptureConnection *video_connection = nil;
    
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
            image_view.image = image;
        }
    }];*/
}

- (void)getTokenWithImg {
    NSString *mashape_key = @"horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
    NSString *img_url = @"http://upload.wikimedia.org/wikipedia/en/2/2d/Mashape_logo.png";
    
    NSError *error;
    
    NSDictionary *headers = @{@"mashape-k   ey": mashape_key, @"Content-Type": @"application/x-www-form-urlencoded", @"Accept": @"application/json"};
    NSDictionary *parameters = @{@"focus[x]": @"480", @"focus[y]": @"640", @"image_request[altitude]": @"27.912109375", @"image_request[language]": @"en", @"image_request[latitude]": @"35.8714220766008", @"image_request[locale]": @"en_US", @"image_request[longitude]": @"14.3583203002251", @"image_request[remote_image_url]": img_url};
    NSData *parameters_json =[NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *url = @"https://camfind.p.mashape.com/image_requests";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:parameters_json];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSLog(@"success");
         } else {
             NSLog(@"failed");
         }
     }];
}


- (void)getDescriptionWithToken {
    NSString *mashape_key = @"horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
    
    NSDictionary *headers = @{@"mashape-key": @"horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r", @"Accept": @"application/json"};
    NSString *url = @"https://camfind.p.mashape.com/image_responses/9JKAWHKGLjqMdDKDNIJQfg";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSLog(@"success");
         } else {
             NSLog(@"failed");
         }
     }];
    
//    UNIUrlConnection *asyncConnection = [[UNIRest get:^(UNISimpleRequest *request) {
//        [request setUrl:@"https://camfind.p.mashape.com/image_responses/9JKAWHKGLjqMdDKDNIJQfg"];
//        [request setHeaders:headers];
//    }] asJsonAsync:^(UNIHTTPJsonResponse *response, NSError *error) {
//        NSInteger code = response.code;
//        NSDictionary *responseHeaders = response.headers;
//        UNIJsonNode *body = response.body;
//        NSData *rawBody = response.rawBody;
//    }];
}

- (void)test2 {
    NSURL *url = [NSURL URLWithString:@"http://rest-service.guides.spring.io/greeting"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSDictionary *greeting = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:NULL];
             NSLog([[greeting objectForKey:@"id"] stringValue]);
//             self.greetingId.text = [[greeting objectForKey:@"id"] stringValue];
//             self.greetingContent.text = [greeting objectForKey:@"content"];
         }
     }];
}

@end
