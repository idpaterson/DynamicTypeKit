//
//  UIFontDescriptor+DTKTextStyles.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "UIFontDescriptor+DTKTextStyles.h"

#import "UIApplication+DTKTextStyles.h"

#import <JRSwizzle.h>
#import <objc/runtime.h>

// Tracks the font descriptors that have been registered (or generated by
// interpolation) for each custom text style and content size category.
static NSMutableDictionary * _fontDescriptorsByContentSizeCategoryByCustomTextStyle;

// Holds a few font descriptor attribute names that cannot be overridden once a
// text style is set. For example, if the registered descriptor uses the font
// Avenir, it should not be possible to create a derivative of that using all
// the same attributes but a different font name because it breaks the concept
// of well-defined text styles.
static NSArray * _protectedAttributesForStyledFonts;

@implementation UIFontDescriptor (DTKTextStyles)

+ (void)load
{
    Class fontDescriptorInstanceClass = NSClassFromString(@"UICTFontDescriptor");

    NSError * error;
    BOOL      success = [self jr_swizzleClassMethod:@selector(preferredFontDescriptorWithTextStyle:)
                                    withClassMethod:@selector(DTK_preferredFontDescriptorWithCustomTextStyle:)
                                              error:&error];

    if (!success)
    {
        // TODO error handling
    }

    success = [fontDescriptorInstanceClass jr_swizzleMethod:@selector(matchingFontDescriptorsWithMandatoryKeys:)
                                                 withMethod:@selector(DTK_matchingFontDescriptorsWithMandatoryKeys:)
                                                      error:&error];

    if (!success)
    {
        // TODO error handling
    }

    _fontDescriptorsByContentSizeCategoryByCustomTextStyle = [NSMutableDictionary dictionary];

    // Changing these attributes would result in a significantly different font
    // than the style intended.
    _protectedAttributesForStyledFonts = @[UIFontDescriptorFamilyAttribute,
                                           UIFontDescriptorNameAttribute,
                                           UIFontDescriptorFaceAttribute,
                                           UIFontDescriptorSizeAttribute,
                                           UIFontDescriptorVisibleNameAttribute];
}

+ (void)DTK_registerFontDescriptors:(NSDictionary *)descriptorsByContentSizeCategory forCustomTextStyle:(NSString *)style
{
    if (!style || descriptorsByContentSizeCategory.count == 0)
    {
        return;
    }

    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        NSMutableDictionary * descriptors = [NSMutableDictionary dictionaryWithCapacity:descriptorsByContentSizeCategory.count];
        NSDictionary        * attributes  = @{
                                              UIFontDescriptorTextStyleAttribute : style
                                              };

        // Map point sizes to full-fledged descriptors
        [descriptorsByContentSizeCategory enumerateKeysAndObjectsUsingBlock:^(NSString * contentSizeCategory, UIFontDescriptor * descriptor, BOOL * stop) {
            descriptors[contentSizeCategory] = [descriptor fontDescriptorByAddingAttributes:attributes];
        }];

        _fontDescriptorsByContentSizeCategoryByCustomTextStyle[style] = descriptors;
    }
}

+ (void)DTK_registerFontDescriptor:(UIFontDescriptor *)descriptor withPointSizes:(NSDictionary *)pointSizesByContentSizeCategory forCustomTextStyle:(NSString *)style
{
    if (!style || !descriptor || pointSizesByContentSizeCategory.count == 0)
    {
        return;
    }

    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        NSMutableDictionary * descriptors = [NSMutableDictionary dictionaryWithCapacity:pointSizesByContentSizeCategory.count];

        // Map point sizes to full-fledged descriptors
        [pointSizesByContentSizeCategory enumerateKeysAndObjectsUsingBlock:^(NSString * contentSizeCategory, NSNumber * pointSize, BOOL * stop) {
            NSDictionary * attributes = @{ UIFontDescriptorTextStyleAttribute : style,
                                           UIFontDescriptorSizeAttribute : pointSize };

            descriptors[contentSizeCategory] = [descriptor fontDescriptorByAddingAttributes:attributes];
        }];

        _fontDescriptorsByContentSizeCategoryByCustomTextStyle[style] = descriptors;
    }
}

+ (void)DTK_registerFontDescriptor:(UIFontDescriptor *)descriptor forCustomTextStyle:(NSString *)style
{
    if (!style || !descriptor)
    {
        return;
    }

    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        NSMutableDictionary * descriptors = [NSMutableDictionary dictionaryWithCapacity:1];
        NSDictionary        * attributes  = @{
                                              UIFontDescriptorTextStyleAttribute : style
                                              };

        descriptor = [descriptor fontDescriptorByAddingAttributes:attributes];

        descriptors[UIContentSizeCategoryLarge] = descriptor;

        _fontDescriptorsByContentSizeCategoryByCustomTextStyle[style] = descriptors;
    }
}

+ (BOOL)DTK_isRegisteredTextStyle:(NSString *)textStyle
{
    if (_fontDescriptorsByContentSizeCategoryByCustomTextStyle[textStyle])
    {
        return YES;
    }

    // Also respond YES for built-in text styles
    return [[UIApplication sharedApplication].DTK_contentSizeCategories containsObject:textStyle];
}

+ (BOOL)DTK_isCustomTextStyle:(NSString *)textStyle
{
    if (_fontDescriptorsByContentSizeCategoryByCustomTextStyle[textStyle])
    {
        return YES;
    }

    return NO;
}

+ (UIFontDescriptor *)DTK_fontDescriptorByInterpolatingDescriptors:(NSMutableDictionary *)descriptorsByContentSizeCategory toContentSizeCategory:(NSString *)contentSizeCategory
{
    NSArray * contentSizeCategories = [UIApplication sharedApplication].DTK_contentSizeCategories;
    NSInteger index                 = [contentSizeCategories indexOfObject:contentSizeCategory];

    if (index != NSNotFound)
    {
        NSUInteger         numberOfContentSizes = contentSizeCategories.count;
        CGFloat            lesserSize           = -1.0f;
        CGFloat            greaterSize          = -1.0f;
        CGFloat            interpolatedSize     = 0.0f;
        NSInteger          lesserIndex          = NSNotFound;
        NSInteger          greaterIndex         = NSNotFound;
        NSString         * aContentSizeCategory;
        UIFontDescriptor * referenceDescriptor;
        UIFontDescriptor * descriptor;

        for (NSInteger i = numberOfContentSizes - 1; i >= 0; i--)
        {
            aContentSizeCategory = contentSizeCategories[i];
            descriptor           = descriptorsByContentSizeCategory[aContentSizeCategory];

            if (descriptor.pointSize)
            {
                greaterSize         = descriptor.pointSize;
                greaterIndex        = i;
                referenceDescriptor = descriptor;
                break;
            }
        }

        for (NSInteger i = 0; i < greaterIndex; i++)
        {
            aContentSizeCategory = contentSizeCategories[i];
            descriptor           = descriptorsByContentSizeCategory[aContentSizeCategory];

            if (descriptor.pointSize)
            {
                lesserSize  = descriptor.pointSize;
                lesserIndex = i;
                break;
            }
        }

        if (lesserSize < 0.0f)
        {
            if (greaterIndex > 0)
            {
                lesserIndex = greaterIndex - 1;
                lesserSize  = greaterSize - 1.0f;
            }
            else
            {
                lesserIndex  = greaterIndex;
                lesserSize   = greaterSize;
                greaterIndex = 1;
                greaterSize  = lesserSize + 1.0f;
            }
        }

        interpolatedSize = MAX(6.0f, roundf((greaterSize - lesserSize) / (greaterIndex - lesserIndex) * (index - greaterIndex) + greaterSize));
        descriptor       = [referenceDescriptor fontDescriptorWithSize:interpolatedSize];

        descriptorsByContentSizeCategory[contentSizeCategory] = descriptor;

        return descriptor;
    }

    return nil;
}

+ (UIFontDescriptor *)DTK_preferredFontDescriptorWithCustomTextStyle:(NSString *)style
{
    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        NSMutableDictionary * fontDescriptorsByContentSizeCategory = _fontDescriptorsByContentSizeCategoryByCustomTextStyle[style];

        if (fontDescriptorsByContentSizeCategory)
        {
            NSString         * contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
            UIFontDescriptor * fontDescriptor      = fontDescriptorsByContentSizeCategory[contentSizeCategory];

            if (fontDescriptor)
            {
                return fontDescriptor;
            }
            else
            {
                return [self DTK_fontDescriptorByInterpolatingDescriptors:fontDescriptorsByContentSizeCategory
                                                    toContentSizeCategory:contentSizeCategory];
            }
        }
    }

    // This calls the original -preferredFontDescriptorWithTextStyle:
    return [self DTK_preferredFontDescriptorWithCustomTextStyle:style];
}

- (UIFontDescriptor *)DTK_fontDescriptorCleanedForTextStyle
{
    NSString * textStyle = self.fontAttributes[UIFontDescriptorTextStyleAttribute];

    if (textStyle && _fontDescriptorsByContentSizeCategoryByCustomTextStyle[textStyle])
    {
        UIFontDescriptor    * cleanDescriptor      = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
        NSMutableDictionary * overriddenAttributes = self.fontAttributes.mutableCopy;

        // Do not allow override of attributes that are core to the font style
        [overriddenAttributes removeObjectsForKeys:_protectedAttributesForStyledFonts];

        cleanDescriptor = [cleanDescriptor fontDescriptorByAddingAttributes:overriddenAttributes];

        return cleanDescriptor;
    }

    return self;
}

- (NSArray *)DTK_matchingFontDescriptorsWithMandatoryKeys:(NSSet *)mandatoryKeys
{
    NSString * textStyle = self.fontAttributes[UIFontDescriptorTextStyleAttribute];

    if (textStyle && _fontDescriptorsByContentSizeCategoryByCustomTextStyle[textStyle])
    {
        UIFontDescriptor * cleanDescriptor = self.DTK_fontDescriptorCleanedForTextStyle;

        // Call the original -matchingFontDescriptorsWithMandatoryKeys:
        NSArray        * matchingFontDescriptors       = [cleanDescriptor DTK_matchingFontDescriptorsWithMandatoryKeys:mandatoryKeys];
        NSMutableArray * styledMatchingFontDescriptors = [NSMutableArray arrayWithCapacity:matchingFontDescriptors.count];
        NSDictionary   * attributes = @{
                                        UIFontDescriptorTextStyleAttribute : textStyle
                                        };
        UIFontDescriptor * matchingDescriptor;
        
        for (UIFontDescriptor * descriptor in matchingFontDescriptors)
        {
            matchingDescriptor = [descriptor fontDescriptorByAddingAttributes:attributes];
            [styledMatchingFontDescriptors addObject:matchingDescriptor];
        }
        
        return styledMatchingFontDescriptors;
    }
    else
    {
        // Call the original -matchingFontDescriptorsWithMandatoryKeys:
        NSArray * matchingFontDescriptors = [self DTK_matchingFontDescriptorsWithMandatoryKeys:mandatoryKeys];
        
        return matchingFontDescriptors;
    }
}

#pragma mark - Protected Methods

+ (void)DTK_resetCustomTextStyles
{
    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        [_fontDescriptorsByContentSizeCategoryByCustomTextStyle removeAllObjects];
    }
}

@end
