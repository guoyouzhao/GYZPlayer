//
//  VideoPlayView.m
//  ioshuanwu
//
//  Created by gyz on 16/3/8.
//  Copyright © 2016年 幻音. All rights reserved.
//

#import "VideoPlayView.h"
#import "FullViewController.h"
#import "LoaderURLConnection.h"

#define kRandomColor [UIColor colorWithRed:arc4random_uniform(256) / 255.0 green:arc4random_uniform(256) / 255.0 blue:arc4random_uniform(256) / 255.0 alpha:1]
#define font [UIFont systemFontOfSize:15]
@interface VideoPlayView ()<CFDanmakuDelegate,LoaderURLConnectionDelegate>
@property (nonatomic, strong) LoaderURLConnection *resouerLoader;
// 播放器的Layer
@property (weak, nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVURLAsset     *videoURLAsset;
@property (nonatomic, strong) AVAsset        *videoAsset;

@property (strong, nonatomic)  UIImageView *imageView;
@property (strong, nonatomic)  UIView *toolView;
@property (strong, nonatomic)  UILabel *timeLabel;
@property (strong, nonatomic)  UISlider *voiceSlider;
// 记录当前是否显示了工具栏
@property (assign, nonatomic) BOOL isShowToolView;

/* 定时器 */
@property (nonatomic, strong) NSTimer *progressTimer;

/* 工具栏的显示和隐藏 */
@property (nonatomic, strong) NSTimer *showTimer;

/* 工具栏展示的时间 */
@property (assign, nonatomic) NSTimeInterval showTime;



@property (nonatomic, strong) NSTimer * timer;

#pragma mark - 监听事件的处理
- (void)playOrPause:(UIButton *)sender;
- (void)switchOrientation:(UIButton *)sender;
- (void)slider;
- (void)startSlider;
- (void)sliderValueChange;

- (void)tapAction:(UITapGestureRecognizer *)sender;
- (void)swipeAction:(UISwipeGestureRecognizer *)sender;
- (void)swipeRight:(UISwipeGestureRecognizer *)sender;
@property (strong, nonatomic) UIImageView *forwardImageView;

@property (strong, nonatomic) UIImageView *backImageView;


@end

@implementation VideoPlayView


// 快速创建View的方法

+ (instancetype)videoPlayView
{
    static dispatch_once_t onceToken;
    static id _sInstance;
    dispatch_once(&onceToken, ^{
        _sInstance = [[self alloc] init];
    });
    
    return _sInstance;
    
}
- (AVPlayer *)player
{
    if (!_player) {
        
        // 初始化Player和Layer
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    self.frame = CGRectMake(0, 0, kScreenWidth, 180);
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 180)];
    [self.imageView setImage:[UIImage imageNamed:@"bg_media_default"]];
    [self addSubview:self.imageView];

    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.imageView.layer addSublayer:self.playerLayer];
    
    self.toolView = [[UIView alloc]initWithFrame:CGRectMake(0, 140, kScreenWidth, 40)];
    self.backgroundColor = [UIColor blackColor];
    [self addSubview:self.toolView];
    // 设置工具栏的状态
    self.toolView.alpha = 0;
    self.isShowToolView = NO;
    
    self.forwardImageView.alpha = 0;
    self.backImageView.alpha = 0;
    
    self.playOrPauseBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 40)];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"full_play_btn"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"full_play_btn_hl"] forState:UIControlStateHighlighted];
    [self.playOrPauseBtn addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolView addSubview:self.playOrPauseBtn];
    
    self.progressSlider = [[UISlider alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_playOrPauseBtn.frame), 5, 152, 31)];
    [self.progressSlider addTarget:self action:@selector(slider) forControlEvents:UIControlEventTouchUpInside];
    [self.progressSlider addTarget:self action:@selector(startSlider) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(sliderValueChange) forControlEvents:UIControlEventValueChanged];
    
    [self addSubview:self.progressSlider];
    // 设置进度条的内容
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"thumbImage"] forState:UIControlStateNormal];
    [self.progressSlider setMaximumTrackImage:[UIImage imageNamed:@"MaximumTrackImage"] forState:UIControlStateNormal];
    [self.progressSlider setMinimumTrackImage:[UIImage imageNamed:@"MinimumTrackImage"] forState:UIControlStateNormal];
    CGAffineTransform rotation = CGAffineTransformMakeRotation(-1.57079633);
    [self.voiceSlider setTransform:rotation];
    [_voiceSlider addTarget:self action:@selector(voiceSliderChange:) forControlEvents:UIControlEventValueChanged];
    // 设置按钮的状态
    self.playOrPauseBtn.selected = NO;
    self.timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_progressSlider.frame), 12, 75, 15)];
    [self.timeLabel setText:@"00:00/00:00"];
    [self.timeLabel setTextColor:[UIColor whiteColor]];
    self.timeLabel.backgroundColor = [UIColor blackColor];
    
    [self addSubview:self.timeLabel];
    
    UIButton *fullButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_timeLabel.frame), 0, 50, 40)];
    [fullButton setImage:[UIImage imageNamed:@"mini_launchFullScreen_btn"] forState:UIControlStateNormal];
    [fullButton setImage:[UIImage imageNamed:@"mini_launchFullScreen_btn_hl"] forState:UIControlStateHighlighted];
    [fullButton addTarget:self action:@selector(switchOrientation:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:fullButton];
    
    
    [self showToolView:YES];
    [self setupDanmakuView];
    [self setupDanmakuData];
    }
    return self;
    
}
-(void)voiceSliderChange:(UISlider *)slider{
    
    
    NSArray *audioTracks = [self.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
    NSLog(@"%f",slider.value);
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:slider.value atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    
    [self.currentItem setAudioMix:audioMix];
    
    
}

#pragma mark - 观察者对应的方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (AVPlayerItemStatusReadyToPlay == status) {
            [self removeProgressTimer];
            [self addProgressTimer];
            [_danmakuView start];
        } else {
            [self removeProgressTimer];
        }
    }
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark - 重新布局
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
}

#pragma mark - 设置播放的视频
- (void)setUrlString:(NSString *)urlString
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
    
        _urlString = urlString;
        NSURL *url = [NSURL URLWithString:urlString];
    
        [self releasePlayer];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        self.currentItem = item;
        
        [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
        
        [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        
        // 添加视频播放结束通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
    });

    
}
//清空播放器监听属性
- (void)releasePlayer
{
    if (!self.currentItem) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.currentItem removeObserver:self forKeyPath:@"status"];
    
    self.currentItem = nil;
    
    [self.player pause];
    
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.progressSlider setValue:0.0 animated:YES];
        weakSelf.playOrPauseBtn.selected = NO;
    }];
}
// 是否显示工具的View
- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    [self showToolView:!self.isShowToolView];
    //    [self removeShowTimer];
    //    if (self.isShowToolView) {
    //        [self showToolView:YES];
    //    }
}

- (IBAction)swipeAction:(UISwipeGestureRecognizer *)sender {
    [self swipeToRight:YES];
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    [self swipeToRight:NO];
}

- (void)swipeToRight:(BOOL)isRight
{
    // 1.获取当前播放的时间
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
    
    if (isRight) {
        [UIView animateWithDuration:1 animations:^{
            self.forwardImageView.alpha = 1;
        } completion:^(BOOL finished) {
            self.forwardImageView.alpha = 0;
        }];
        currentTime += 10;
        
    } else {
        [UIView animateWithDuration:1 animations:^{
            self.backImageView.alpha = 1;
        } completion:^(BOOL finished) {
            self.backImageView.alpha = 0;
        }];
        currentTime -= 10;
        
    }
    
    if (currentTime >= CMTimeGetSeconds(self.player.currentItem.duration)) {
        
        currentTime = CMTimeGetSeconds(self.player.currentItem.duration) - 1;
    } else if (currentTime <= 0) {
        currentTime = 0;
    }
    
    [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    [self updateProgressInfo];
}




- (void)showToolView:(BOOL)isShow
{
    if (self.progressSlider.tag == 100) {
        
        //            [self showToolView:YES];
        [self removeShowTimer];
        self.progressSlider.tag = 20;
        return;
        
    }
    [UIView animateWithDuration:1.0 animations:^{
        self.toolView.alpha = !self.isShowToolView;
        self.isShowToolView = !self.isShowToolView;
    }];
}

// 暂停按钮的监听
- (void)playOrPause:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (sender == nil) {
        self.playOrPauseBtn.selected = NO;
    }
    if (sender.selected) {
        [self.player play];
        [self addShowTimer];
        [self addProgressTimer];
        if (_danmakuView.isPrepared) {
            if (!_timer) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimeCount) userInfo:nil repeats:YES];
            }
            [_danmakuView start];
        }
    } else {
        [self.player pause];
        [self removeShowTimer];
        [self removeProgressTimer];
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        [_danmakuView pause];
    }
}

#pragma mark - 定时器操作
- (void)addProgressTimer
{
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}

- (void)removeProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)updateProgressInfo
{
    // 1.更新时间
    self.timeLabel.text = [self timeString];
    
    self.progressSlider.value = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
    
    if(self.progressSlider.value == 1)
    {
        self.progressSlider.value = 0;
        self.progressSlider.tag = 100;
        //        [self playOrPause:nil];
        //        [self sliderValueChange];
        self.player = nil;
        self.playOrPauseBtn.selected = NO;
        self.toolView.alpha = 1;
        
        [self removeProgressTimer];
        [self removeShowTimer];
        self.timeLabel.text = @"00:00/00:00";
        return;
        
    }
    
}

- (NSString *)timeString
{
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentTime);
    //    if (self.player == nil) {
    //        return @"00:00/00:00";
    //    }
    return [self stringWithCurrentTime:currentTime duration:duration];
}

- (void)addShowTimer
{
    self.showTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateShowTime) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.showTimer forMode:NSRunLoopCommonModes];
}

- (void)removeShowTimer
{
    [self.showTimer invalidate];
    self.showTimer = nil;
}

- (void)updateShowTime
{
    self.showTime += 1;
    
    if (self.showTime > 2.0) {
        [self tapAction:nil];
        [self removeShowTimer];
        
        self.showTime = 0;
    }
}

#pragma mark - 通过代理方法实现切换屏幕的方向
- (void)switchOrientation:(UIButton *)sender {
    sender.selected = !sender.selected;
    [_delegate videoplayViewSwitchOrientation:sender.selected];
    //    [self videoplayViewSwitchOrientation:sender.selected];
}

- (void)slider {
    [self addProgressTimer];
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)startSlider {
    [self removeProgressTimer];
    
}

- (void)sliderValueChange {
    [self removeProgressTimer];
    [self removeShowTimer];
    if (self.progressSlider.value == 1) {
        self.progressSlider.value = 0;
    }
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    self.timeLabel.text = [self stringWithCurrentTime:currentTime duration:duration];
    [self addShowTimer];
    [self addProgressTimer];
}

- (NSString *)stringWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    //    if (currentTime == duration) {
    //        currentTime = 0;
    //
    ////        self.player.currentTime = currentTime;
    ////        [self updateProgressInfo];
    ////        [self sliderValueChange];
    ////        self.progressSlider.value = 0;
    //        self.playOrPauseBtn.selected = NO;
    //        self.toolView.alpha = 1;
    //
    //        [self removeProgressTimer];
    //        [self removeShowTimer];
    //        self.player = nil;
    //
    //    }
    NSInteger dMin = duration / 60;
    NSInteger dSec = (NSInteger)duration % 60;
    
    NSInteger cMin = currentTime / 60;
    NSInteger cSec = (NSInteger)currentTime % 60;
    
    NSString *durationString = [NSString stringWithFormat:@"%02ld:%02ld", dMin, dSec];
    NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
    
    return [NSString stringWithFormat:@"%@/%@", currentString, durationString];
}

#pragma mark - 懒加载代码
- (FullViewController *)fullVc
{
    if (_fullVc == nil) {
        _fullVc = [[FullViewController alloc] init];
    }
    return _fullVc;
}

#pragma mark - 弹幕
- (void)setupDanmakuView
{
    CGRect rect =  self.frame;
    _danmakuView = [[CFDanmakuView alloc] initWithFrame:rect];
    _danmakuView.duration = 6.5;
    _danmakuView.centerDuration = 2.5;
    _danmakuView.lineHeight = 17;
    _danmakuView.maxShowLineCount = 8;
    _danmakuView.maxCenterLineCount = 1;
    _danmakuView.delegate = self;
    [self addSubview:_danmakuView];
}

- (void)setupDanmakuData
{
    NSString *danmakufile = [[NSBundle mainBundle] pathForResource:@"danmakufile" ofType:nil];
    NSArray *danmakusDicts = [NSArray arrayWithContentsOfFile:danmakufile];
    
    NSMutableArray* danmakus = [NSMutableArray array];
    for (NSDictionary* dict in danmakusDicts) {
        CFDanmaku* danmaku = [[CFDanmaku alloc] init];
        NSMutableAttributedString *contentStr = [[NSMutableAttributedString alloc] initWithString:dict[@"m"] attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : kRandomColor}];
        
        NSString* emotionName = [NSString stringWithFormat:@"smile_%zd", arc4random_uniform(90)];
        UIImage* emotion = [UIImage imageNamed:emotionName];
        NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
        attachment.image = emotion;
        attachment.bounds = CGRectMake(0, -font.lineHeight*0.3, font.lineHeight*1.5, font.lineHeight*1.5);
        NSAttributedString* emotionAttr = [NSAttributedString attributedStringWithAttachment:attachment];
        
        [contentStr appendAttributedString:emotionAttr];
        danmaku.contentStr = contentStr;
        
        NSString* attributesStr = dict[@"p"];
        NSArray* attarsArray = [attributesStr componentsSeparatedByString:@","];
        danmaku.timePoint = [[attarsArray firstObject] doubleValue] / 1000;
        danmaku.position = [attarsArray[1] integerValue];
        //        if (danmaku.position != 0) {
        
        [danmakus addObject:danmaku];
        //        }
    }
    
    [_danmakuView prepareDanmakus:danmakus];
}

- (void)onTimeCount
{
    _progressSlider.value+=0.1/120;
    if (_progressSlider.value>120.0) {
        _progressSlider.value=0;
    }
}

- (NSTimeInterval)danmakuViewGetPlayTime:(CFDanmakuView *)danmakuView
{
    if(_progressSlider.value == 1.0) [_danmakuView stop]
        ;
    return _progressSlider.value*120.0;
}

- (BOOL)danmakuViewIsBuffering:(CFDanmakuView *)danmakuView
{
    return NO;
}

- (void)dealloc
{
    [self.currentItem removeObserver:self forKeyPath:@"status" context:nil];
}


@end
