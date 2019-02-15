//
//  AspectBlock.h
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#ifndef AspectBlock_h
#define AspectBlock_h

//此处 AspectBlock 的定义拷贝自 Clang 文档 http://clang.llvm.org/docs/Block-ABI-Apple.html
enum {
    // Set to true on blocks that have captures (and thus are not true
    // global blocks) but are known not to escape for various other
    // reasons. For backward compatiblity with old runtimes, whenever
    // BLOCK_IS_NOESCAPE is set, BLOCK_IS_GLOBAL is set too. Copying a
    // non-escaping block returns the original block and releasing such a
    // block is a no-op, which is exactly how global blocks are handled.
    BLOCK_IS_NOESCAPE      =  (1 << 23),
    
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};

struct AspectBlockDesc {
    unsigned long int reserved;         // NULL
    unsigned long int size;         // sizeof(struct Block_literal_1)
    //        // optional helper functions
    //        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    //        void (*dispose_helper)(void *src);             // IFF (1<<25)
    //        // required ABI.2010.3.16
    //        const char *signature;                         // IFF (1<<30)
    //因为 copy_helper 和 dispose_helper 是不一定存在的，所以这里用 extra[1] 去接，c 语言中 int a[1] = {1,2,3} 是不会出错的
    void *extras[1];
};
typedef struct AspectBlockDesc AspectBlockDesc;

struct AspectBlock {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    AspectBlockDesc *descriptor;
    // imported variables
};
typedef struct AspectBlock AspectBlock;

NSMethodSignature * blockMethodSignature(id blk) {
    AspectBlock *aspectBlk = (__bridge void *)blk;
    //判断有没有 signature
    if (!(aspectBlk->flags & BLOCK_HAS_SIGNATURE)) {
        return nil;
    }
    if (aspectBlk->flags & BLOCK_HAS_COPY_DISPOSE) {
        //有 copy_helper, dispose_helper 和 signature
        //取第2个下标的值就是 signature 的值
        return [NSMethodSignature signatureWithObjCTypes:aspectBlk->descriptor->extras[2]];
    } else {
        //没有 copy_helper, dispose_helper，只有 signature
        return [NSMethodSignature signatureWithObjCTypes:aspectBlk->descriptor->extras[0]];
    }
}

#endif /* AspectBlock_h */
