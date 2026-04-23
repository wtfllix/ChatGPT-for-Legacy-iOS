#import "CGConversation.h"

@implementation CGConversation

@synthesize uuid = _uuid;
@synthesize creationDate = _creationDate;
@synthesize lastTimeEdited = _lastTimeEdited;
@synthesize title = _title;
@synthesize messageCount = _messageCount;
@synthesize messages = _messages;

- (void)dealloc {
	[_uuid release];
	[_creationDate release];
	[_lastTimeEdited release];
	[_title release];
	[_messages release];
	[super dealloc];
}

@end
