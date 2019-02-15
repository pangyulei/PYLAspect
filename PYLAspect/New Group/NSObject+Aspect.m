//
//  NSObject+Aspect.m
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "NSObject+Aspect.h"
#import "AspectBlock.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <libkern/OSAtomic.h>

#define LOG_ERROR(str) NSLog(@"%s %@", __func__, str)

@implementation NSObject (Aspect)

+ (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk {
    if (!sel || !blk) {
        return;
    }
    safe_thread_perform(^{
        Method meth = class_getClassMethod(self, sel);
        if (!meth) {
            LOG_ERROR(@"方法找不到");
            return;
        }
        //校验 blk 与 meth 参数是否一致
        NSMethodSignature *blkSign = blockMethodSignature(blk);
        if (!blkSign) {
            LOG_ERROR(@"block 没有签名");
            return;
        }
        NSMethodSignature *sign = [self methodSignatureForSelector:sel];
        if (!compareSignature(blkSign, sign)) {
            LOG_ERROR(@"block 签名与原方法不一致");
            return;
        }
        
        //swizzle forward
        SEL fowardSel = @selector(forwardInvocation:);
        class_replaceMethod(object_getClass(self), fowardSel, (IMP)aspectForwardInvocation, "@:@");
        
        //sel -> _msgForward
        const char *types = method_getTypeEncoding(meth);
        IMP originIMP = class_replaceMethod(object_getClass(self), sel, _objc_msgForward, types);
        if (!originIMP) {
            originIMP = method_getImplementation(meth);
        }
        //aliasSel -> originIMP
        SEL aliasSel = sel_registerName([NSString stringWithFormat:@"aspect_alias_%s", sel_getName(sel)].UTF8String);
        class_replaceMethod(self, aliasSel, originIMP, types);
    });
}

- (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk {
    
}

void aspectForwardInvocation(NSObject *slf, SEL sel, NSInvocation *anInvocation) {
    NSLog(@"%s", sel_getName([anInvocation selector]));
    NSLog(@"%@", [anInvocation target]);
}

bool compareSignature(NSMethodSignature *blkSign, NSMethodSignature *sign) {
    if (blkSign.numberOfArguments - 1 != sign.numberOfArguments - 2) {
        LOG_ERROR(@"block 参数个数不一致");
        return false;
    }
    if (strcmp(blkSign.methodReturnType, sign.methodReturnType) != 0) {
        LOG_ERROR(@"block 返回值不一致");
        return false;
    }
    for (NSUInteger i=1;i<blkSign.numberOfArguments;i++) {
        const char *blkArg = [blkSign getArgumentTypeAtIndex:i];
        const char *arg = [sign getArgumentTypeAtIndex:i+1];
        if (blkArg[0] != arg[0]) {
            LOG_ERROR(@"block 参数类型不一致");
            return false;
        };
    }
    return true;
}

void safe_thread_perform(void(^blk)(void)) {
    if (!blk) {
        return;
    }
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t sema;
    dispatch_once(&onceToken, ^{
        sema = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    blk();
    dispatch_semaphore_signal(sema);
}

@end
