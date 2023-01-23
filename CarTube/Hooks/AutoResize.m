// Prevents all windows from overlapping the CarPlay status bar

@import UIKit;
#import <Foundation/Foundation.h>
#import "AutoHook.h"
#import <UIKit/UIWindow.h>
#import "UIScreen+_isCarScreen.h"
#import "UITextEffectsWindow.h"

@interface HOOKUIWindow: UIWindow <AutoHook>
@end
@implementation HOOKUIWindow

+ (NSArray *)targetClasses {
    return @[@"UIWindow"];
}

- (void)hook_setRootViewController:(UIViewController *)arg1 {
    if (self.screen._isCarScreen) {
        // kill off the text effects window so we don't get the buggy keyboard bar
        if ([self isKindOfClass:[UITextEffectsWindow class]]) {
            return;
        }
        // resize window to the safe area outside the status bar
        CGRect safeFrame = [[self safeAreaLayoutGuide] layoutFrame];
        [self setFrame:safeFrame];
    }
    [self original_setRootViewController:arg1];
}

- (void)original_setRootViewController:(UIViewController *)arg1 { }

@end
