//
//  ResultsViewController.m
//  pur
//
//  Created by Varnit Grewal on 2016-07-11.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "ResultsViewController.h"
#import "DashboardViewController.h"

@interface ResultsViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progress_bar;
@property (weak, nonatomic) IBOutlet UIImageView *swipe_card;
@property (weak, nonatomic) IBOutlet UIImageView *drop_right;
@property (weak, nonatomic) IBOutlet UIImageView *drop_down;
@property (weak, nonatomic) IBOutlet UIImageView *drop_left;

@property (weak, nonatomic) IBOutlet UIImageView *compost;
@property (weak, nonatomic) IBOutlet UIImageView *garbage;
@property (weak, nonatomic) IBOutlet UIImageView *recycling;

@end

@implementation ResultsViewController

UIImageView *waste_type;
UIImageView *drop_dir;

float timerValue = 0.0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init results to transparent
    _compost.alpha = 0.0;
    _garbage.alpha = 0.0;
    _recycling.alpha = 0.0;
    
    //init text
    _swipe_card.alpha = 0.0;
    _drop_right.alpha = 0.0;
    _drop_down.alpha = 0.0;
    _drop_left.alpha = 0.0;
    
    //progress bar
    timerValue = 0.0;
    _progress_bar.alpha = 1.0;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated  {
    [super viewDidAppear:animated];
    
    //progress
    _progress_bar.progress = 0.0;
    [self performSelectorOnMainThread:@selector(makeMyProgressBarMove) withObject:nil waitUntilDone:NO];
}

-(void) startAnimations{
    [UIView animateWithDuration: 2.0f
                          delay: 3.0f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                         drop_dir.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                     }
     ];
    [UIView animateWithDuration: 2.0f
                          delay: 3.0f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                         _swipe_card.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                     }
     ];
}

-(void)switchToDashboard{
    //switch to dashboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DashboardViewController *dashboardViewController = (DashboardViewController *)[storyboard instantiateViewControllerWithIdentifier:@"DashboardViewController"];
    [self presentViewController:dashboardViewController animated:YES completion:nil];
    
}

-(void)makeMyProgressBarMove {
    timerValue++;
    float actual = [_progress_bar progress];
    if (actual < 1) {
        _progress_bar.progress = actual + ((float)timerValue/(float)4.0);
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(makeMyProgressBarMove) userInfo:nil repeats:NO];
    }
    else{
        //check saved data info to see which waste type was found
        NSString *garbage_type = [[NSUserDefaults standardUserDefaults] stringForKey:@"waste_type"];
        
        if ([garbage_type  isEqual: @"recycle"]) {
            waste_type = _recycling;
            drop_dir = _drop_right;
            
        } else if ([garbage_type  isEqual: @"compost"]) {
            waste_type = _compost;
            drop_dir = _drop_down;
            
        } else {
            waste_type = _garbage;
            drop_dir = _drop_left;
        }
        
        _progress_bar.alpha = 0.0;
        waste_type.alpha= 1.0;
        drop_dir.alpha = 1.0;
        
        [self startAnimations];
        [self performSelector:@selector(switchToDashboard) withObject:nil afterDelay:18.0];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
}
@end
