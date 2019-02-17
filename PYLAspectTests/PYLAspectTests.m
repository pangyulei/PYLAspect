//
//  PYLAspectTests.m
//  PYLAspectTests
//
//  Created by yulei pang on 2019/2/16.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+Aspect.h"
#import "Person.h"
#import <objc/runtime.h>

@interface PYLAspectTests : XCTestCase

@end

@implementation PYLAspectTests

- (void)setUp {
    glb = 0;
}

- (void)test_类中的类方法_block不匹配 {
    __block bool called = false;
    [Person aspect_selector:@selector(setGlb:) options:AspectOptionsReplace block:^{
        //not call 因为参数不匹配
        called = true;
    }];
    [Person setGlb:1];
    XCTAssertFalse(called);
}

- (void)test_类中的类方法_sel不匹配 {
    __block bool called = false;
    [Person aspect_selector:sel_registerName("NOTExist:") options:AspectOptionsReplace block:^(int a){
        //not call 因为sel不匹配
        called = true;
    }];
    [Person setGlb:1];
    XCTAssertFalse(called);
}

- (void)test_类中的类方法_正常替换 {
    __block bool called = false;
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsReplace block:^(int a){
        called = true;
        XCTAssert(a == 1);
    }];
    [Person setGlb:1];
    XCTAssert(called);
}

- (void)test_类中的类方法_只要options包含replace就替换 {
    __block int calledCount = 0;
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsReplace|AspectOptionsAfter block:^(int a){
        calledCount++;
        XCTAssert(a == 1);
        glb = 2;
    }];
    [Person setGlb:1];
    XCTAssert(glb == 2);
    XCTAssert(calledCount == 1);
}

- (void)test_类中的类方法_options之前调用 {
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsBefore block:^(int a){
        XCTAssert(a == 1);
        XCTAssert(glb == 0);
    }];
    [Person setGlb:1];
    XCTAssert(glb == 1);
}

- (void)test_类中的类方法_options之后调用 {
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsAfter block:^(int a){
        XCTAssert(a == 1);
        XCTAssert(glb == 1);
    }];
    [Person setGlb:1];
    XCTAssert(glb == 1);
}

- (void)test_类中的类方法_options前后调用 {
    __block int calledCount = 0;
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsBefore|AspectOptionsAfter block:^(int a){
        XCTAssert(a == 1);
        calledCount++;
    }];
    [Person setGlb:1];
    XCTAssert(glb == 1);
    XCTAssert(calledCount == 2);
}

- (void)test_类中的类方法_替换n次只有最后一次生效 {
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsReplace block:^(int a){
        //不该调用
        XCTAssert(false);
    }];
    __block int calledCount = 0;
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsReplace block:^(int a){
        calledCount++;
        XCTAssert(a == 1);
    }];
    
    [Person setGlb:1];
    XCTAssert(calledCount == 1);
}

- (void)test_类中的类方法_触发n次 {
    __block int calledCount = 0;
    [Person aspect_selector:sel_registerName("setGlb:") options:AspectOptionsReplace block:^(int a){
        calledCount = a;
    }];
    
    [Person setGlb:1];
    [Person setGlb:2];
    [Person setGlb:3];
    XCTAssert(calledCount == 3);
}

- (void)test_类中的实例方法 {
    NSMutableString *s = @"".mutableCopy;
    [Person aspect_selector:@selector(workWith:) options:AspectOptionsReplace block:^(NSString *str) {
        [s appendString:str];
    }];
    Person *p1 = [Person new];
    [p1 workWith:@"p1"];
    
    Person *p2 = [Person new];
    [p2 workWith:@"p2"];
    XCTAssert([s isEqualToString:@"p1p2"]);
}

- (void)test_类中的实例方法_n次 {
    NSMutableString *s = @"".mutableCopy;
    [Person aspect_selector:@selector(workWith:) options:AspectOptionsReplace block:^(NSString *str) {
        [s appendString:str];
    }];
    [Person aspect_selector:@selector(workWith:) options:AspectOptionsReplace block:^(NSString *str) {
        [s replaceCharactersInRange:NSMakeRange(0, s.length) withString:@"hello"];
    }];
    Person *p1 = [Person new];
    [p1 workWith:@"p1"];
    XCTAssert([s isEqualToString:@"hello"]);
}

- (void)test_实例中的实例方法_sel不匹配 {
    Person *p1 = [Person new];
    [p1 aspect_selector:sel_registerName("notexist") options:AspectOptionsReplace block:^(NSString *s){
        XCTAssert(false);
    }];
    [p1 workWith:nil];
}

- (void)test_实例中的实例方法_block不匹配 {
    Person *p1 = [Person new];
    [p1 aspect_selector:sel_registerName("workWith:") options:AspectOptionsReplace block:^{
        XCTAssert(false);
    }];
    [p1 workWith:nil];
}

- (void)test_实例中的实例方法 {
    Person *p1 = [Person new];
    [p1 aspect_selector:sel_registerName("workWith:") options:AspectOptionsReplace block:^(NSString *str) {
        XCTAssert([str isEqualToString:@"john"]);
    }];
    [p1 workWith:@"john"];
    [[Person new] workWith:@"jack"];//不会触发
}

- (void)test_实例中的实例方法_替换n次 {
    Person *p1 = [Person new];
    __block int count = 0;
    [p1 aspect_selector:sel_registerName("workWith:") options:AspectOptionsReplace block:^(NSString *str) {
        count--;//被覆盖
    }];
    [p1 aspect_selector:sel_registerName("workWith:") options:AspectOptionsReplace block:^(NSString *str) {
        count++;
    }];
    [p1 workWith:@"john"];
    XCTAssert(count == 1);
    const char *clsname = object_getClassName(p1);
    XCTAssert(strcmp(clsname, "aspect_subclass_Person") == 0); //strcmp == 0 代表 true
}

@end
