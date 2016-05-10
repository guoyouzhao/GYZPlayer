//
//  VideoPlayView.h
//  ioshuanwu
//
//  Created by gyz on 16/3/8.
//  Copyright © 2016年 幻音. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class CFDanmakuView;
@class FullViewController;
@protocol  VideoPlayViewDelegate <NSObject>

- (void)videoplayViewSwitchOrientation:(BOOL)isFull;

@end
@interface VideoPlayView : UIView



@property (nonatomic, assign) NSInteger index;
@property (nonatomic, readonly) PlayerState state;
/* playItem */
@property (nonatomic, weak) AVPlayerItem *currentItem;
@property (strong, nonatomic)  UISlider *progressSlider;


/* 播放器 */
@property (nonatomic, strong) AVPlayer *player;

/* 弹幕 */

@property (nonatomic, strong) CFDanmakuView * danmakuView;

//@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, copy) NSString *urlString;
@property (strong, nonatomic) UIButton *playOrPauseBtn;

/* 包含在哪一个控制器中 */
@property (nonatomic, weak) UIViewController *contrainerViewController;

/* 全屏控制器 */
@property (nonatomic, strong) FullViewController *fullVc;

/* 代理 */
@property (nonatomic, assign) id<VideoPlayViewDelegate>delegate;
+ (instancetype)videoPlayView;
- (void)showToolView:(BOOL)isShow;
@end