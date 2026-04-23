#import "CGAPICommunicator.h"
#import "CGAPIHelper.h"
#import "CGMessage.h"
#import "NSURLConnection+FoundationCompletions.h"
#import <UIKit/UIKit.h>
#include "curl.h"
#include "easy.h"

NSString * const LCAPIResponseNotification = @"LCAPIResponseNotification";
NSString * const LCAPIMessageDidUpdateNotification = @"LCAPIMessageDidUpdateNotification";
NSString * const LCAPIStatusDidChangeNotification = @"LCAPIStatusDidChangeNotification";

@interface LCStreamingChatState : NSObject

@property (nonatomic, retain) NSMutableData *bufferedData;
@property (nonatomic, retain) NSMutableData *completeResponseData;
@property (nonatomic, retain) NSMutableString *reasoningText;
@property (nonatomic, retain) NSMutableString *visibleText;
@property (nonatomic, retain) CGMessage *message;
@property (nonatomic, assign) BOOL appendedInitialMessage;
@property (nonatomic, assign) BOOL sawSSEData;
@property (nonatomic, assign) BOOL showingVisibleText;

- (void)appendBytes:(const void *)bytes length:(size_t)length;
- (void)finishParsing;

@end

@implementation LCStreamingChatState

@synthesize bufferedData = _bufferedData;
@synthesize completeResponseData = _completeResponseData;
@synthesize reasoningText = _reasoningText;
@synthesize visibleText = _visibleText;
@synthesize message = _message;
@synthesize appendedInitialMessage = _appendedInitialMessage;
@synthesize sawSSEData = _sawSSEData;
@synthesize showingVisibleText = _showingVisibleText;

- (id)init {
	self = [super init];
	if (self) {
		self.bufferedData = [NSMutableData data];
		self.completeResponseData = [NSMutableData data];
		self.reasoningText = [NSMutableString string];
		self.visibleText = [NSMutableString string];
	}
	return self;
}

- (void)postUpdate {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIMessageDidUpdateNotification object:self.message];
	});
}

- (void)ensureInitialMessageIsPosted {
	if (self.appendedInitialMessage) {
		return;
	}
	self.appendedInitialMessage = YES;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIResponseNotification object:self.message];
	});
}

- (void)applyDisplayText {
	if (self.showingVisibleText) {
		if ([self.visibleText length] > 0) {
			self.message.content = self.visibleText;
		}
	} else if ([self.reasoningText length] > 0) {
		self.message.content = self.reasoningText;
	} else {
		self.message.content = @"Thinking…";
	}
	self.message.hiddenReasoningContent = ([self.reasoningText length] > 0 ? self.reasoningText : nil);
}

- (void)consumePayloadLine:(NSString *)line {
	if ([line hasPrefix:@"data:"] == NO) {
		return;
	}

	NSString *payload = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([payload length] == 0) {
		return;
	}

	self.sawSSEData = YES;
	if ([payload isEqualToString:@"[DONE]"]) {
		return;
	}

	NSData *jsonData = [payload dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
	if (![dictionary isKindOfClass:[NSDictionary class]]) {
		return;
	}

	NSArray *choices = [dictionary objectForKey:@"choices"];
	if (![choices isKindOfClass:[NSArray class]] || [choices count] == 0) {
		return;
	}

	NSDictionary *choice = [choices objectAtIndex:0];
	NSDictionary *delta = [choice objectForKey:@"delta"];
	if (![delta isKindOfClass:[NSDictionary class]]) {
		return;
	}

	NSString *reasoningDelta = nil;
	NSArray *reasoningKeys = [NSArray arrayWithObjects:@"reasoning_content", @"reasoning", @"thinking", @"think", nil];
	for (NSString *key in reasoningKeys) {
		NSString *value = [delta objectForKey:key];
		if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
			reasoningDelta = value;
			break;
		}
	}

	NSString *contentDelta = [delta objectForKey:@"content"];
	if (![contentDelta isKindOfClass:[NSString class]]) {
		contentDelta = nil;
	}

	id contentArray = [delta objectForKey:@"content"];
	if ([contentArray isKindOfClass:[NSArray class]]) {
		for (NSDictionary *contentItem in (NSArray *)contentArray) {
			if (![contentItem isKindOfClass:[NSDictionary class]]) {
				continue;
			}
			NSString *itemType = [contentItem objectForKey:@"type"];
			NSString *text = [contentItem objectForKey:@"text"];
			if (![text isKindOfClass:[NSString class]] || [text length] == 0) {
				continue;
			}
			if ([itemType isEqualToString:@"reasoning"] || [itemType isEqualToString:@"thinking"]) {
				reasoningDelta = (reasoningDelta ?: text);
			} else if ([itemType isEqualToString:@"text"]) {
				contentDelta = (contentDelta ?: text);
			}
		}
	}

	if ([reasoningDelta length] > 0) {
		[self.reasoningText appendString:reasoningDelta];
	}
	if ([contentDelta length] > 0) {
		self.showingVisibleText = YES;
		[self.visibleText appendString:contentDelta];
	}

	if ([reasoningDelta length] == 0 && [contentDelta length] == 0) {
		return;
	}

	[self ensureInitialMessageIsPosted];
	[self applyDisplayText];
	[self postUpdate];
}

- (void)appendBytes:(const void *)bytes length:(size_t)length {
	if (length == 0) {
		return;
	}

	NSData *chunkData = [NSData dataWithBytes:bytes length:length];
	[self.completeResponseData appendData:chunkData];
	[self.bufferedData appendData:chunkData];

	while (YES) {
		const void *bufferBytes = [self.bufferedData bytes];
		NSUInteger bufferLength = [self.bufferedData length];
		NSUInteger lineBreakIndex = NSNotFound;
		for (NSUInteger index = 0; index < bufferLength; index++) {
			if (((const char *)bufferBytes)[index] == '\n') {
				lineBreakIndex = index;
				break;
			}
		}
		if (lineBreakIndex == NSNotFound) {
			break;
		}

		NSData *lineData = [self.bufferedData subdataWithRange:NSMakeRange(0, lineBreakIndex)];
		NSString *line = [[[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding] autorelease];
		if ([line hasSuffix:@"\r"]) {
			line = [line substringToIndex:[line length] - 1];
		}
		[self consumePayloadLine:(line ?: @"")];

		NSRange remainingRange = NSMakeRange(lineBreakIndex + 1, bufferLength - lineBreakIndex - 1);
		NSData *remainingData = [self.bufferedData subdataWithRange:remainingRange];
		[self.bufferedData setData:remainingData];
	}
}

- (void)finishParsing {
	if ([self.bufferedData length] > 0) {
		NSString *line = [[[NSString alloc] initWithData:self.bufferedData encoding:NSUTF8StringEncoding] autorelease];
		if ([line length] > 0) {
			[self consumePayloadLine:line];
		}
	}
}

- (void)dealloc {
	[_bufferedData release];
	[_completeResponseData release];
	[_reasoningText release];
	[_visibleText release];
	[_message release];
	[super dealloc];
}

@end

static size_t LCStreamingWriteCallback(void *ptr, size_t size, size_t nmemb, void *userdata) {
	size_t realSize = size * nmemb;
	LCStreamingChatState *state = (LCStreamingChatState *)userdata;
	[state appendBytes:ptr length:realSize];
	return realSize;
}

@implementation CGAPICommunicator

+ (void)postStatus:(BOOL)isSending {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIStatusDidChangeNotification object:[NSNumber numberWithBool:isSending]];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = isSending;
	});
}

+ (NSString *)textContentFromChoiceMessage:(NSDictionary *)messageDictionary {
	id content = [messageDictionary objectForKey:@"content"];
	if ([content isKindOfClass:[NSString class]]) {
		return content;
	}

	if (![content isKindOfClass:[NSArray class]]) {
		return nil;
	}

	NSMutableArray *textFragments = [NSMutableArray array];
	for (id item in (NSArray *)content) {
		if (![item isKindOfClass:[NSDictionary class]]) {
			continue;
		}

		NSString *text = [item objectForKey:@"text"];
		if ([text isKindOfClass:[NSString class]] && [text length] > 0) {
			[textFragments addObject:text];
		}
	}

	if ([textFragments count] == 0) {
		return nil;
	}
	return [textFragments componentsJoinedByString:@"\n"];
}

+ (NSString *)textContentFromStreamResponseDictionary:(NSDictionary *)parsedResponse {
	NSArray *choices = [parsedResponse objectForKey:@"choices"];
	if (![choices isKindOfClass:[NSArray class]] || [choices count] == 0) {
		return nil;
	}

	NSDictionary *firstChoice = [choices objectAtIndex:0];
	NSDictionary *messageDictionary = [firstChoice objectForKey:@"message"];
	if ([messageDictionary isKindOfClass:[NSDictionary class]]) {
		NSString *messageText = [self textContentFromChoiceMessage:messageDictionary];
		if ([messageText length] > 0) {
			return messageText;
		}
	}

	NSString *fallbackText = [firstChoice objectForKey:@"text"];
	return ([fallbackText isKindOfClass:[NSString class]] ? fallbackText : nil);
}

+ (NSString *)reasoningContentFromChoiceMessage:(NSDictionary *)messageDictionary {
	NSArray *reasoningKeys = [NSArray arrayWithObjects:@"reasoning_content", @"reasoning", @"thinking", @"think", nil];
	for (NSString *key in reasoningKeys) {
		NSString *reasoningText = [messageDictionary objectForKey:key];
		if ([reasoningText isKindOfClass:[NSString class]] && [reasoningText length] > 0) {
			return reasoningText;
		}
	}

	id content = [messageDictionary objectForKey:@"content"];
	if (![content isKindOfClass:[NSArray class]]) {
		return nil;
	}

	NSMutableArray *reasoningFragments = [NSMutableArray array];
	for (id item in (NSArray *)content) {
		if (![item isKindOfClass:[NSDictionary class]]) {
			continue;
		}
		NSString *itemType = [item objectForKey:@"type"];
		if ([itemType isEqualToString:@"reasoning"] || [itemType isEqualToString:@"thinking"]) {
			NSString *text = [item objectForKey:@"text"];
			if ([text isKindOfClass:[NSString class]] && [text length] > 0) {
				[reasoningFragments addObject:text];
			}
		}
	}

	return ([reasoningFragments count] > 0 ? [reasoningFragments componentsJoinedByString:@"\n"] : nil);
}

+ (NSDictionary *)payloadDictionaryForMessages:(NSArray *)messages {
	NSMutableArray *serializedMessages = [NSMutableArray array];
	NSString *systemPrompt = [CGAPIHelper configuredSystemPrompt];
	if ([systemPrompt length] > 0) {
		[serializedMessages addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			@"system", @"role",
			systemPrompt, @"content",
			nil]];
	}

	for (CGMessage *message in messages) {
		if (![message isKindOfClass:[CGMessage class]]) {
			continue;
		}

		NSString *role = message.role;
		if (![role isEqualToString:@"user"] && ![role isEqualToString:@"assistant"] && ![role isEqualToString:@"system"]) {
			continue;
		}

		NSString *content = [message.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([content length] == 0 && message.imageAttachment == nil) {
			continue;
		}

		NSMutableDictionary *serializedMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys:role, @"role", nil];
		if (message.imageAttachment != nil) {
			NSMutableArray *contentItems = [NSMutableArray array];
			if ([content length] > 0) {
				[contentItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					@"text", @"type",
					content, @"text",
					nil]];
			}

			NSString *base64Image = [CGAPIHelper base64StringForImage:message.imageAttachment];
			if ([base64Image length] > 0) {
				[contentItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					@"image_url", @"type",
					[NSDictionary dictionaryWithObjectsAndKeys:
						[NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64Image], @"url",
						nil], @"image_url",
					nil]];
			}

			if ([contentItems count] == 0) {
				continue;
			}
			[serializedMessage setObject:contentItems forKey:@"content"];
		} else {
			[serializedMessage setObject:content forKey:@"content"];
		}

		[serializedMessages addObject:serializedMessage];
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:
		[CGAPIHelper configuredChatModel], @"model",
		serializedMessages, @"messages",
		nil];
}

+ (void)postUpdatedMessage:(CGMessage *)message {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIMessageDidUpdateNotification object:message];
	});
}

+ (void)postMessageText:(NSString *)text assistantRole:(NSString *)role {
	CGMessage *message = [role isEqualToString:@"assistant"] ? [CGAPIHelper assistantMessageWithText:text] : [CGAPIHelper localMessageWithText:text];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIResponseNotification object:message];
	});
}

+ (void)createChatCompletionWithMessages:(NSArray *)messages {
	[self postStatus:YES];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *apiKey = [CGAPIHelper currentAPIKey];
		if ([apiKey length] == 0) {
			[self postMessageText:@"API key is missing. Edit ProviderConfig.plist before packaging, or write apiKey into the app preferences plist on device." assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSDictionary *payload = [self payloadDictionaryForMessages:messages];
		if ([[payload objectForKey:@"messages"] count] == 0) {
			[self postMessageText:@"There is nothing to send yet. Please enter a message first." assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSError *jsonError = nil;
		NSMutableDictionary *streamingPayload = [NSMutableDictionary dictionaryWithDictionary:payload];
		[streamingPayload setObject:[NSNumber numberWithBool:YES] forKey:@"stream"];
		NSData *streamBodyData = [NSJSONSerialization dataWithJSONObject:streamingPayload options:0 error:&jsonError];
		if (jsonError == nil && streamBodyData != nil) {
			NSMutableURLRequest *streamRequest = [[[NSMutableURLRequest alloc] initWithURL:[CGAPIHelper configuredChatCompletionURL]] autorelease];
			[streamRequest setHTTPMethod:@"POST"];
			[streamRequest setHTTPBody:streamBodyData];
			[CGAPIHelper applyAuthorizationHeadersToRequest:streamRequest withAPIKey:apiKey];

			struct curl_slist *headerList = NULL;
			CURL *curlHandle = curl_easy_init();
			if (curlHandle != NULL) {
				LCStreamingChatState *streamState = [[[LCStreamingChatState alloc] init] autorelease];
				streamState.message = [[CGAPIHelper assistantMessageWithText:@""] retain];

				curl_easy_setopt(curlHandle, CURLOPT_URL, [[[streamRequest URL] absoluteString] UTF8String]);
				curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1L);
				curl_easy_setopt(curlHandle, CURLOPT_SSL_VERIFYPEER, 0L);
				curl_easy_setopt(curlHandle, CURLOPT_NOSIGNAL, 1L);
				curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, [streamBodyData bytes]);
				curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDSIZE, [streamBodyData length]);
				curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, LCStreamingWriteCallback);
				curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, streamState);

				NSDictionary *headers = [streamRequest allHTTPHeaderFields];
				for (NSString *headerKey in [headers allKeys]) {
					NSString *headerValue = [headers objectForKey:headerKey];
					headerList = curl_slist_append(headerList, [[NSString stringWithFormat:@"%@: %@", headerKey, headerValue] UTF8String]);
				}
				if (headerList != NULL) {
					curl_easy_setopt(curlHandle, CURLOPT_HTTPHEADER, headerList);
				}

				int curlResult = curl_easy_perform(curlHandle);
				[streamState finishParsing];

				if (headerList != NULL) {
					curl_slist_free_all(headerList);
				}
				curl_easy_cleanup(curlHandle);

				if (curlResult == 0 && streamState.sawSSEData) {
					if ([streamState.visibleText length] == 0 && [streamState.reasoningText length] > 0) {
						streamState.message.content = streamState.reasoningText;
					} else if ([streamState.visibleText length] > 0) {
						streamState.message.content = streamState.visibleText;
					}
					if (streamState.appendedInitialMessage) {
						streamState.message.hiddenReasoningContent = ([streamState.reasoningText length] > 0 ? streamState.reasoningText : nil);
						[self postUpdatedMessage:streamState.message];
					}
					[self postStatus:NO];
					return;
				}

				if ([streamState.completeResponseData length] > 0 && !streamState.sawSSEData) {
					NSDictionary *streamResponse = [NSJSONSerialization JSONObjectWithData:streamState.completeResponseData options:0 error:nil];
					NSString *streamResponseText = nil;
					if ([streamResponse isKindOfClass:[NSDictionary class]]) {
						streamResponseText = [self textContentFromStreamResponseDictionary:streamResponse];
					}
					if ([streamResponseText length] > 0) {
						NSString *streamReasoningText = nil;
						NSArray *choices = [streamResponse objectForKey:@"choices"];
						if ([choices isKindOfClass:[NSArray class]] && [choices count] > 0) {
							NSDictionary *firstChoice = [choices objectAtIndex:0];
							NSDictionary *messageDictionary = [firstChoice objectForKey:@"message"];
							if ([messageDictionary isKindOfClass:[NSDictionary class]]) {
								streamReasoningText = [self reasoningContentFromChoiceMessage:messageDictionary];
							}
						}
						CGMessage *assistantMessage = [CGAPIHelper assistantMessageWithText:streamResponseText];
						assistantMessage.hiddenReasoningContent = streamReasoningText;
						dispatch_async(dispatch_get_main_queue(), ^{
							[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIResponseNotification object:assistantMessage];
						});
						[self postStatus:NO];
						return;
					}
				}
			}
		}

		NSData *bodyData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];
		if (jsonError != nil || bodyData == nil) {
			[self postMessageText:@"The request body could not be encoded. Please try a shorter message first." assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[CGAPIHelper configuredChatCompletionURL]] autorelease];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:bodyData];
		[CGAPIHelper applyAuthorizationHeadersToRequest:request withAPIKey:apiKey];

		NSURLResponse *response = nil;
		NSError *requestError = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
		if (responseData == nil || requestError != nil) {
			NSString *errorText = [CGAPIHelper extractErrorMessageFromResponseData:responseData fallback:@"The configured provider could not be reached. Please verify your base URL, API key, and network connection."];
			[self postMessageText:errorText assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
		if (jsonError != nil || ![parsedResponse isKindOfClass:[NSDictionary class]]) {
			[self postMessageText:@"The provider returned a response that this build could not parse yet." assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSDictionary *errorDictionary = [parsedResponse objectForKey:@"error"];
		if ([errorDictionary isKindOfClass:[NSDictionary class]]) {
			NSString *errorText = [CGAPIHelper extractErrorMessageFromResponseData:responseData fallback:@"The provider returned an unknown error."];
			[self postMessageText:errorText assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSArray *choices = [parsedResponse objectForKey:@"choices"];
		if (![choices isKindOfClass:[NSArray class]] || [choices count] == 0) {
			[self postMessageText:@"The provider responded without any choices." assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		NSDictionary *firstChoice = [choices objectAtIndex:0];
		NSDictionary *messageDictionary = [firstChoice objectForKey:@"message"];
		NSString *responseText = nil;
		NSString *reasoningText = nil;
		if ([messageDictionary isKindOfClass:[NSDictionary class]]) {
			responseText = [self textContentFromChoiceMessage:messageDictionary];
			reasoningText = [self reasoningContentFromChoiceMessage:messageDictionary];
		}

		if ([responseText length] == 0) {
			responseText = [firstChoice objectForKey:@"text"];
		}

		if (![responseText isKindOfClass:[NSString class]] || [responseText length] == 0) {
			[self postMessageText:@"The provider returned an empty reply." assistantRole:@"local"];
			[self postStatus:NO];
			return;
		}

		CGMessage *assistantMessage = [CGAPIHelper assistantMessageWithText:responseText];
		assistantMessage.hiddenReasoningContent = reasoningText;
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:LCAPIResponseNotification object:assistantMessage];
		});
		[self postStatus:NO];
	});
}

@end
