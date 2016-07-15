//
//  DashboardViewController.h
//  pur
//
//  Created by Varnit Grewal on 2016-07-11.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
@interface DashboardViewController : UIViewController {
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImagePicture *sourcePicture;
    GPUImageUIElement *uiElementInput;
    
    GPUImageFilterPipeline *pipeline;
    UIView *faceView;
    
    CIDetector *faceDetector;
}

@end
