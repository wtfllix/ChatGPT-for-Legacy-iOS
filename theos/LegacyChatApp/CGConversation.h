#import <Foundation/Foundation.h>

@interface CGConversation : NSObject

@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *creationDate;
@property (nonatomic, retain) NSString *lastTimeEdited;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, assign) int messageCount;
@property (nonatomic, retain) NSMutableArray *messages;

@end
