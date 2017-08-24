//
//  videoView.m
//  iOSReview
//
//  Created by Apple on 2017/8/8.
//  Copyright © 2017年 KennyHito. All rights reserved.
//

#import "videoView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MRVideoHUDView.h"
#import "UIView+ViewController.h"

@interface videoView()
{
    CGFloat width;//当前高度
    CGFloat height;//当前宽度
    CGFloat light; // 屏幕亮度
    CGFloat voice; // 音量
    CGRect initFrame; // 初始化时的frame
    UIView *SView; // 初始化时的父View
    CGPoint cenPoint; // 初始化是中心点
    BOOL isStop; // 结束播放
    UIInterfaceOrientation lastStatus; // 上次旋转状态
    
    CGFloat sumTime; // 用来保存快进的总时长
}

@property (nonatomic,strong) UILabel * startLab;//播放时间
@property (nonatomic,strong) UILabel * totalLab;//总时间
@property (nonatomic,strong) UISlider * slider;//进度条
@property (nonatomic,strong) UIButton * bigBtn;//放大
@property (nonatomic,strong) UIButton * playBtn;//播放,暂停

@property (nonatomic,strong) AVPlayer * player;//AVPlayer
@property (nonatomic,strong) AVPlayerItem * item;
@property (nonatomic,strong) AVPlayerLayer * playLayer;

@property (nonatomic,assign) BOOL flag;//横屏,竖屏
@property (nonatomic,strong) MPVolumeView * volumeView;
@property (nonatomic,strong) UISlider * volumeViewSlider;
@property (nonatomic,copy) NSString * url;//视频地址
@property (nonatomic, strong) MRVideoHUDView *indicatorView;
@end

@implementation videoView
 //距离下边距
static CGFloat bottomHeight = 25;

/* 构造函数 */
- (instancetype)initWithFrame:(CGRect)frame AndURL:(NSString *)videoURL{
    if (self = [super initWithFrame:frame]) {
        self.url = videoURL;
        self.backgroundColor = [UIColor grayColor];
        [self setUpUI];
        initFrame = self.frame;
        
        // app退到后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
        
        // app进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        // 监测设备方向
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDeviceOrientationChange)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - 释放内存
- (void)releaseResources{

    [self.playLayer removeFromSuperlayer];
    self.playLayer=nil;
    self.player=nil;
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 应用退到后台
- (void)appDidEnterBackground {
    [self pasueVideo];
}

#pragma mark - 应用进入前台
- (void)appDidEnterPlayground {
    if (!self.playBtn.isSelected){
        [self playVideo];
    }
}

#pragma mark - 屏幕方向发生变化会调用这里
- (void)onDeviceOrientationChange {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:{
            [self verticalScreen];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            [self crossScreen:UIInterfaceOrientationLandscapeLeft];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            [self crossScreen:UIInterfaceOrientationLandscapeRight];
        }
            break;
        default:
            break;
    }
}

#pragma mark - 播放
- (void)playVideo{
    lastStatus = UIInterfaceOrientationPortrait; //初始化竖屏
    SView = self.superview;
    cenPoint = self.center;
    [self.player play];
    [self setSubViewsFrame];
    [self setVideoTime];
}

#pragma mark - 暂停
- (void)pasueVideo{
    [self.player pause];
}

#pragma mark - 加载框
- (MRVideoHUDView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[MRVideoHUDView alloc] init];
        _indicatorView.bounds = CGRectMake(0, 0, 80, 80);
    }
    return _indicatorView;
}

#pragma mark - 创建view
- (void)setUpUI{
    
    self.userInteractionEnabled = YES;
    // 滑动事件
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panClick:)];
    [self addGestureRecognizer:pan];
    // 点击事件
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapClick:)];
    doubleTap.numberOfTouchesRequired = 1; //手指数
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    _flag = YES;
    
    //获得当前屏幕亮度
    light = [UIScreen mainScreen].brightness;
    //获得系统当前音量
    self.volumeView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width * 9.0 / 16.0);
}

#pragma mark -- 增加音量
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}

#pragma mark - 屏幕滑动事件
- (void)panClick:(UIPanGestureRecognizer *)panGR{
    
    //locationInView : 获取view的具体位置点
    CGPoint translation = [panGR locationInView:self];
    
    //velocityInView : 用来区分上下移动,还是左右移动
    CGPoint velocity = [panGR velocityInView:self];
    
    if (velocity.x>-10 && velocity.x<10) {
        //只能允许上下移动
        
        if (translation.x < width/2) {
            //左侧
            if (velocity.y < 0) {
                if (light < 1) {
                    //向上滑动亮度增加
                    light = light + 0.01;
                }else{
                    //当亮度为1时固定为1，禁止大于1
                    light = 1;
                }
            }else{
                if (light > 0) {
                    //向下滑动屏幕变暗，亮度下降
                    light = light - 0.01;
                }else{
                    //当亮度为0时固定为0，禁止为负值
                    light = 0;
                }
            }
            //设置屏幕亮度
            [UIScreen mainScreen].brightness = light;
            
        }else{
            //右侧
            if (velocity.y < 0) {
                if (voice < 1) {
                    voice = voice + 0.03;
                }else{
                    voice = 1;
                }
            }else{
                if (voice > 0) {
                    voice = voice - 0.03;
                }else{
                    voice = 0;
                }
            }
            [self.volumeViewSlider setValue:voice animated:NO];
        }
    }else{
        switch (panGR.state) {
            case UIGestureRecognizerStateBegan:{ // 开始移动
                // 给sumTime初值
                CMTime time       = self.player.currentTime;
                sumTime      = time.value/time.timescale;
                break;
            }
            case UIGestureRecognizerStateChanged:{ // 正在移动
                [self horizontalMoved:velocity.x]; // 水平移动的方法只要x方向的值
                break;
            }
            case UIGestureRecognizerStateEnded:{ // 移动停止
                // 移动结束也需要判断垂直或者平移
                // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
                [self.player pause];
                CMTime dragedCMTime = CMTimeMake(sumTime, 1); //kCMTimeZero
                if (!dragedCMTime.timescale) {
                    self.indicatorView.hidden = NO;
                }
                __weak typeof(self) weakSelf = self;
                [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
                    self.indicatorView.hidden = YES;
                    if (self.playBtn.isSelected){
                        self.playBtn.selected = !self.playBtn.selected;
                    }
                    // 视频跳转回调
                    [weakSelf.player play];
                }];

                // 把sumTime滞空，不然会越加越多
                sumTime = 0;
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - 屏幕点击事件
- (void)doubleTapClick:(UITapGestureRecognizer *)tap{
    self.playBtn.selected = !self.playBtn.selected;
    if (!self.playBtn.isSelected){
        [self.player play];
    }else{
        [self.player pause];
    }
}

#pragma mark - pan水平移动的方法
- (void)horizontalMoved:(CGFloat)value {
    // 每次滑动需要叠加时间
    sumTime += value / 300;
    
    // 需要限定sumTime的范围
    CMTime totalTime = self.item.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (sumTime > totalMovieDuration) { sumTime = totalMovieDuration;}
    if (sumTime < 0) { sumTime = 0; }
}

#pragma mark - 设置控件大小
- (void)setSubViewsFrame{
    width = self.bounds.size.width;
    height= self.bounds.size.height;
    self.playBtn.frame = CGRectMake(10, height-bottomHeight, 20, 20);
    self.startLab.frame = CGRectMake(CGRectGetMaxX(self.playBtn.frame)+10, height-bottomHeight, 40, 20);
    self.bigBtn.frame = CGRectMake(ScreenWidth-30, height-bottomHeight, 20, 20);
    self.totalLab.frame = CGRectMake(CGRectGetMinX(self.bigBtn.frame)-50, height-bottomHeight, 40, 20);
    self.slider.frame = CGRectMake(CGRectGetMaxX(self.startLab.frame)+5,height-bottomHeight,ScreenWidth-CGRectGetWidth(self.playBtn.frame)-CGRectGetWidth(self.bigBtn.frame)-CGRectGetWidth(self.bigBtn.frame)-CGRectGetWidth(self.startLab.frame)-70,20);
    self.playLayer.frame = CGRectMake(0, 0, width, height);
    
    self.indicatorView.center     = CGPointMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2);
    [self addSubview:self.indicatorView];
}

#pragma mark - 拖动滚动条
- (void)sliderClick:(UISlider *)sender{
    if (self.playBtn.isSelected){
        self.playBtn.selected = !self.playBtn.selected;
    }
    [self.player pause];
    //获得当前时间
    CMTime currentTime = CMTimeMake(_player.currentItem.duration.value * sender.value, _player.currentItem.duration.timescale);
    //跳转到curentTime的位置播放
    if (!currentTime.timescale) {
        self.indicatorView.hidden = NO;
    }else{
        self.indicatorView.hidden = YES;
        [self.player seekToTime:currentTime];
        [self.player play];
    }
}

#pragma mark - 获取视频时间
- (void)setVideoTime{
    __weak typeof(self)weakSelf = self;
    
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(30, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        weakSelf.indicatorView.hidden = YES;
        //获取总时间
        float totalTime = weakSelf.player.currentItem.duration.value*1.0/weakSelf.player.currentItem.duration.timescale;
        
        //获取当前时间
        float currentTime = weakSelf.player.currentItem.currentTime.value*1.0/weakSelf.player.currentTime.timescale;
        
        //当前播放时间
        weakSelf.startLab.text = [NSString stringWithFormat:@"%@",[weakSelf sendTimeCGFloat:currentTime]];
        //显示总时间
        weakSelf.totalLab.text = [NSString stringWithFormat:@"%@",[weakSelf sendTimeCGFloat:totalTime]];
        
        //用来显示拖动条的进度值
        weakSelf.slider.value = currentTime/totalTime;
        
        if (currentTime == totalTime){
            [weakSelf.player pause];
            weakSelf.playBtn.selected = YES;
            isStop = YES;
        }
    }];
}

#pragma mark - 获取变换的旋转角度
- (CGAffineTransform)getTransformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}
#pragma mark - 横屏,竖屏
- (void)bigBtnClick{
    if (_flag) {
        
        /*
        // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
        // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
        // 如果自定义nav需要重写
        - (BOOL)shouldAutorotate{
            return [[self.viewControllers lastObject] shouldAutorotate];
        }
        - (NSUInteger)supportedInterfaceOrientations {
            return [[self.viewControllers lastObject] supportedInterfaceOrientations];
        }
        - (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
            return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
        }
         */
        
        // 横屏
        [self crossScreen:UIInterfaceOrientationLandscapeRight];
    }else{
        // 竖屏
        [self verticalScreen];
    }
}

#pragma mark - 旋转view
- (void)rotateView{
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
    self.transform = CGAffineTransformIdentity;
    self.transform = [self getTransformRotationAngle];
    // 开始旋转
    [UIView commitAnimations];
}

#pragma mark - 横屏
- (void)crossScreen:(UIInterfaceOrientation)orien{
    
    // 隐藏导航栏
    [self.viewController.navigationController setNavigationBarHidden:YES animated:NO];
    
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orien) { return; }
    
    UIWindow *win = [[UIApplication sharedApplication] windows].lastObject;
    // 根据要旋转的方向,使用Masonry重新修改限制
    if (orien != UIInterfaceOrientationPortrait) {//
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            self.frame = CGRectMake(0, 0, win.bounds.size.height, win.bounds.size.width-20);
            [win addSubview:self];
        }
    }
    if (orien == UIInterfaceOrientationLandscapeLeft){
        self.center = CGPointMake(win.center.x+10, win.center.y);
    }else{
        self.center = CGPointMake(win.center.x-10, win.center.y);
    }
    
    [[UIApplication sharedApplication] setStatusBarOrientation:orien animated:NO];
    _flag = false;
    
    // 旋转
    [self rotateView];
    [self setSubViewsFrame];
}

#pragma mark - 竖屏
- (void)verticalScreen{
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    //竖屏
    _flag = YES;
    [self rotateView];
    self.frame = initFrame;
    self.center = cenPoint;
    [SView addSubview:self];
    [self setSubViewsFrame];
    // 显示导航栏
    self.viewController.navigationController.navigationBarHidden = NO;
}
#pragma mark - 播放,暂停
- (void)playBtnClick:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        if (!self.indicatorView.isHidden){
            self.indicatorView.hidden = YES;
        }
        [self.player pause];
    }else{
        if (isStop){
            //获得当前时间
            CMTime currentTime = CMTimeMake(_player.currentItem.duration.value * 0, _player.currentItem.duration.timescale);
            [self.player seekToTime:currentTime];
            self.startLab.text = @"00:00";
            self.volumeViewSlider.value = 0;
            isStop = NO;
        }
        [self.player play];
        self.indicatorView.hidden = NO;
    }
}

#pragma mark - 拖动条点击事件
- (void)tapGRClick:(UITapGestureRecognizer *)sender {
    if (self.playBtn.isSelected){
        self.playBtn.selected = !self.playBtn.selected;
    }
    //1.首先设置slider上的值
    CGPoint touchPoint = [sender locationInView:_slider];
    CGFloat value = (_slider.maximumValue - _slider.minimumValue) * (touchPoint.x / _slider.frame.size.width );
    [_slider setValue:value animated:YES];
    
    //2.根据value设置播放进度
    CMTime currentTime = CMTimeMake(_player.currentItem.duration.value * value, _player.currentItem.duration.timescale);
    //跳转到curentTime的位置播放
    if (!currentTime.timescale) {
        self.indicatorView.hidden = NO;
    }else{
        self.indicatorView.hidden = YES;
        [self.player seekToTime:currentTime];
        [self.player play];
    }
}


#pragma mark - 设置时间
- (NSString *)sendTimeCGFloat:(CGFloat)time{
    //转化时间的格式
    NSDate*d = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter*formatter = [[NSDateFormatter alloc]init];
    if(time/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }else{
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString * showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

#pragma mark -------------------------懒加载----------------------------
- (AVPlayer *)player{
    if (!_player) {
        self.item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.url]];
        _player = [[AVPlayer alloc]initWithPlayerItem:self.item];
        self.playLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        self.playLayer.frame = CGRectMake(0, 0, width, height);
        self.playLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.layer.backgroundColor = [UIColor blackColor].CGColor;
        [self.layer addSublayer:self.playLayer];
    }
    return _player;
}

- (UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:0];
        _playBtn.frame = CGRectMake(10, height-bottomHeight, 20, 20);
        [_playBtn setImage:[UIImage imageNamed:@"videoPause"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage imageNamed:@"videoPlay"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playBtn];
    }
    return _playBtn;
}

- (UILabel *)startLab{
    if (!_startLab) {
        _startLab = [[UILabel alloc]init];
        _startLab.frame = CGRectMake(CGRectGetMaxX(_playBtn.frame)+10, height-bottomHeight, 40, 20);
        _startLab.text = @"00:00";
        _startLab.textColor = [UIColor whiteColor];
        _startLab.font = [UIFont systemFontOfSize:11];
        [self addSubview:_startLab];
    }
    return _startLab;
}
- (UIButton *)bigBtn{
    if (!_bigBtn) {
        _bigBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _bigBtn.frame = CGRectMake(ScreenWidth-30, height-bottomHeight, 20, 20);
        [_bigBtn setImage:[UIImage imageNamed:@"videofang"] forState:UIControlStateNormal];
        [_bigBtn addTarget:self action:@selector(bigBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_bigBtn];
    }
    return _bigBtn;
}
- (UILabel *)totalLab{
    if (!_totalLab) {
        _totalLab = [[UILabel alloc]init];
        _totalLab.frame = CGRectMake(CGRectGetMinX(self.bigBtn.frame)-50, height-bottomHeight, 40, 20);
        _totalLab.text = @"00:00";
        _totalLab.textColor = [UIColor whiteColor];
        _totalLab.font = [UIFont systemFontOfSize:11];
        [self addSubview:_totalLab];
    }
    return _totalLab;
}
- (UISlider *)slider{
    if (!_slider) {
        _slider = [[UISlider alloc]init];
        _slider.frame = CGRectMake(CGRectGetMaxX(self.startLab.frame)+5,height-bottomHeight,ScreenWidth-CGRectGetWidth(self.playBtn.frame)-CGRectGetWidth(self.bigBtn.frame)-CGRectGetWidth(self.bigBtn.frame)-CGRectGetWidth(self.startLab.frame)-70,20);
        _slider.minimumValue = 0;
        _slider.maximumValue = 1;
        [_slider addTarget:self action:@selector(sliderClick:) forControlEvents:UIControlEventValueChanged];
        UIImage * imagea= [self OriginImage:[UIImage imageNamed:@"videodian"] scaleToSize:CGSizeMake(15, 15)];
        [_slider setThumbImage:imagea forState:UIControlStateNormal];
        
        UITapGestureRecognizer * tapGR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGRClick:)];
        [_slider addGestureRecognizer:tapGR];
        [self addSubview:_slider];
    }
    return _slider;
}

/*
 对原来的图片的大小进行处理
 @param image 要处理的图片
 @param size  处理过图片的大小
 */
- (UIImage *)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *scaleImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaleImage;
}


@end
