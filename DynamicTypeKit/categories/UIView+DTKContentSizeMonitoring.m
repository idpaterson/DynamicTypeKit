//
//  UIView+DTKContentSizeMonitoring.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/17/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "UIView+DTKContentSizeMonitoring.h"

#import "DTKDynamicTypeManager.h"
#import "UIApplication+DTKTextStyles.h"

#import <JRSwizzle.h>
#import <objc/runtime.h>

static char DTKViewLastKnownContentSizeAttribute;

@implementation UIView (DTKContentSizeMonitoring)

+ (void)load
{
    NSError * error;
    BOOL success = [self jr_swizzleMethod:@selector(willMoveToWindow:)
                               withMethod:@selector(DTK_willMoveToWindow:)
                                    error:&error];

    if (!success)
    {
        // TODO error handling
    }

    success = [self jr_swizzleMethod:@selector(setFrame:)
                               withMethod:@selector(DTK_setFrame:)
                                    error:&error];

    if (!success)
    {
        // TODO error handling
    }
}

- (void)DTK_willMoveToWindow:(UIWindow *)newWindow
{
    [self DTK_willMoveToWindow:newWindow];

    // Added to a window, if previously removed then update the content size if
    // necessary.
    // Note that -updateFontsInViewsForPreferredContentSizeCategory: will set
    // the DTK_lastKnownContentSizeCategory on any view that is processed. So,
    // once the root view moves back to a window its hierarchy will be updated
    // in that call and not again in their own -DTK_willMoveToWindow:
    if (newWindow)
    {
        NSString * lastKnownContentSizeCategory = self.DTK_lastKnownContentSizeCategory;

        if (lastKnownContentSizeCategory)
        {
            NSString * preferredContentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;

            if (![preferredContentSizeCategory isEqualToString:lastKnownContentSizeCategory])
            {
                [[DTKDynamicTypeManager sharedManager] updateFontsInViewsForPreferredContentSizeCategory:@[self]];
            }
        }
    }
    // Removed from a window, track the current content size in case the view is
    // displayed again later.
    else
    {
        self.DTK_lastKnownContentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    }
}

- (void)DTK_setFrame:(CGRect)frame
{
    [self DTK_setFrame:frame];

    if (!self.DTK_lastKnownContentSizeCategory)
    {
        self.DTK_lastKnownContentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    }
}

- (NSString *)DTK_lastKnownContentSizeCategory
{
    return objc_getAssociatedObject(self, &DTKViewLastKnownContentSizeAttribute);
}

- (void)setDTK_lastKnownContentSizeCategory:(NSString *)lastKnownContentSizeCategory
{
    [self willChangeValueForKey:@"lastKnownContentSizeCategory"];

    objc_setAssociatedObject(self, &DTKViewLastKnownContentSizeAttribute,
                             lastKnownContentSizeCategory, OBJC_ASSOCIATION_COPY_NONATOMIC);

    [self didChangeValueForKey:@"lastKnownContentSizeCategory"];
}

@end
