//
//  PlayViewController.m
//  YMVideoPlay
//
//  Created by msy on 2017/8/16.
//  Copyright © 2017年 YM. All rights reserved.
//

#import "PlayViewController.h"
#import "videoView.h"
#import "AppDelegate.h"


#define MP4_URL @"http://test2.wootide.net/scenicsys/media/video/3c2e9c0ca12f4a889dd7cc7d59f3037a.mp4"

@interface PlayViewController ()

@property (nonatomic,strong)videoView *playView;

@end

@implementation PlayViewController


- (BOOL)shouldAutorotate {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"视频播放";
    self.view.backgroundColor = [UIColor whiteColor];
    [self createUI];
}

- (void)dealloc{
    [self.playView pasueVideo];
    [self.playView releaseResources];
    self.playView = nil;
}

///////////////////////////////////////////////////////////////
// 如视频不能播放提示:App Transport Security has blocked a cleartext HTTP (http://) resource load
// 解决方式:
// 1.在 Info.plist 中添加NSAppTransportSecurity类型Dictionary。
// 2.在NSAppTransportSecurity下添加NSAllowsArbitraryLoads类型Boolean, 值设为YES
///////////////////////////////////////////////////////////////

#pragma mark - UI
- (void)createUI{
    // 播放的view 和 URL
    self.playView = [[videoView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, 200) AndURL:MP4_URL];
    // 先添加到视图上  在进行播放
    [self.view addSubview:self.playView];
    // 播放
    [self.playView playVideo];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
