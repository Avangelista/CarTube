@interface UIApplicationRotationFollowingWindow : UIWindow
@end

@interface UIAutoRotatingWindow : UIApplicationRotationFollowingWindow
@end

@protocol _UICanvasBasedObject <NSObject>
@end

@interface UITextEffectsWindow : UIAutoRotatingWindow <_UICanvasBasedObject>
@end

