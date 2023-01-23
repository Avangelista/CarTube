// Hide the large and buggy scroll indicator that CarPlay adds to the WebView

@import UIKit;
#import "AutoHook.h"
#import "_UIStaticScrollBar.h"

@interface HOOK_UIStaticScrollBar: _UIStaticScrollBar <AutoHook>
@end
@implementation HOOK_UIStaticScrollBar

+ (NSArray *)targetClasses {
    return @[@"_UIStaticScrollBar"];
}

// not the best idea to hook this method... but I have no better ideas
- (void)hook_layoutSubviews {
    self.hidden = YES;
}

@end
