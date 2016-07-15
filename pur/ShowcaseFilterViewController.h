#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface ShowcaseFilterViewController : UIViewController <GPUImageVideoCameraDelegate>
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImagePicture *sourcePicture;
    GPUImageUIElement *uiElementInput;
    
    GPUImageFilterPipeline *pipeline;
    UIView *faceView;
    
    CIDetector *faceDetector;
}

- (void)setupFilter;

@end
