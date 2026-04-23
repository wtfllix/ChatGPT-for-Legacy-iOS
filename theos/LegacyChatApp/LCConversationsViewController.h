#import <UIKit/UIKit.h>

@class CGConversation;
@class LCConversationsViewController;

@protocol LCConversationsViewControllerDelegate <NSObject>

- (void)conversationsViewControllerDidRequestNewChat:(LCConversationsViewController *)controller;
- (void)conversationsViewController:(LCConversationsViewController *)controller didSelectConversation:(CGConversation *)conversation;

@end

@interface LCConversationsViewController : UITableViewController

@property (nonatomic, assign) id<LCConversationsViewControllerDelegate> delegate;

@end
