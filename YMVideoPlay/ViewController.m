//
//  ViewController.m
//  YMVideoPlay
//
//  Created by msy on 2017/8/16.
//  Copyright © 2017年 YM. All rights reserved.
//

#import "ViewController.h"
#import "PlayViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频列表";
}


- (IBAction)playClick:(UIButton *)sender {
    PlayViewController *vc = [[PlayViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
