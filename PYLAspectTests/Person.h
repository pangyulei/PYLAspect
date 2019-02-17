//
//  Person.h
//  PYLAspectTests
//
//  Created by yulei pang on 2019/2/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>
extern int glb;
@interface Person : NSObject

+ (int)setGlb:(int)a;
- (void)workWith:(NSString *)str;
@end
