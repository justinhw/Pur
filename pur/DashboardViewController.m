//
//  DashboardViewController.m
//  pur
//
//  Created by Varnit Grewal on 2016-07-11.
//  Copyright © 2016 justinSYDE. All rights reserved.
//

#import "DashboardViewController.h"

@interface DashboardViewController ()
@property (weak, nonatomic) IBOutlet UILabel *compost_kg;
@property (weak, nonatomic) IBOutlet UILabel *recycling_kg;
@property (weak, nonatomic) IBOutlet UILabel *garbage_kg;
@property (weak, nonatomic) IBOutlet UIImageView *hold_item;

@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [UIView animateWithDuration: 1.75f
                          delay:0.5f
                        options:  UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                     animations:^(void) {
                        _hold_item.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                     }
    ];
    
    [_garbage_kg setFont:[UIFont fontWithName:@"Helvetica" size:54 ]];
    _garbage_kg.textColor = [UIColor whiteColor];
    _garbage_kg.text = @"200 kg";
    
    [_recycling_kg setFont:[UIFont fontWithName:@"Helvetica" size:54 ]];
    _recycling_kg.textColor = [UIColor whiteColor];
    _recycling_kg.text = @"150 kg";
    
    [_compost_kg setFont:[UIFont fontWithName:@"Helvetica" size:54 ]];
    _compost_kg.textColor = [UIColor whiteColor];
    _compost_kg.text = @"50 kg";
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
