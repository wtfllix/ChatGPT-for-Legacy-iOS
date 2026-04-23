#import <UIKit/UIKit.h>
#import "CGMessage.h"

@interface CGChatTableCell : UITableViewCell

@property (nonatomic, retain) UIImageView *avatar;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UIView *thinkingBackgroundView;
@property (nonatomic, retain) UILabel *contentLabel;
@property (nonatomic, retain) UIImageView *attachmentPreview;
@property (nonatomic, retain) UIImageView *separator;
@property (nonatomic, retain) UIImageView *iOS7Separator;

- (void)configureWithAuthor:(NSString *)author
                    message:(CGMessage *)message
                     avatar:(UIImage *)avatarImage;

+ (CGFloat)heightForMessage:(CGMessage *)message width:(CGFloat)width;

@end
