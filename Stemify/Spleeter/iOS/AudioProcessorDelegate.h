//
//  AudioProcessorDelegate.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#import <Foundation/Foundation.h>

// Objective-C协议，保持与原来的接口一致
@protocol AudioProcessorViewDelegate <NSObject>
@optional
// 进度更新回调：progress 范围 0.0 - 1.0
- (void)audioProcessorDidUpdateProgress:(float)progress;
// 开始处理回调
- (void)audioProcessorDidStart;
// 完成处理回调
- (void)audioProcessorDidFinish;
// 错误回调
- (void)audioProcessorDidFailWithError:(NSString *)error;
@end
