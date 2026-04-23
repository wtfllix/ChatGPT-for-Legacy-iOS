#import "NSURLConnection+FoundationCompletions.h"

#include "curl.h"
#include "easy.h"

struct MemoryStruct {
	char *memory;
	size_t size;
};

static void *lc_realloc(void *ptr, size_t size) {
	if (ptr != NULL) {
		return realloc(ptr, size);
	}
	return malloc(size);
}

static size_t LCWriteMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data) {
	size_t realSize = size * nmemb;
	struct MemoryStruct *memoryStruct = (struct MemoryStruct *)data;

	memoryStruct->memory = lc_realloc(memoryStruct->memory, memoryStruct->size + realSize + 1);
	if (memoryStruct->memory == NULL) {
		return 0;
	}

	memcpy(&(memoryStruct->memory[memoryStruct->size]), ptr, realSize);
	memoryStruct->size += realSize;
	memoryStruct->memory[memoryStruct->size] = 0;
	return realSize;
}

@implementation NSURLConnection (FoundationCompletions)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)responsep error:(NSError **)errorp {
	struct MemoryStruct response;
	response.memory = NULL;
	response.size = 0;

	struct curl_slist *headerList = NULL;
	CURL *curlHandle = curl_easy_init();
	if (curlHandle == NULL) {
		if (errorp != NULL) {
			*errorp = [NSError errorWithDomain:@"LegacyChatAppConnectionDomain" code:1 userInfo:nil];
		}
		return nil;
	}

	curl_easy_setopt(curlHandle, CURLOPT_URL, [[[request URL] absoluteString] UTF8String]);
	curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1L);
	curl_easy_setopt(curlHandle, CURLOPT_SSL_VERIFYPEER, 0L);
	curl_easy_setopt(curlHandle, CURLOPT_NOSIGNAL, 1L);

	NSString *method = [request HTTPMethod];
	if ([method isEqualToString:@"POST"]) {
		NSData *body = [request HTTPBody];
		curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, [body bytes]);
		curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDSIZE, [body length]);
	} else if ([method isEqualToString:@"DELETE"]) {
		curl_easy_setopt(curlHandle, CURLOPT_CUSTOMREQUEST, "DELETE");
	} else {
		curl_easy_setopt(curlHandle, CURLOPT_HTTPGET, 1L);
	}

	NSDictionary *headers = [request allHTTPHeaderFields];
	for (NSString *headerKey in [headers allKeys]) {
		NSString *headerValue = [headers objectForKey:headerKey];
		headerList = curl_slist_append(headerList, [[NSString stringWithFormat:@"%@: %@", headerKey, headerValue] UTF8String]);
	}
	if (headerList != NULL) {
		curl_easy_setopt(curlHandle, CURLOPT_HTTPHEADER, headerList);
	}

	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, LCWriteMemoryCallback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, (void *)&response);

	int result = curl_easy_perform(curlHandle);
	if (result != 0) {
		if (headerList != NULL) {
			curl_slist_free_all(headerList);
		}
		curl_easy_cleanup(curlHandle);
		if (errorp != NULL) {
			*errorp = [NSError errorWithDomain:@"LegacyChatAppConnectionDomain" code:result userInfo:nil];
		}
		if (response.memory != NULL) {
			free(response.memory);
		}
		return nil;
	}

	long statusCode = 0;
	curl_easy_getinfo(curlHandle, CURLINFO_RESPONSE_CODE, &statusCode);
	if (responsep != NULL) {
		*responsep = [[[NSHTTPURLResponse alloc] initWithURL:[request URL]
			statusCode:(NSInteger)statusCode
			HTTPVersion:@"HTTP/1.1"
			headerFields:[NSDictionary dictionary]] autorelease];
	}

	NSData *data = [NSData dataWithBytes:response.memory length:response.size];

	if (headerList != NULL) {
		curl_slist_free_all(headerList);
	}
	curl_easy_cleanup(curlHandle);
	if (response.memory != NULL) {
		free(response.memory);
	}
	return data;
}

@end
