//
//  UIApplication+DTKTextStyles.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "UIApplication+DTKTextStyles.h"

#import "DTKDynamicTypeManager.h"

#import <JRSwizzle.h>
#import <objc/runtime.h>

static char DTKPreferredContentSizeCategoryAttribute;
static char DTKPreferredContentSizeCategoryBeforeSilencingAttribute;

// An array of the content size category strings in ascending size order
static NSArray * _contentSizeCategories;

// The index of the default "Large" size category in _contentSizeCategories
static const NSUInteger _indexOfDefaultSizeCategory = 3;

// The index of the first accessibility size "Medium" in _contentSizeCategories
static const NSUInteger _indexOfFirstAccessibilitySizeCategory = 7;

@implementation UIApplication (DTKTextStyles)

+ (void)load
{
    NSError * error;
    BOOL      success = [self jr_swizzleMethod:@selector(preferredContentSizeCategory)
                                    withMethod:@selector(DTK_preferredContentSizeCategory)
                                         error:&error];

    if (!success)
    {
        // TODO error handling
    }

    _contentSizeCategories = @[UIContentSizeCategoryExtraSmall,
                               UIContentSizeCategorySmall,
                               UIContentSizeCategoryMedium,
                               UIContentSizeCategoryLarge,
                               UIContentSizeCategoryExtraLarge,
                               UIContentSizeCategoryExtraExtraLarge,
                               UIContentSizeCategoryExtraExtraExtraLarge,
                               UIContentSizeCategoryAccessibilityMedium,
                               UIContentSizeCategoryAccessibilityLarge,
                               UIContentSizeCategoryAccessibilityExtraLarge,
                               UIContentSizeCategoryAccessibilityExtraExtraLarge,
                               UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];
}

#pragma mark - Working with content size categories

- (NSArray *)DTK_contentSizeCategories
{
    return _contentSizeCategories;
}

- (NSInteger)DTK_preferredContentSizeCategoryDistanceFromDefault
{
    NSString * preferredContentSizeCategory = self.preferredContentSizeCategory;
    NSInteger  index = [_contentSizeCategories indexOfObject:preferredContentSizeCategory];

    if (index == NSNotFound)
    {
        return 0;
    }

    return index - _indexOfDefaultSizeCategory;
}

- (NSString *)DTK_contentSizeCategoryByDistanceFromDefault:(NSInteger)distance
{
    NSInteger contentSizeIndex = _indexOfDefaultSizeCategory + distance;

    if (contentSizeIndex < 0)
    {
        contentSizeIndex = 0;
    }
    else if (contentSizeIndex >= _contentSizeCategories.count)
    {
        contentSizeIndex = _contentSizeCategories.count - 1;
    }

    return _contentSizeCategories[contentSizeIndex];
}

- (CGFloat)DTK_preferredContentSizeCategoryStandardFontSizeMultiplier
{
    UIFontDescriptor * bodyFontDescriptor  = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    CGFloat            defaultBodyFontSize = [UIFont labelFontSize];

    return bodyFontDescriptor.pointSize / defaultBodyFontSize;
}

- (BOOL)DTK_isValidContentSizeCategory:(NSString *)contentSizeCategory
{
    NSInteger index = [_contentSizeCategories indexOfObject:contentSizeCategory];

    return index != NSNotFound;
}

- (BOOL)DTK_isContentSizeCategorySizedForAccessibility:(NSString *)contentSizeCategory
{
    NSInteger index = [_contentSizeCategories indexOfObject:contentSizeCategory];

    return index >= _indexOfFirstAccessibilitySizeCategory;
}

#pragma mark - Modifying the preferredContentSizeCategory

- (NSString *)DTK_preferredContentSizeCategory
{
    NSString * preferredContentSizeCategory = objc_getAssociatedObject(self, &DTKPreferredContentSizeCategoryAttribute);

    if (preferredContentSizeCategory)
    {
        return preferredContentSizeCategory;
    }

    // Call the original implementation of preferredContentSizeCategory
    return [self DTK_preferredContentSizeCategory];
}

- (void)setDTK_preferredContentSizeCategory:(NSString *)preferredContentSizeCategory
{
    if (preferredContentSizeCategory && ![self DTK_isValidContentSizeCategory:preferredContentSizeCategory])
    {
        // TODO: log warning
        return;
    }

    [self willChangeValueForKey:@"preferredContentSizeCategory"];

    objc_setAssociatedObject(self, &DTKPreferredContentSizeCategoryAttribute,
                             preferredContentSizeCategory, OBJC_ASSOCIATION_COPY_NONATOMIC);

    [self didChangeValueForKey:@"preferredContentSizeCategory"];

    // Emit the change notification, unless it is silenced
    if (!self.DTK_isSilencingPreferredContentSizeChangeNotifications)
    {
        if ([NSThread isMainThread])
        {
            [self DTK_preferredContentSizeCategoryDidChange:preferredContentSizeCategory];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self DTK_preferredContentSizeCategoryDidChange:preferredContentSizeCategory];
            });
        }
    }
}

- (void)DTK_preferredContentSizeCategoryDidChange:(id)newCategory
{
    if (!newCategory)
    {
        newCategory = self.preferredContentSizeCategory;
    }

    NSDictionary * userInfo = @{
                                UIContentSizeCategoryNewValueKey : newCategory
                                };

    [[NSNotificationCenter defaultCenter] postNotificationName:UIContentSizeCategoryDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (NSString *)DTK_preferredContentSizeCategoryBeforeSilencing
{
    return objc_getAssociatedObject(self, &DTKPreferredContentSizeCategoryBeforeSilencingAttribute);
}

- (void)setDTK_preferredContentSizeCategoryBeforeSilencing:(NSString *)preferredContentSizeCategoryBeforeSilencing
{
    [self willChangeValueForKey:@"preferredContentSizeCategoryBeforeSilencing"];

    objc_setAssociatedObject(self, &DTKPreferredContentSizeCategoryBeforeSilencingAttribute,
                             preferredContentSizeCategoryBeforeSilencing, OBJC_ASSOCIATION_COPY_NONATOMIC);

    [self didChangeValueForKey:@"preferredContentSizeCategoryBeforeSilencing"];
}

- (BOOL)DTK_isSilencingPreferredContentSizeChangeNotifications
{
    return self.DTK_preferredContentSizeCategoryBeforeSilencing != nil;
}

- (void)DTK_beginSilencingPreferredContentSizeChangeNotifications
{
    if (!self.DTK_preferredContentSizeCategoryBeforeSilencing)
    {
        self.DTK_preferredContentSizeCategoryBeforeSilencing = self.preferredContentSizeCategory;
    }
}

- (void)DTK_endSilencingPreferredContentSizeChangeNotifications
{
    NSString * preferredContentSizeCategoryBeforeSilencing = self.DTK_preferredContentSizeCategoryBeforeSilencing;

    self.DTK_preferredContentSizeCategoryBeforeSilencing = nil;

    if (![preferredContentSizeCategoryBeforeSilencing isEqualToString:self.preferredContentSizeCategory])
    {
        if ([NSThread isMainThread])
        {
            [self DTK_preferredContentSizeCategoryDidChange:self.preferredContentSizeCategory];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self DTK_preferredContentSizeCategoryDidChange:self.preferredContentSizeCategory];
            });
        }
    }
}

@end