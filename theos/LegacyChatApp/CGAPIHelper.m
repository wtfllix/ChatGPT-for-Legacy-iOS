#import "CGAPIHelper.h"
#import "CGMessage.h"

static NSString * const LCProviderProfilesKey = @"providerProfiles";
static NSString * const LCActiveProviderProfileIDKey = @"activeProviderProfileID";
static NSString * const LCSystemPromptKey = @"systemPrompt";

@implementation CGAPIHelper

+ (NSString *)defaultSystemPrompt {
	return @"You are a concise, helpful assistant in a legacy iOS chat app. Prefer clear, direct answers. Use simple Markdown only when it improves readability, and avoid complex tables or deeply nested formatting.";
}

+ (NSString *)stringByStrippingThinkBlocks:(NSString *)value extractedReasoning:(NSString **)reasoningOutput {
	if (![value isKindOfClass:[NSString class]] || [value length] == 0) {
		return @"";
	}

	NSMutableString *visibleText = [NSMutableString stringWithString:value];
	NSMutableArray *reasoningParts = [NSMutableArray array];
	NSRegularExpression *thinkRegex = [NSRegularExpression regularExpressionWithPattern:@"<think>([\\s\\S]*?)</think>" options:NSRegularExpressionCaseInsensitive error:nil];
	NSArray *matches = [thinkRegex matchesInString:value options:0 range:NSMakeRange(0, [value length])];
	for (NSInteger index = [matches count] - 1; index >= 0; index--) {
		NSTextCheckingResult *match = [matches objectAtIndex:index];
		if ([match numberOfRanges] > 1) {
			NSString *reasoningText = [value substringWithRange:[match rangeAtIndex:1]];
			if ([reasoningText length] > 0) {
				[reasoningParts insertObject:reasoningText atIndex:0];
			}
		}
		[visibleText replaceCharactersInRange:match.range withString:@""];
	}

	NSString *trimmedVisibleText = [visibleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (reasoningOutput != NULL) {
		*reasoningOutput = ([reasoningParts count] > 0 ? [reasoningParts componentsJoinedByString:@"\n\n"] : nil);
	}
	return trimmedVisibleText;
}

+ (NSString *)stringByNormalizingMarkdown:(NSString *)value {
	if (![value isKindOfClass:[NSString class]] || [value length] == 0) {
		return @"";
	}

	NSMutableString *normalized = [NSMutableString stringWithString:value];
	NSArray *replacements = [NSArray arrayWithObjects:
		[NSArray arrayWithObjects:@"```", @"", nil],
		[NSArray arrayWithObjects:@"**", @"", nil],
		[NSArray arrayWithObjects:@"__", @"", nil],
		[NSArray arrayWithObjects:@"`", @"", nil],
		nil];
	for (NSArray *replacementPair in replacements) {
		[normalized replaceOccurrencesOfString:[replacementPair objectAtIndex:0]
		                            withString:[replacementPair objectAtIndex:1]
		                               options:0
		                                 range:NSMakeRange(0, [normalized length])];
	}

	NSRegularExpression *headerRegex = [NSRegularExpression regularExpressionWithPattern:@"(?m)^#{1,6}\\s*" options:0 error:nil];
	[headerRegex replaceMatchesInString:normalized options:0 range:NSMakeRange(0, [normalized length]) withTemplate:@""];

	NSRegularExpression *listRegex = [NSRegularExpression regularExpressionWithPattern:@"(?m)^(\\s*)[-\\*+]\\s+" options:0 error:nil];
	[listRegex replaceMatchesInString:normalized options:0 range:NSMakeRange(0, [normalized length]) withTemplate:@"$1• "];

	NSRegularExpression *linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[([^\\]]+)\\]\\(([^\\)]+)\\)" options:0 error:nil];
	[linkRegex replaceMatchesInString:normalized options:0 range:NSMakeRange(0, [normalized length]) withTemplate:@"$1"];

	NSRegularExpression *italicRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\*)\\*([^\\*]+)\\*(?!\\*)" options:0 error:nil];
	[italicRegex replaceMatchesInString:normalized options:0 range:NSMakeRange(0, [normalized length]) withTemplate:@"$1"];

	NSRegularExpression *underscoreItalicRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!_)_([^_]+)_(?!_)" options:0 error:nil];
	[underscoreItalicRegex replaceMatchesInString:normalized options:0 range:NSMakeRange(0, [normalized length]) withTemplate:@"$1"];

	return [normalized stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (void)applyMarkdownAttributesToAttributedString:(NSMutableAttributedString *)attributedString {
	NSString *fullText = [attributedString string];
	if ([fullText length] == 0) {
		return;
	}

	NSRegularExpression *strongRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\*\\*|__)(.+?)(\\1)" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
	NSArray *strongMatches = [strongRegex matchesInString:fullText options:0 range:NSMakeRange(0, [fullText length])];
	for (NSInteger index = [strongMatches count] - 1; index >= 0; index--) {
		NSTextCheckingResult *match = [strongMatches objectAtIndex:index];
		NSRange contentRange = [match rangeAtIndex:2];
		NSString *matchedText = [fullText substringWithRange:contentRange];
		NSAttributedString *replacement = [[[NSAttributedString alloc] initWithString:matchedText attributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:15.0f] forKey:NSFontAttributeName]] autorelease];
		[attributedString replaceCharactersInRange:match.range withAttributedString:replacement];
	}

	fullText = [attributedString string];
	NSRegularExpression *inlineCodeRegex = [NSRegularExpression regularExpressionWithPattern:@"`([^`]+)`" options:0 error:nil];
	NSArray *codeMatches = [inlineCodeRegex matchesInString:fullText options:0 range:NSMakeRange(0, [fullText length])];
	for (NSInteger index = [codeMatches count] - 1; index >= 0; index--) {
		NSTextCheckingResult *match = [codeMatches objectAtIndex:index];
		NSRange contentRange = [match rangeAtIndex:1];
		NSString *matchedText = [fullText substringWithRange:contentRange];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIFont fontWithName:@"Courier" size:14.0f], NSFontAttributeName,
			[UIColor colorWithWhite:0.18f alpha:1.0f], NSForegroundColorAttributeName,
			nil];
		NSAttributedString *replacement = [[[NSAttributedString alloc] initWithString:matchedText attributes:attributes] autorelease];
		[attributedString replaceCharactersInRange:match.range withAttributedString:replacement];
	}
}

+ (NSString *)trimmedString:(NSString *)value fallback:(NSString *)fallback {
	if (![value isKindOfClass:[NSString class]]) {
		return fallback;
	}

	NSString *trimmedValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([trimmedValue length] == 0) {
		return fallback;
	}
	return trimmedValue;
}

+ (NSString *)providerIdentifierFromValues:(NSDictionary *)values fallback:(NSString *)fallback {
	NSString *providerName = [self trimmedString:[values objectForKey:@"providerName"] fallback:fallback];
	NSString *baseURL = [self trimmedString:[values objectForKey:@"baseURL"] fallback:@""];
	NSString *identifier = [NSString stringWithFormat:@"%@|%@", providerName, baseURL];
	return identifier;
}

+ (NSDictionary *)profileDictionaryFromValues:(NSDictionary *)values identifier:(NSString *)identifierFallback {
	NSString *providerName = [self trimmedString:[values objectForKey:@"providerName"] fallback:@"AI Assistant"];
	NSString *baseURL = [self trimmedString:[values objectForKey:@"baseURL"] fallback:@"https://api.openai.com"];
	NSString *chatPath = [self trimmedString:[values objectForKey:@"chatPath"] fallback:@"/v1/chat/completions"];
	NSString *chatModel = [self trimmedString:[values objectForKey:@"c-aiModel"] fallback:@"gpt-4o-mini"];
	NSString *apiKey = [self trimmedString:[values objectForKey:@"apiKey"] fallback:@""];
	NSString *identifier = [self providerIdentifierFromValues:values fallback:identifierFallback];

	return [NSDictionary dictionaryWithObjectsAndKeys:
		identifier, @"identifier",
		providerName, @"providerName",
		baseURL, @"baseURL",
		chatPath, @"chatPath",
		chatModel, @"c-aiModel",
		apiKey, @"apiKey",
		nil];
}

+ (void)registerProviderDefaults {
	NSString *configPath = [[NSBundle mainBundle] pathForResource:@"ProviderConfig" ofType:@"plist"];
	if (configPath == nil) {
		return;
	}

	NSDictionary *bundleDefaults = [NSDictionary dictionaryWithContentsOfFile:configPath];
	if (bundleDefaults == nil) {
		return;
	}
	NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithDictionary:bundleDefaults];
	[defaults setObject:[self defaultSystemPrompt] forKey:LCSystemPromptKey];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	NSArray *profiles = [[NSUserDefaults standardUserDefaults] objectForKey:LCProviderProfilesKey];
	if ([profiles count] == 0) {
		NSString *legacyProviderName = [self trimmedString:[[NSUserDefaults standardUserDefaults] objectForKey:@"providerName"] fallback:[defaults objectForKey:@"providerName"]];
		NSString *legacyBaseURL = [self trimmedString:[[NSUserDefaults standardUserDefaults] objectForKey:@"baseURL"] fallback:[defaults objectForKey:@"baseURL"]];
		NSString *legacyChatPath = [self trimmedString:[[NSUserDefaults standardUserDefaults] objectForKey:@"chatPath"] fallback:[defaults objectForKey:@"chatPath"]];
		NSString *legacyModel = [self trimmedString:[[NSUserDefaults standardUserDefaults] objectForKey:@"c-aiModel"] fallback:[defaults objectForKey:@"c-aiModel"]];
		NSString *legacyKey = [self trimmedString:[[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"] fallback:[defaults objectForKey:@"apiKey"]];

		NSDictionary *initialProfile = [self profileDictionaryFromValues:[NSDictionary dictionaryWithObjectsAndKeys:
			(legacyProviderName ?: @"AI Assistant"), @"providerName",
			(legacyBaseURL ?: @"https://api.openai.com"), @"baseURL",
			(legacyChatPath ?: @"/v1/chat/completions"), @"chatPath",
			(legacyModel ?: @"gpt-4o-mini"), @"c-aiModel",
			(legacyKey ?: @""), @"apiKey",
			nil] identifier:@"default-profile"];

		[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObject:initialProfile] forKey:LCProviderProfilesKey];
		[[NSUserDefaults standardUserDefaults] setObject:[initialProfile objectForKey:@"identifier"] forKey:LCActiveProviderProfileIDKey];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)providerDisplayName {
	return [self trimmedString:[[self activeProviderProfile] objectForKey:@"providerName"] fallback:@"AI Assistant"];
}

+ (NSString *)storedValueForKey:(NSString *)key fallback:(NSString *)fallback {
	return [self trimmedString:[[self activeProviderProfile] objectForKey:key] fallback:fallback];
}

+ (NSString *)currentAPIKey {
	NSString *apiKey = [self trimmedString:[[self activeProviderProfile] objectForKey:@"apiKey"] fallback:nil];
	if ([apiKey isEqualToString:@"PASTE_API_KEY_HERE"]) {
		return nil;
	}
	return apiKey;
}

+ (NSString *)configuredBaseURL {
	NSString *baseURL = [self trimmedString:[[self activeProviderProfile] objectForKey:@"baseURL"] fallback:@"https://api.openai.com"];
	while ([baseURL hasSuffix:@"/"]) {
		baseURL = [baseURL substringToIndex:[baseURL length] - 1];
	}
	return baseURL;
}

+ (NSString *)configuredChatPath {
	NSString *chatPath = [self trimmedString:[[self activeProviderProfile] objectForKey:@"chatPath"] fallback:@"/v1/chat/completions"];
	if (![chatPath hasPrefix:@"/"]) {
		chatPath = [@"/" stringByAppendingString:chatPath];
	}
	return chatPath;
}

+ (NSString *)configuredChatModel {
	return [self trimmedString:[[self activeProviderProfile] objectForKey:@"c-aiModel"] fallback:@"gpt-4o-mini"];
}

+ (NSString *)configuredSystemPrompt {
	NSString *prompt = [[NSUserDefaults standardUserDefaults] objectForKey:LCSystemPromptKey];
	return [self trimmedString:prompt fallback:@""];
}

+ (void)saveSystemPrompt:(NSString *)prompt {
	NSString *trimmedPrompt = [self trimmedString:prompt fallback:@""];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([trimmedPrompt length] > 0) {
		[defaults setObject:trimmedPrompt forKey:LCSystemPromptKey];
	} else {
		[defaults setObject:@"" forKey:LCSystemPromptKey];
	}
	[defaults synchronize];
}

+ (NSArray *)providerProfiles {
	NSArray *profiles = [[NSUserDefaults standardUserDefaults] objectForKey:LCProviderProfilesKey];
	if (![profiles isKindOfClass:[NSArray class]]) {
		return [NSArray array];
	}
	return profiles;
}

+ (NSString *)activeProviderProfileIdentifier {
	return [[NSUserDefaults standardUserDefaults] objectForKey:LCActiveProviderProfileIDKey];
}

+ (NSDictionary *)activeProviderProfile {
	NSString *activeIdentifier = [self activeProviderProfileIdentifier];
	NSArray *profiles = [self providerProfiles];
	for (NSDictionary *profile in profiles) {
		if ([[profile objectForKey:@"identifier"] isEqualToString:activeIdentifier]) {
			return profile;
		}
	}
	return ([profiles count] > 0 ? [profiles objectAtIndex:0] : [NSDictionary dictionary]);
}

+ (void)persistProfiles:(NSArray *)profiles activeIdentifier:(NSString *)activeIdentifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:profiles forKey:LCProviderProfilesKey];
	if ([activeIdentifier length] > 0) {
		[defaults setObject:activeIdentifier forKey:LCActiveProviderProfileIDKey];
	}
	[defaults synchronize];
}

+ (void)saveActiveProviderProfileWithValues:(NSDictionary *)values {
	NSString *activeIdentifier = [self activeProviderProfileIdentifier];
	NSMutableArray *profiles = [NSMutableArray arrayWithArray:[self providerProfiles]];
	NSDictionary *updatedProfile = [self profileDictionaryFromValues:values identifier:(activeIdentifier ?: @"default-profile")];
	BOOL updated = NO;
	for (NSUInteger index = 0; index < [profiles count]; index++) {
		NSDictionary *profile = [profiles objectAtIndex:index];
		if ([[profile objectForKey:@"identifier"] isEqualToString:activeIdentifier]) {
			[profiles replaceObjectAtIndex:index withObject:updatedProfile];
			updated = YES;
			break;
		}
	}
	if (!updated) {
		[profiles addObject:updatedProfile];
	}
	[self persistProfiles:profiles activeIdentifier:[updatedProfile objectForKey:@"identifier"]];
}

+ (void)createProviderProfileWithValues:(NSDictionary *)values {
	NSMutableArray *profiles = [NSMutableArray arrayWithArray:[self providerProfiles]];
	NSString *identifier = [NSString stringWithFormat:@"profile-%u", arc4random()];
	NSDictionary *newProfile = [self profileDictionaryFromValues:values identifier:identifier];
	[profiles addObject:newProfile];
	[self persistProfiles:profiles activeIdentifier:[newProfile objectForKey:@"identifier"]];
}

+ (void)activateProviderProfileWithIdentifier:(NSString *)identifier {
	if ([identifier length] == 0) {
		return;
	}
	[self persistProfiles:[self providerProfiles] activeIdentifier:identifier];
}

+ (void)updateProviderProfileWithIdentifier:(NSString *)identifier values:(NSDictionary *)values {
	if ([identifier length] == 0) {
		return;
	}

	NSMutableArray *profiles = [NSMutableArray arrayWithArray:[self providerProfiles]];
	NSDictionary *updatedProfile = [self profileDictionaryFromValues:values identifier:identifier];
	for (NSUInteger index = 0; index < [profiles count]; index++) {
		NSDictionary *profile = [profiles objectAtIndex:index];
		if ([[profile objectForKey:@"identifier"] isEqualToString:identifier]) {
			[profiles replaceObjectAtIndex:index withObject:updatedProfile];
			[self persistProfiles:profiles activeIdentifier:[self activeProviderProfileIdentifier]];
			return;
		}
	}
}

+ (void)deleteProviderProfileWithIdentifier:(NSString *)identifier {
	if ([identifier length] == 0) {
		return;
	}

	NSMutableArray *profiles = [NSMutableArray arrayWithArray:[self providerProfiles]];
	for (NSInteger index = [profiles count] - 1; index >= 0; index--) {
		NSDictionary *profile = [profiles objectAtIndex:index];
		if ([[profile objectForKey:@"identifier"] isEqualToString:identifier]) {
			[profiles removeObjectAtIndex:index];
		}
	}

	NSString *activeIdentifier = [self activeProviderProfileIdentifier];
	if ([profiles count] == 0) {
		NSString *fallbackName = @"AI Assistant";
		NSString *fallbackBaseURL = @"https://api.openai.com";
		NSString *fallbackChatPath = @"/v1/chat/completions";
		NSString *fallbackModel = @"gpt-4o-mini";
		NSDictionary *fallbackProfile = [self profileDictionaryFromValues:[NSDictionary dictionaryWithObjectsAndKeys:
			fallbackName, @"providerName",
			fallbackBaseURL, @"baseURL",
			fallbackChatPath, @"chatPath",
			fallbackModel, @"c-aiModel",
			@"", @"apiKey",
			nil] identifier:@"default-profile"];
		[profiles addObject:fallbackProfile];
		activeIdentifier = [fallbackProfile objectForKey:@"identifier"];
	} else if ([activeIdentifier isEqualToString:identifier]) {
		activeIdentifier = [[profiles objectAtIndex:0] objectForKey:@"identifier"];
	}

	[self persistProfiles:profiles activeIdentifier:activeIdentifier];
}

+ (NSURL *)configuredChatCompletionURL {
	NSString *fullString = [NSString stringWithFormat:@"%@%@", [self configuredBaseURL], [self configuredChatPath]];
	return [NSURL URLWithString:fullString];
}

+ (void)applyAuthorizationHeadersToRequest:(NSMutableURLRequest *)request withAPIKey:(NSString *)key {
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	if ([key length] > 0) {
		[request setValue:[NSString stringWithFormat:@"Bearer %@", key] forHTTPHeaderField:@"Authorization"];
	}
}

+ (CGMessage *)messageWithText:(NSString *)text role:(NSString *)role {
	CGMessage *message = [[[CGMessage alloc] init] autorelease];
	message.author = [self providerDisplayName];
	message.role = role;
	message.type = 2;
	message.content = text;
	message.indestructible = YES;
	message.avatar = [UIImage imageNamed:@"Images/defaultAssistantAvatar.png"];
	return message;
}

+ (NSString *)displayTextForMessage:(CGMessage *)message {
	if (![message isKindOfClass:[CGMessage class]]) {
		return @"";
	}

	NSString *discardedReasoning = nil;
	NSString *visibleText = [self stringByStrippingThinkBlocks:message.content extractedReasoning:&discardedReasoning];
	if ([message.hiddenReasoningContent length] == 0 && [discardedReasoning length] > 0) {
		message.hiddenReasoningContent = discardedReasoning;
	}
	return [self stringByNormalizingMarkdown:visibleText];
}

+ (NSAttributedString *)attributedDisplayStringForMessage:(CGMessage *)message font:(UIFont *)font textColor:(UIColor *)textColor {
	NSString *displayText = [self displayTextForMessage:message];
	NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:displayText attributes:[NSDictionary dictionaryWithObjectsAndKeys:
		(font ?: [UIFont systemFontOfSize:15.0f]), NSFontAttributeName,
		(textColor ?: [UIColor blackColor]), NSForegroundColorAttributeName,
		nil]] autorelease];
	[self applyMarkdownAttributesToAttributedString:attributedString];
	return attributedString;
}

+ (CGFloat)heightForMessage:(CGMessage *)message width:(CGFloat)width font:(UIFont *)font {
	NSString *displayText = [self displayTextForMessage:message];
	CGSize textSize = [displayText sizeWithFont:(font ?: [UIFont systemFontOfSize:15.0f])
	                          constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
	                              lineBreakMode:NSLineBreakByWordWrapping];
	CGFloat height = textSize.height;
	if (message.imageAttachment != nil) {
		height += 72.0f;
	}
	return MAX(72.0f, height + 34.0f);
}

+ (NSString *)base64StringForImage:(UIImage *)image {
	if (image == nil) {
		return nil;
	}

	NSData *jpegData = UIImageJPEGRepresentation(image, 0.75f);
	if ([jpegData length] == 0) {
		return nil;
	}
	return [jpegData base64Encoding];
}

+ (CGMessage *)assistantMessageWithText:(NSString *)text {
	return [self messageWithText:text role:@"assistant"];
}

+ (CGMessage *)localMessageWithText:(NSString *)text {
	return [self messageWithText:text role:@"local"];
}

+ (NSString *)extractErrorMessageFromResponseData:(NSData *)data fallback:(NSString *)fallback {
	if (data == nil || [data length] == 0) {
		return fallback;
	}

	NSError *jsonError = nil;
	id parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
	if (jsonError != nil || ![parsedObject isKindOfClass:[NSDictionary class]]) {
		return fallback;
	}

	NSDictionary *responseDictionary = (NSDictionary *)parsedObject;
	NSDictionary *errorDictionary = [responseDictionary objectForKey:@"error"];
	if ([errorDictionary isKindOfClass:[NSDictionary class]]) {
		NSString *message = [self trimmedString:[errorDictionary objectForKey:@"message"] fallback:nil];
		if ([message length] > 0) {
			return message;
		}
	}

	NSString *message = [self trimmedString:[responseDictionary objectForKey:@"message"] fallback:nil];
	if ([message length] > 0) {
		return message;
	}

	return fallback;
}

@end
