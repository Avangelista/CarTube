@import Foundation;
@import ObjectiveC.runtime;
@import MachO.dyld;

#import "AutoHook.h"

@interface AutoHookImplementor : NSObject

@end

@implementation AutoHookImplementor

+ (void)load {
    [self implementAllMethodHooks];
}


+ (void)implementAllMethodHooks {
    unsigned classCount;
    Class *classes = objc_copyClassList(&classCount);
    if (!classes) {
        NSLog(@"Error: Auto hook couldn't get class list");
        return;
    }
    
    Protocol *hookProtocol = @protocol(AutoHook);
    
    for (int index = 0; index < classCount; index += 1) {
        Class hookClass = classes[index];
        if (class_conformsToProtocol(hookClass, hookProtocol) == false) {
            continue;
        }
        [self implementHooksForClass:hookClass];
    }
    
    free(classes);
}

+ (void)implementHooksForClass:(Class)hookClass {
    const char *className = class_getName(hookClass);
    Class metaClass = hookClass;
    if (class_isMetaClass(metaClass) == FALSE && className != NULL) {
        Class potentialMetaClass = objc_getMetaClass(className);
        if (potentialMetaClass) {
            metaClass = potentialMetaClass;
        }
        
        NSArray *targetClasses = [hookClass targetClasses];
        
        for (NSString *targetClassName in targetClasses) {
            Class targetClass = NSClassFromString(targetClassName);
            if (!targetClass) {
                NSLog(@"Couldn't find target class %@", targetClassName);
                continue;
            }
            
            [self implementMethodHooksForClass:hookClass
                                   targetClass:targetClass];
        }
    }
}

+ (void)implementMethodHooksForClass:(Class)hookClass
                         targetClass:(Class)targetClass {
    unsigned int methodCount;
    Method *methods = class_copyMethodList(hookClass, &methodCount);
    if (!methods) {
        NSLog(@"Couldn't get method list for class: %s", class_getName(hookClass));
        return;
    }
    for (int methodIndex = 0; methodIndex < methodCount; methodIndex += 1) {
        Method hookMethod = methods[methodIndex];
        if (!hookMethod) {
            continue;
        }
        
        SEL hookMethodSelector = method_getName(hookMethod);
        if (!hookMethodSelector) {
            continue;
        }
        
        NSString *hookPrefix = @"hook_";
        NSString *originalStorePrefix = @"original_";
        
        NSString *hookMethodName = NSStringFromSelector(hookMethodSelector);
        if ([hookMethodName hasPrefix:hookPrefix] == FALSE) {
            if ([hookMethodName hasPrefix:originalStorePrefix] == FALSE) {
                [self addMethodToClass:targetClass fromClass:hookClass method:hookMethod];
            }
            continue;
        }
        
        NSString *targetMethodName = [hookMethodName substringFromIndex:hookPrefix.length];
        SEL targetMethodSelector = NSSelectorFromString(targetMethodName);
        Method targetMethod = class_getInstanceMethod(targetClass, targetMethodSelector);
        BOOL targetMetaClass = FALSE;
        
        if (!targetMethod) {
            targetMetaClass = TRUE;
            targetMethod = class_getClassMethod(targetClass, targetMethodSelector);
        }
        
        if (!targetMethod) {
            NSLog(@"Error: Target class %s doesn't incorporate method %@",
                  class_getName(targetClass), targetMethodName);
            continue;
        }
        
        const char *targetTypeEncoding = method_getTypeEncoding(targetMethod);
        const char *hookedTypeEncoding = method_getTypeEncoding(hookMethod);
        if (strcmp(targetTypeEncoding, hookedTypeEncoding) != 0) {
            NSLog(@"Error: Not implementing hook: target type encoding %s doesn't match hook type encoding: %s for selector %s",
                  targetTypeEncoding, hookedTypeEncoding, sel_getName(targetMethodSelector));
            return;
        }
        
        IMP hookImplementation = method_getImplementation(hookMethod);
        if (!hookImplementation) {
            NSLog(@"Error: Couldn't get implementation for method %@", hookMethodName);
            continue;
        }
        
        NSString *originalStoreMethodName = [originalStorePrefix stringByAppendingString:targetMethodName];
        SEL originalStoreSelector = NSSelectorFromString(originalStoreMethodName);
        
        Method originalStoreMethod = class_getInstanceMethod(hookClass, originalStoreSelector);
        if (!originalStoreMethod) {
            class_getClassMethod(hookClass, originalStoreSelector);
        }
        
        IMP originalImplementation = method_getImplementation(targetMethod);
        if (!originalImplementation) {
            NSLog(@"Error: Couldn't get implementation for method %@", targetMethodName);
            continue;
        }
        
        if (originalStoreMethod) {
            Class addMethodClass = targetClass;
            if (targetMetaClass) {
                addMethodClass = objc_getMetaClass(class_getName(targetClass));
            }
            class_addMethod(addMethodClass, originalStoreSelector, originalImplementation, targetTypeEncoding);
        }
        
        IMP previousImplementation = class_replaceMethod(targetClass, targetMethodSelector, hookImplementation, targetTypeEncoding);
        if (previousImplementation != NULL) {
            NSLog(@"Implemented hook for [%s %@]", class_getName(targetClass), targetMethodName);
        } else {
            NSLog(@"Failed to implement hook for [%s %@]", class_getName(targetClass), targetMethodName);
        }
        
    }
    
    free(methods);
}

+ (void)addMethodToClass:(Class)targetClass fromClass:(Class)hookClass method:(Method)method {
    SEL selector = method_getName(method);
    const char *typeEncoding = method_getTypeEncoding(method);
    IMP implementation = method_getImplementation(method);
    class_addMethod(targetClass, selector, implementation, typeEncoding);
}

@end