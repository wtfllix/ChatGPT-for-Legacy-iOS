#import "CGMessage.h"

@implementation CGMessage

@synthesize author = _author;
@synthesize username = _username;
@synthesize avatar = _avatar;
@synthesize content = _content;
@synthesize hiddenReasoningContent = _hiddenReasoningContent;
@synthesize imageHash = _imageHash;
@synthesize imageAttachment = _imageAttachment;
@synthesize role = _role;
@synthesize type = _type;
@synthesize indestructible = _indestructible;
@synthesize contentHeight = _contentHeight;
@synthesize authorNameWidth = _authorNameWidth;
@synthesize indexForImageRow = _indexForImageRow;

- (void)dealloc {
	[_author release];
	[_username release];
	[_avatar release];
	[_content release];
	[_hiddenReasoningContent release];
	[_imageHash release];
	[_imageAttachment release];
	[_role release];
	[super dealloc];
}

@end
