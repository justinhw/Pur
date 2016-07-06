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
    // testing token. getTokenWithImg should return this
    NSString *token = [self getTokenWithImg];

    [self getDescriptionWithToken:token];
    
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

- (NSString*)getTokenWithImg {
    
    NSString *url = @"https://camfind.p.mashape.com/image_requests";
    NSString *headers = @"?mashape-key=horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", url, headers];
    
    NSError *error;
    NSDictionary *parameters = @{@"image_request[image]": @"BINARY IMAGE HERE"}; // need to input BINARY
    NSData *parameters_json =[NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:parameters_json];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(string);
         }
     }];
    
    return @"9JKAWHKGLjqMdDKDNIJQfg";
    }


- (void)getDescriptionWithToken:(NSString*) token {

    NSString *headers = @"?mashape-key=horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
    NSString *url = @"https://camfind.p.mashape.com/image_responses/";
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@%@", url, token, headers];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(string);
         }
     }];
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
