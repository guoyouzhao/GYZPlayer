//
//  LoaderURLConnection.h
//  VideoLive
//
//  Created by gyz on 16/2/24.
//  Copyright © 2016年 gl. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@class VideoRequestTask;

@protocol LoaderURLConnectionDelegate <NSObject>

- (void)didFinishLoadingWithTask:(VideoRequestTask *)task;
- (void)didFailLoadingWithTask:(VideoRequestTask *)task WithError:(NSInteger )errorCode;

@end

@interface LoaderURLConnection : NSURLConnection <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) VideoRequestTask *task;
@property (nonatomic, weak  ) id<LoaderURLConnectionDelegate> delegate;
- (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end
