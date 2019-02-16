//
//  Person.m
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "Person.h"

@implementation Person
+ (void)talk:(NSString *)a {
    NSLog(@"person call");
}

-(void)fuck:(int)a {
    NSLog(@"fuck called");
}

- (void)testBlock:(int(^)(int c, int b))ssss {
    
}
@end
