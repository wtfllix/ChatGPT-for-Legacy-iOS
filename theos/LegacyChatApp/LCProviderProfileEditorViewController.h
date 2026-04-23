#import <UIKit/UIKit.h>

@interface LCProviderProfileEditorViewController : UITableViewController <UITextFieldDelegate>

- (id)initForNewProfile;
- (id)initWithProfile:(NSDictionary *)profile;

@end
