//
//  ViewController.h
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import <AVFoundation/AVFoundation.h>
//#import "Unirest/UNIRest.h"

@interface ViewController : UIViewController {
    IBOutlet UIView *frame_for_capture;
    IBOutlet UIImageView *image_view;
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImagePicture *sourcePicture;
    GPUImageUIElement *uiElementInput;
    
    GPUImageFilterPipeline *pipeline;
    UIView *faceView;
    
    CIDetector *faceDetector;

}

@end


