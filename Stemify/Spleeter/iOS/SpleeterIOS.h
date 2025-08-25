//
//  SpleeterIOS.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/25.
//
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SpleeterModel) {
    SpleeterModel2Stems,
    SpleeterModel5Stems,
};

NS_ASSUME_NONNULL_BEGIN
@interface SpleeterIOS : NSObject

@property (nonatomic, readonly, class) SpleeterIOS *sharedInstance;

- (instancetype)init NS_UNAVAILABLE;

- (void)processFileAt:(NSString*)path
           usingModel:(SpleeterModel)model
               saveAt:(NSString*)folder
              onStart:(void(^)(void))startHandler
           onProgress:(void(^)(float))progressHandler
         onCompletion:(void(^)(BOOL success, NSError * _Nullable error))completionHandler;

@end
NS_ASSUME_NONNULL_END
