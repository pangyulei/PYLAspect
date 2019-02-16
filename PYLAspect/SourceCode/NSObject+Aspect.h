//
//  NSObject+Aspect.h
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AspectOptions.h"

@interface NSObject (Aspect)

+ (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk;
- (void)aspect_selector:(SEL)sel options:(AspectOptions)opt block:(id)blk;

@end
