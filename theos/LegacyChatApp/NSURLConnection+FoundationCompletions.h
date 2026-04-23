#import <Foundation/Foundation.h>

@interface NSURLConnection (FoundationCompletions)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)anerror;

@end
