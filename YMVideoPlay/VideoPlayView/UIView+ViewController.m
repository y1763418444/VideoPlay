//
//  UIView+ViewController.m
//  马上游
//
//  Created by 徐文强 on 16/5/19.
//
//

#import "UIView+ViewController.h"

@implementation UIView (ViewController)

- (UIViewController*)viewController {
    
    for (UIView *vw = [self superview]; vw; vw = vw.superview) {
        UIResponder *nextResponder = [vw nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}
@end
