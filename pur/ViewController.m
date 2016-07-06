//
//  ViewController.m
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ViewController.h"
@import AssetsLibrary;

@interface ViewController ()
@property (nonatomic) UIButton *takePhotoBtn;
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
    
    // Initialize arrays
    garbage_terms = [NSArray arrayWithObjects:@"styrofoam", nil];
    recycling_terms = [NSArray arrayWithObjects:@"bottle", @"cardboard", @"paper", nil];
    compost_terms = [NSArray arrayWithObjects:@"banana", @"apple", @"fruit", @"vegetable", nil];
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
            
            // Save image to camera roll so that we can get a path for the image to send to the API later
            if (image != nil) {
                NSString *path = [self getPhotoPath:image];
                NSLog(path);
                
                image_view.image = image;
            }
        }
    }];
    
    [self getDescriptionWithToken];
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
    // May want to consider using fuzzy string matching if we have time
    if ([array containsObject:string]) {
        return true;
    } else {
        return false;
    }
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

- (void)getTokenWithImg {
    NSString *mashape_key = @"horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
    NSString *img_url = @"http://upload.wikimedia.org/wikipedia/en/2/2d/Mashape_logo.png";
    
    NSError *error;
    
    NSDictionary *headers = @{@"mashape-key": mashape_key, @"Content-Type": @"application/x-www-form-urlencoded", @"Accept": @"application/json"};
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
    //fix this...{token} value & {mashape-key value}
    NSString *url = @"https://camfind.p.mashape.com/image_responses/9JKAWHKGLjqMdDKDNIJQfg?mashape-key=horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
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
}

@end
