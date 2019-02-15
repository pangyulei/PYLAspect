//
//  NSObject+Aspect.h
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, AspectOptions) {
    AspectOptionsReplace = 1 << 0,
    AspectOptionsBefore = 1 << 1,
    AspectOptionsAfter = 1 << 2,
};

@interface NSObject (Aspect)

+ (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk;
- (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk;

@end
