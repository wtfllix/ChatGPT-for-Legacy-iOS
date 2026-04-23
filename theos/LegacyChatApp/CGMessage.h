#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CGMessage : NSObject

@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) UIImage *avatar;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *hiddenReasoningContent;
@property (nonatomic, retain) NSString *imageHash;
@property (nonatomic, retain) UIImage *imageAttachment;
@property (nonatomic, retain) NSString *role;

@property (nonatomic, assign) int type;
@property (nonatomic, assign) BOOL indestructible;
@property (nonatomic, assign) int contentHeight;
@property (nonatomic, assign) int authorNameWidth;
@property (nonatomic, assign) int indexForImageRow;

@end
