//
//  AspectClassSwizzledMap.h
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#ifndef AspectClassSwizzledMap_h
#define AspectClassSwizzledMap_h

@class AspectSwizzledInfo;

dispatch_queue_t _aspect_class_queue() {
    static dispatch_once_t onceToken;
    static dispatch_queue_t q;
    dispatch_once(&onceToken, ^{
        q = dispatch_queue_create("aspect_class_queue", DISPATCH_QUEUE_CONCURRENT);
    });
    return q;
}

NSString* _aspect_token(Class cls, SEL sel) {
    return [NSString stringWithFormat:@"%s_%s", class_getName(cls), sel_getName(sel)];
}

NSMutableDictionary* _aspect_class_swizzled_map() {
    static NSMutableDictionary<NSString*, AspectSwizzledInfo*> *infos;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        infos = @{}.mutableCopy;
    });
    return infos;
}

//取值
AspectSwizzledInfo* _aspect_class_swizzled_info(NSString *token) {
    __block AspectSwizzledInfo *info;
    dispatch_sync(_aspect_class_queue(), ^{
        info = _aspect_class_swizzled_map()[token];
    });
    return info;
}

//设值
void _aspect_set_class_swizzled_info(NSString *token, AspectSwizzledInfo *info) {
    //这里要用sync，因为调用设值函数之后可能马上就要用到，必须保证设值成功才结束本函数
    dispatch_barrier_sync(_aspect_class_queue(), ^{
        _aspect_class_swizzled_map()[token] = info;
    });
}


#endif /* AspectClassSwizzledMap_h */
