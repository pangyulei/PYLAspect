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
#import "AspectSwizzledInfo.h"
#import "AspectClassSwizzledMap.h"

#define LOG_ERROR(str) NSLog(@"%s %@", __func__, str)

@implementation NSObject (Aspect)

+ (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk {
    if (!sel || !blk) {
        return;
    }
    _safe_thread_perform(^{
        Class cls;
        Method meth = NULL;
        NSMethodSignature *sign;
        if ([self instancesRespondToSelector:sel]) {
            //替换类中的实例方法
            cls = self;
            meth = class_getInstanceMethod(self, sel);
            sign = [self instanceMethodSignatureForSelector:sel];
            
        } else if ([self respondsToSelector:sel]) {
            //替换类中的类方法
            cls = object_getClass(self);
            meth = class_getClassMethod(cls, sel);
            sign = [self methodSignatureForSelector:sel];
        }
        
        if (!meth) {
            LOG_ERROR(@"方法找不到");
            return;
        }
        
        IMP originSelIMP = method_getImplementation(meth);
        const char *types = method_getTypeEncoding(meth);
        
        //校验 blk 与 meth 参数是否一致
        NSMethodSignature *blkSign = _aspect_blockMethodSignature(blk);
        if (!_compareSignature(blkSign, sign)) {
            LOG_ERROR(@"block 签名与原方法不一致");
            return;
        }
        
        //储存信息
        NSString *token = _aspect_class_token(self, sel);
        AspectSwizzledInfo *info = _aspect_class_swizzled_info(token);
        if (info) {
            //之前 swizzle 过了直接更新就好了
            info.opt = opt;
            info.block = blk;
            _aspect_set_class_swizzled_info(token, info);
            return;
        }
        
        //sel -> _msgForward
        class_replaceMethod(cls, sel, _objc_msgForward, types);
        
        //_msgForward -> 我自己的 forward, 主动调用 block 等业务, 以及最终调用之前 swizzle 掉的方法
        SEL fowardSel = @selector(forwardInvocation:);
        class_replaceMethod(cls, fowardSel, (IMP)_class_aspectForwardInvocation, "@:@");
        
        //aliasSel -> originIMP
        SEL aliasSel = _aspect_alias_sel(sel);
        class_replaceMethod(cls, aliasSel, originSelIMP, types);
        
        info = [AspectSwizzledInfo new];
        info.block = blk;
        info.opt = opt;
        info.aliasSel = aliasSel;
        _aspect_set_class_swizzled_info(token, info);
    });
}

- (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk {
    if (!sel || !blk) {
        return;
    }
    _safe_thread_perform(^{
        Class cls;
        Method meth = NULL;
        NSMethodSignature *sign;
        if ([self respondsToSelector:sel]) {
            //替换实例方法
            cls = object_getClass(self);
            meth = class_getInstanceMethod(cls, sel);
            sign = [self methodSignatureForSelector:sel];
        }
        
        if (!meth) {
            LOG_ERROR(@"方法找不到");
            return;
        }
        
        IMP originSelIMP = method_getImplementation(meth);
        const char *types = method_getTypeEncoding(meth);
        
        //校验 blk 与 meth 参数是否一致
        NSMethodSignature *blkSign = _aspect_blockMethodSignature(blk);
        if (!_compareSignature(blkSign, sign)) {
            LOG_ERROR(@"block 签名与原方法不一致");
            return;
        }
        
        //创建子类
        NSString *subclassname = subclass_name(cls);
        Class subcls = objc_getClass(subclassname.UTF8String);
        if (nil == subcls) {
            subcls = objc_allocateClassPair(cls, subclassname.UTF8String, 0);
            if (!subcls) {
                NSLog(@"子类创建失败");
                return;
            }
            objc_registerClassPair(subcls);
            
            //sel -> _msgForward
            class_replaceMethod(subcls, sel, _objc_msgForward, types);
            
            //_msgForward -> 我自己的 forward, 主动调用 block 等业务, 以及最终调用之前 swizzle 掉的方法
            SEL fowardSel = @selector(forwardInvocation:);
            class_replaceMethod(subcls, fowardSel, (IMP)_instance_aspectForwardInvocation, "@:@");
            
            //aliasSel -> originIMP
            class_replaceMethod(subcls, _aspect_alias_sel(sel), originSelIMP, types);
        }
        
        //isa 替换
        object_setClass(self, subcls);
        
        //储存信息
        NSString *token = _aspect_inst_token(self, sel);
        NSMutableDictionary *map = [self aspect_swizzledInfoMap];
        if (!map) {
            map = @{}.mutableCopy;
        }
        
        AspectSwizzledInfo *info = [AspectSwizzledInfo new];
        info.block = blk;
        info.opt = opt;
        info.aliasSel = _aspect_alias_sel(sel);
        map[token] = info;
        [self setAspect_swizzledInfoMap:map];
    });
}

NSString* _aspect_inst_token(NSObject *inst, SEL sel) {
    return [NSString stringWithFormat:@"%p_%s", inst, sel_getName(sel)];
}

void _instance_aspectForwardInvocation(NSObject *self, SEL sel, NSInvocation *anInvocation) {
    NSString *token = _aspect_inst_token(self, anInvocation.selector);
    AspectSwizzledInfo *info = [self aspect_swizzledInfoMap][token];
    if (!info) {
        return;
    }
    if (info.opt & AspectOptionsReplace) {
        //完全替换
        _aspect_invokeBlockWithInvocation(info.block, anInvocation);
        return;
    }
    
    if (info.opt & AspectOptionsBefore) {
        //先调用 block
        _aspect_invokeBlockWithInvocation(info.block, anInvocation);
    }
    
    //再调用原来的实现
    anInvocation.selector = info.aliasSel;
    [anInvocation invoke];
    
    if (info.opt & AspectOptionsAfter) {
        //再次调用 block
        _aspect_invokeBlockWithInvocation(info.block, anInvocation);
    }
}

NSString* subclass_name(Class superclass) {
    NSString *prefix = @"aspect_subclass_";
    if ([[NSString stringWithUTF8String:class_getName(superclass)] containsString:prefix]) {
        return [NSString stringWithUTF8String:class_getName(superclass)];
    }
    return [NSString stringWithFormat:@"%@%s",prefix, class_getName(superclass)];
}

SEL _aspect_alias_sel(SEL sel) {
    NSString * const prefix = @"aspect_alias";
    if ([[NSString stringWithUTF8String:sel_getName(sel)] containsString:prefix]) {
        return sel;
    }
    return sel_registerName([NSString stringWithFormat:@"%@_%s", prefix, sel_getName(sel)].UTF8String);
}

void _class_aspectForwardInvocation(Class self, SEL sel, NSInvocation *anInvocation) {
    NSString *token;
    if (object_isClass(anInvocation.target)) {
        //替换的是类中的类方法
        token = _aspect_class_token(anInvocation.target, anInvocation.selector);
    } else {
        //替换的是类中的实例方法
        token = _aspect_class_token(object_getClass(anInvocation.target), anInvocation.selector);
    }
    AspectSwizzledInfo *info = _aspect_class_swizzled_info(token);
    if (!info) {
        return;
    }
    if (info.opt & AspectOptionsReplace) {
        //完全替换
        _aspect_invokeBlockWithInvocation(info.block, anInvocation);
        return;
    }
    
    if (info.opt & AspectOptionsBefore) {
        //先调用 block
        _aspect_invokeBlockWithInvocation(info.block, anInvocation);
    }
    
    //再调用原来的实现
    anInvocation.selector = info.aliasSel;
    [anInvocation invoke];
    
    if (info.opt & AspectOptionsAfter) {
        //再次调用 block
        _aspect_invokeBlockWithInvocation(info.block, anInvocation);
    }
}

void _aspect_invokeBlockWithInvocation(id block, NSInvocation *originInvocation) {
    NSMethodSignature *sign = _aspect_blockMethodSignature(block);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
    void *argBuf = NULL;
    for (NSUInteger i = 1; i<sign.numberOfArguments;i++) {
        const char *type = [originInvocation.methodSignature getArgumentTypeAtIndex:i+1];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        if ((argBuf = reallocf(argBuf, argSize))) {
            [originInvocation getArgument:argBuf atIndex:i+1];
            [invocation setArgument:argBuf atIndex:i];
        }
    }
    [invocation invokeWithTarget:block];
    if (argBuf != NULL) {
        free(argBuf);
    }
}

bool _compareSignature(NSMethodSignature *blkSign, NSMethodSignature *sign) {
    if (!blkSign) {
        LOG_ERROR(@"block 没有签名");
        return false;
    }
    if (!sign) {
        LOG_ERROR(@"方法没有签名");
        return false;
    }
    if (blkSign.numberOfArguments - 1 != sign.numberOfArguments - 2) {
        LOG_ERROR(@"block 参数个数不一致");
        return false;
    }
//    if (strcmp(blkSign.methodReturnType, sign.methodReturnType) != 0) {
//        LOG_ERROR(@"block 返回值不一致");
//        return false;
//    }
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

void _safe_thread_perform(void(^blk)(void)) {
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

- (void)setAspect_swizzledInfoMap:(NSMutableDictionary*)d {
    objc_setAssociatedObject(self, @selector(aspect_swizzledInfoMap), d, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary*)aspect_swizzledInfoMap {
    //避免多个instance同时做改动
    return [objc_getAssociatedObject(self, _cmd) mutableCopy];
}


@end
