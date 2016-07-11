//
//  ViewController.m
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ViewController.h"
#import <UNIRest.h>

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
            
            // Create path.
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
            
            // Save image.
            [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
            
            NSURL *imageUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
            
//            NSFileManager *fileManager = [NSFileManager defaultManager];
//            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//            NSString *documentsDirectory = [paths objectAtIndex:0];
//            NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:@".png"];
//            [fileManager createFileAtPath:fullPath contents:image_data attributes:nil];
//            
//            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
//                
//            {
//                NSURL *imageUrl = [NSURL fileURLWithPath:fullPath isDirectory:NO];
//                NSLog(@"test");
//            }
            
            // Save image to camera roll so that we can get a path for the image to send to the API later
            if (image != nil) {
                NSString *imgDataAsString = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];;
                NSString *token = [self getTokenWithImgData:imageUrl];
                NSString *response = [self getDescriptionWithToken:token];

                image_view.image = image;
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

- (NSString*)getTokenWithImgData:(NSURL *)imgDataAsString {
    
    __block NSString* token;
    
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
        
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:rawBody
                                                             options:kNilOptions
                                                               error:&error];
        token = [json[@"token"] stringValue] ;
    }];
    
    return token;
}


- (NSString *)getDescriptionWithToken:(NSString*) token {
    
    NSLog(token);
    
    NSString *description;
    
    NSString *url = @"https://camfind.p.mashape.com/image_responses/";
    NSString *headers = @"?mashape-key=horcs5Q9Ddmsh1lzJ9dhI2q2h3D1p1cvrI0jsnYzNbOKZ4M16r";
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@%@", url, token, headers];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             __block description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         }
     }];
    
    return description;
}

@end
