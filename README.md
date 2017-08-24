使用简单 简单 简单 重要的事情说三遍

#VideoPlay是一个简单的网络视频播放器(包含以下功能)

1.左右旋转屏幕放大或点击放大按钮

2.前后台切换不会影响视频播放

3.屏幕左侧上下滑动改变屏幕亮度

4.屏幕右侧上下滑动改变播放音量

5.屏幕左右滑动改变播放进度

6.状态栏跟随屏幕旋转的方向改变

7.双击屏幕播放或暂停

使用非常简单,方法如下

// 播放的view 和 URL

videoView *playView = [[videoView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, 200) AndURL:@"视频地址"];

// 先添加到视图上  在进行播放

[self.view addSubview:self.playView];

// 播放

[playView playVideo];
