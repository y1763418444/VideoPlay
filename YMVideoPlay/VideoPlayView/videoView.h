//
//  videoView.h
//  iOSReview
//
//  Created by Apple on 2017/8/8.
//  Copyright © 2017年 KennyHito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Header.h"

@interface videoView : UIView

// 初始化
- (instancetype)initWithFrame:(CGRect)frame AndURL:(NSString *)videoURL;
// 播放
- (void)playVideo;
// 暂停
- (void)pasueVideo;
// 释放资源
- (void)releaseResources;

@end
