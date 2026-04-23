#import <Foundation/Foundation.h>

extern NSString * const LCAPIResponseNotification;
extern NSString * const LCAPIMessageDidUpdateNotification;
extern NSString * const LCAPIStatusDidChangeNotification;

@interface CGAPICommunicator : NSObject

+ (void)createChatCompletionWithMessages:(NSArray *)messages;

@end
