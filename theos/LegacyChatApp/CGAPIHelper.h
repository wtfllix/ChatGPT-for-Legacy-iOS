#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CGMessage;

@interface CGAPIHelper : NSObject

+ (void)registerProviderDefaults;
+ (NSString *)providerDisplayName;
+ (NSString *)currentAPIKey;
+ (NSString *)configuredBaseURL;
+ (NSString *)configuredChatPath;
+ (NSString *)configuredChatModel;
+ (NSString *)defaultSystemPrompt;
+ (NSString *)configuredSystemPrompt;
+ (void)saveSystemPrompt:(NSString *)prompt;
+ (NSString *)storedValueForKey:(NSString *)key fallback:(NSString *)fallback;
+ (NSArray *)providerProfiles;
+ (NSDictionary *)activeProviderProfile;
+ (void)saveActiveProviderProfileWithValues:(NSDictionary *)values;
+ (void)createProviderProfileWithValues:(NSDictionary *)values;
+ (void)activateProviderProfileWithIdentifier:(NSString *)identifier;
+ (NSString *)activeProviderProfileIdentifier;
+ (void)updateProviderProfileWithIdentifier:(NSString *)identifier values:(NSDictionary *)values;
+ (void)deleteProviderProfileWithIdentifier:(NSString *)identifier;
+ (NSURL *)configuredChatCompletionURL;
+ (void)applyAuthorizationHeadersToRequest:(NSMutableURLRequest *)request withAPIKey:(NSString *)key;
+ (CGMessage *)assistantMessageWithText:(NSString *)text;
+ (CGMessage *)localMessageWithText:(NSString *)text;
+ (NSString *)extractErrorMessageFromResponseData:(NSData *)data fallback:(NSString *)fallback;
+ (NSString *)displayTextForMessage:(CGMessage *)message;
+ (NSAttributedString *)attributedDisplayStringForMessage:(CGMessage *)message font:(UIFont *)font textColor:(UIColor *)textColor;
+ (CGFloat)heightForMessage:(CGMessage *)message width:(CGFloat)width font:(UIFont *)font;
+ (NSString *)base64StringForImage:(UIImage *)image;

@end
