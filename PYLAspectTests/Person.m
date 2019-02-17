//
//  Person.m
//  PYLAspectTests
//
//  Created by yulei pang on 2019/2/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "Person.h"

int glb = 0;

@implementation Person

+ (int)setGlb:(int)a {
    glb = a;
    return a;
}

- (void)workWith:(NSString *)str {
    
}
@end
