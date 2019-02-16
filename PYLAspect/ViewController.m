//
//  ViewController.m
//  PYLAspect
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+Aspect.h"
#import "Person.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //交换类中的类方法
    [Person aspect_selector:@selector(talk:) options:AspectOptionsAfter|AspectOptionsBefore block:^(NSString *str) {
        NSLog(@"%@", str);
    }];
    [Person talk:@"mother"];
    
    //交换类中的实例方法
    [Person aspect_selector:@selector(fuck:) options:AspectOptionsReplace block:^(int a){
        NSLog(@"a%d", a);
    }];
    [[Person new] fuck:4];
}


@end
