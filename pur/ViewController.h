//
//  ViewController.h
//  pur
//
//  Created by Justin Wong on 2016-06-29.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController {
    IBOutlet UIView *frame_for_capture;
    IBOutlet UIImageView *image_view;
}

- (IBAction)takePhoto:(id)sender;

@end


