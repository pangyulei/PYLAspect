//
//  AspectSwizzledInfo.h
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AspectOptions.h"

@interface AspectSwizzledInfo : NSObject
@property (nonatomic, assign) AspectOptions opt;
@property (nonatomic, copy) id block;
@property (nonatomic, assign) SEL aliasSel;
@end
