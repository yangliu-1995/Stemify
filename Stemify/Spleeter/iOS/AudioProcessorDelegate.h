//
//  AudioProcessorDelegate.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#import <Foundation/Foundation.h>

@protocol AudioProcessorViewDelegate <NSObject>
@optional
- (void)audioProcessorDidUpdateProgress:(float)progress;
- (void)audioProcessorDidStart;
- (void)audioProcessorDidFinish;
- (void)audioProcessorDidFailWithError:(NSString *)error;
@end
