//
//  ResultsViewController.m
//  pur
//
//  Created by Varnit Grewal on 2016-07-11.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ResultsViewController.h"

@interface ResultsViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *swipe_card;
@property (weak, nonatomic) IBOutlet UIImageView *drop_right;
@property (weak, nonatomic) IBOutlet UIImageView *drop_down;
@property (weak, nonatomic) IBOutlet UIImageView *drop_left;

@property (weak, nonatomic) IBOutlet UIImageView *compost;
@property (weak, nonatomic) IBOutlet UIImageView *garbage;
@property (weak, nonatomic) IBOutlet UIImageView *recycling;

@end

@implementation ResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init results to transparent
    _compost.alpha = 0.0;
    _garbage.alpha = 0.0;
    _recycling.alpha = 0.0;
    
    //init text
    _swipe_card.alpha = 0.0;
    _drop_right.alpha = 1.0;
    _drop_down.alpha = 0.0;
    _drop_left.alpha = 0.0;
    
    // Do any additional setup after loading the view.
    NSString *garbage_type = [[NSUserDefaults standardUserDefaults] stringForKey:@"waste_type"];
    
    if ([garbage_type  isEqual: @"recycle"]) {
        
    } else if ([garbage_type  isEqual: @"compost"]) {
        
    } else {
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated  {
    [super viewDidAppear:animated];
    //hold item here - flashing
    [UIView animateWithDuration: 1.75f
                          delay: 0.5f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                         _drop_right.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                     }
     ];
    [UIView animateWithDuration: 1.75f
                          delay: 2.4f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                         _swipe_card.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                     }
     ];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
