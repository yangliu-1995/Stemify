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
} NS_SWIFT_NAME(Spleeter.Model);

NS_ASSUME_NONNULL_BEGIN
NS_SWIFT_UI_ACTOR
NS_SWIFT_NAME(Spleeter)
@interface SpleeterIOS : NSObject

@property (nonatomic, readonly, class) SpleeterIOS *sharedInstance NS_SWIFT_NAME(shared);

- (instancetype)init NS_UNAVAILABLE;

- (void)processFileAt:(NSString*)path
           usingModel:(SpleeterModel)model
               saveAt:(NSString*)folder
              onStart:(void(^)(void))startHandler
           onProgress:(void(^)(float))progressHandler
         onCompletion:(void(^)(BOOL success, NSError * _Nullable error))completionHandler;

@end
NS_ASSUME_NONNULL_END
