#import "LCConversationStore.h"
#import "CGConversation.h"
#import "CGAPIHelper.h"
#import "CGMessage.h"

@interface LCConversationStore ()

+ (NSDate *)dateFromString:(NSString *)value;

@end

static NSInteger LCConversationSort(id leftValue, id rightValue, void *context) {
	CGConversation *left = (CGConversation *)leftValue;
	CGConversation *right = (CGConversation *)rightValue;
	return [[LCConversationStore dateFromString:right.lastTimeEdited] compare:[LCConversationStore dateFromString:left.lastTimeEdited]];
}

@implementation LCConversationStore

+ (NSString *)conversationsDirectoryPath {
	NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *directoryPath = [libraryDirectory stringByAppendingPathComponent:@"LegacyChatApp/Conversations"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	return directoryPath;
}

+ (NSString *)pathForConversationIdentifier:(NSString *)identifier {
	return [[self conversationsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", identifier]];
}

+ (NSString *)stringFromDate:(NSDate *)date {
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	return [formatter stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)value {
	if ([value length] == 0) {
		return [NSDate dateWithTimeIntervalSince1970:0];
	}

	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSDate *date = [formatter dateFromString:value];
	return date ?: [NSDate dateWithTimeIntervalSince1970:0];
}

+ (NSString *)nextConversationIdentifier {
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *uuidString = (NSString *)CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [uuidString autorelease];
}

+ (NSString *)currentConversationIdentifier {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"currentConversationIdentifier"];
}

+ (void)setCurrentConversationIdentifier:(NSString *)identifier {
	if ([identifier length] > 0) {
		[[NSUserDefaults standardUserDefaults] setObject:identifier forKey:@"currentConversationIdentifier"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentConversationIdentifier"];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)messageShouldBePersisted:(CGMessage *)message {
	if (![message isKindOfClass:[CGMessage class]]) {
		return NO;
	}
	if (![message.role isEqualToString:@"user"] &&
		![message.role isEqualToString:@"assistant"] &&
		![message.role isEqualToString:@"system"] &&
		![message.role isEqualToString:@"local"]) {
		return NO;
	}
	return ([message.content length] > 0 || message.imageAttachment != nil);
}

+ (BOOL)hasMeaningfulMessages:(NSArray *)messages {
	for (CGMessage *message in messages) {
		if ([message.role isEqualToString:@"user"] || [message.role isEqualToString:@"assistant"]) {
			return YES;
		}
	}
	return NO;
}

+ (NSString *)derivedTitleForMessages:(NSArray *)messages fallback:(NSString *)fallback {
	for (CGMessage *message in messages) {
		if ([message.role isEqualToString:@"user"] && [message.content length] > 0) {
			NSString *title = [message.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([title length] > 28) {
				title = [[title substringToIndex:28] stringByAppendingString:@"…"];
			}
			return title;
		}
		if ([message.role isEqualToString:@"user"] && message.imageAttachment != nil) {
			return @"Photo";
		}
	}
	return fallback;
}

+ (NSDictionary *)dictionaryForMessage:(CGMessage *)message {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		(message.author ?: @""), @"name",
		(message.role ?: @"assistant"), @"role",
		[NSNumber numberWithInt:message.type], @"type",
		(message.content ?: @""), @"message",
		nil];
	if ([message.hiddenReasoningContent length] > 0) {
		[dictionary setObject:message.hiddenReasoningContent forKey:@"hiddenReasoningContent"];
	}
	if (message.imageAttachment != nil) {
		NSString *base64Image = [CGAPIHelper base64StringForImage:message.imageAttachment];
		if ([base64Image length] > 0) {
			[dictionary setObject:base64Image forKey:@"imageBase64"];
		}
	}
	return dictionary;
}

+ (CGMessage *)messageFromDictionary:(NSDictionary *)dictionary {
	CGMessage *message = [[[CGMessage alloc] init] autorelease];
	message.author = [dictionary objectForKey:@"name"];
	message.role = [dictionary objectForKey:@"role"];
	message.type = [[dictionary objectForKey:@"type"] intValue];
	message.content = [dictionary objectForKey:@"message"];
	message.hiddenReasoningContent = [dictionary objectForKey:@"hiddenReasoningContent"];
	NSString *base64Image = [dictionary objectForKey:@"imageBase64"];
	if ([base64Image length] > 0) {
		NSData *imageData = [[[NSData alloc] initWithBase64Encoding:base64Image] autorelease];
		if ([imageData length] > 0) {
			message.imageAttachment = [UIImage imageWithData:imageData];
		}
	}
	message.indestructible = YES;
	message.avatar = [UIImage imageNamed:(message.type == 1 ? @"Images/defaultUserAvatar.png" : @"Images/defaultAssistantAvatar.png")];

	CGFloat contentWidth = [UIScreen mainScreen].bounds.size.width - 78.0f;
	message.contentHeight = (int)[CGAPIHelper heightForMessage:message width:contentWidth font:[UIFont systemFontOfSize:15.0f]];
	return message;
}

+ (void)saveMessages:(NSArray *)messages conversationID:(NSString *)conversationID title:(NSString *)title {
	if ([conversationID length] == 0) {
		return;
	}

	if (![self hasMeaningfulMessages:messages]) {
		[self deleteConversationWithIdentifier:conversationID];
		return;
	}

	NSMutableArray *serializedMessages = [NSMutableArray array];
	for (CGMessage *message in messages) {
		if (![self messageShouldBePersisted:message]) {
			continue;
		}
		[serializedMessages addObject:[self dictionaryForMessage:message]];
	}

	NSString *nowString = [self stringFromDate:[NSDate date]];
	NSString *filePath = [self pathForConversationIdentifier:conversationID];
	NSDictionary *existingConversation = [NSDictionary dictionaryWithContentsOfFile:filePath];
	NSString *createdAt = [existingConversation objectForKey:@"createdAt"];
	if ([createdAt length] == 0) {
		createdAt = nowString;
	}

	NSString *resolvedTitle = [self derivedTitleForMessages:messages fallback:title];
	NSDictionary *conversationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		conversationID, @"conversationID",
		(resolvedTitle ?: @"New Chat"), @"title",
		createdAt, @"createdAt",
		nowString, @"updatedAt",
		serializedMessages, @"messages",
		nil];

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:conversationDictionary options:NSJSONWritingPrettyPrinted error:nil];
	[jsonData writeToFile:filePath atomically:YES];
	[self setCurrentConversationIdentifier:conversationID];
}

+ (CGConversation *)loadConversationWithIdentifier:(NSString *)identifier {
	if ([identifier length] == 0) {
		return nil;
	}

	NSString *filePath = [self pathForConversationIdentifier:identifier];
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	if (data == nil) {
		return nil;
	}

	NSDictionary *conversationDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	if (![conversationDictionary isKindOfClass:[NSDictionary class]]) {
		return nil;
	}

	CGConversation *conversation = [[[CGConversation alloc] init] autorelease];
	conversation.uuid = [conversationDictionary objectForKey:@"conversationID"];
	conversation.title = [conversationDictionary objectForKey:@"title"];
	conversation.creationDate = [conversationDictionary objectForKey:@"createdAt"];
	conversation.lastTimeEdited = [conversationDictionary objectForKey:@"updatedAt"];
	conversation.messages = [NSMutableArray array];

	NSArray *messages = [conversationDictionary objectForKey:@"messages"];
	for (NSDictionary *messageDictionary in messages) {
		CGMessage *message = [self messageFromDictionary:messageDictionary];
		if (message != nil) {
			[conversation.messages addObject:message];
		}
	}
	conversation.messageCount = (int)[conversation.messages count];
	return conversation;
}

+ (NSArray *)loadConversations {
	NSMutableArray *conversations = [NSMutableArray array];
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self conversationsDirectoryPath] error:nil];
	for (NSString *fileName in files) {
		if (![fileName hasSuffix:@".json"]) {
			continue;
		}

		NSString *identifier = [fileName stringByDeletingPathExtension];
		CGConversation *conversation = [self loadConversationWithIdentifier:identifier];
		if (conversation != nil) {
			[conversations addObject:conversation];
		}
	}

	[conversations sortUsingFunction:LCConversationSort context:NULL];

	return conversations;
}

+ (BOOL)deleteConversationWithIdentifier:(NSString *)identifier {
	if ([identifier length] == 0) {
		return NO;
	}

	NSString *filePath = [self pathForConversationIdentifier:identifier];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
	}

	if ([[identifier description] isEqualToString:[self currentConversationIdentifier]]) {
		[self setCurrentConversationIdentifier:nil];
	}
	return YES;
}

@end
