//
//  AspectOptions.h
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#ifndef AspectOptions_h
#define AspectOptions_h

typedef NS_OPTIONS(NSInteger, AspectOptions) {
    AspectOptionsReplace = 1 << 0,
    AspectOptionsBefore = 1 << 1,
    AspectOptionsAfter = 1 << 2,
};

#endif /* AspectOptions_h */
