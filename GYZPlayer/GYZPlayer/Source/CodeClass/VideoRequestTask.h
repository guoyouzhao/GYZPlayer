//
//  VideoRequestTask.h
//  VideoLive
//
//  Created by gyz on 16/2/24.
//  Copyright © 2016年 gl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VideoRequestTask;
@protocol VideoRequestTaskDelegate <NSObject>

- (void)task:(VideoRequestTask *)task didReceiveVideoLength:(NSUInteger)ideoLength mimeType:(NSString *)mimeType;
- (void)didReceiveVideoDataWithTask:(VideoRequestTask *)task;
- (void)didFinishLoadingWithTask:(VideoRequestTask *)task;
- (void)didFailLoadingWithTask:(VideoRequestTask *)task WithError:(NSInteger )errorCode;

@end

@interface VideoRequestTask : NSObject
@property (nonatomic, strong, readonly) NSURL                      *url;
@property (nonatomic, readonly        ) NSUInteger                 offset;

@property (nonatomic, readonly        ) NSUInteger                 videoLength;
@property (nonatomic, readonly        ) NSUInteger                 downLoadingOffset;
@property (nonatomic, strong, readonly) NSString                   * mimeType;
@property (nonatomic, assign)           BOOL                       isFinishLoad;

@property (nonatomic, weak            ) id <VideoRequestTaskDelegate> delegate;


- (void)setUrl:(NSURL *)url offset:(NSUInteger)offset;

- (void)cancel;

- (void)continueLoading;

- (void)clearData;

@end
