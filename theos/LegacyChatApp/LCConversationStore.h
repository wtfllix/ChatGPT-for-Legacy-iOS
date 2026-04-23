#import <Foundation/Foundation.h>

@class CGConversation;

@interface LCConversationStore : NSObject

+ (NSArray *)loadConversations;
+ (CGConversation *)loadConversationWithIdentifier:(NSString *)identifier;
+ (void)saveMessages:(NSArray *)messages conversationID:(NSString *)conversationID title:(NSString *)title;
+ (BOOL)deleteConversationWithIdentifier:(NSString *)identifier;
+ (NSString *)nextConversationIdentifier;
+ (NSString *)currentConversationIdentifier;
+ (void)setCurrentConversationIdentifier:(NSString *)identifier;
+ (NSString *)derivedTitleForMessages:(NSArray *)messages fallback:(NSString *)fallback;

@end
