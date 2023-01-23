#import <Foundation/Foundation.h>

@protocol AutoHook <NSObject>
@required

+ (NSArray <NSString *> *)targetClasses;

@end
