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
    // FIXME: find whether there are any attributes that could not be modified
    // by adding traits or other harmless modifications. The idea is to avoid
    // switching to an entirely different font.
    _protectedAttributesForStyledFonts = @[];
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

#pragma mark - UIWebView support

+ (NSString *)DTK_cssFontFaceDeclarationsForCustomTextStylesForPreferredContentSizeCategory
{
    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        NSMutableArray * allValues = [NSMutableArray arrayWithCapacity:_fontDescriptorsByContentSizeCategoryByCustomTextStyle.count];
        NSString * contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
        UIFontDescriptor * descriptor;

        for (NSDictionary * fontDescriptorsByContentSizeCategory in _fontDescriptorsByContentSizeCategoryByCustomTextStyle.allValues)
        {
            descriptor = fontDescriptorsByContentSizeCategory[contentSizeCategory];

            [allValues addObject:descriptor.DTK_cssFontFaceDeclaration];
        }
        
        return [allValues componentsJoinedByString:@""];
    }
}

+ (NSString *)DTK_cssFontFaceDeclarationForFontDescriptor:(UIFontDescriptor *)descriptor
{
    UIFontDescriptor * matchingDescriptor = [descriptor matchingFontDescriptorsWithMandatoryKeys:nil].firstObject;
    NSMutableArray * cssDescriptors = [NSMutableArray array];
    NSDictionary * fontAttributes = matchingDescriptor.fontAttributes;
    UIFontDescriptorSymbolicTraits symbolicTraits = matchingDescriptor.symbolicTraits;
    NSString * value;
    NSString * cssDescriptor;

    // The name by which to represent the font in CSS
    value = fontAttributes[UIFontDescriptorTextStyleAttribute];
    if (value)
    {
        cssDescriptor = [NSString stringWithFormat:@"font-family:\"%@\"", value];
        [cssDescriptors addObject:cssDescriptor];
    }

    // The system name for the font
    value = fontAttributes[UIFontDescriptorNameAttribute];
    if (value)
    {
        cssDescriptor = [NSString stringWithFormat:@"src:local(\"%@\")", value];
        [cssDescriptors addObject:cssDescriptor];
    }

    if ((symbolicTraits & UIFontDescriptorTraitBold) != 0)
    {
        cssDescriptor = @"font-weight:bold";
        [cssDescriptors addObject:cssDescriptor];
    }

    if ((symbolicTraits & UIFontDescriptorTraitItalic) != 0)
    {
        cssDescriptor = @"font-style:italic";
        [cssDescriptors addObject:cssDescriptor];
    }

    if ((symbolicTraits & UIFontDescriptorTraitCondensed) != 0)
    {
        cssDescriptor = @"font-stretch:condensed";
        [cssDescriptors addObject:cssDescriptor];
    }
    else if ((symbolicTraits & UIFontDescriptorTraitExpanded) != 0)
    {
        cssDescriptor = @"font-stretch:expanded";
        [cssDescriptors addObject:cssDescriptor];
    }

    return [NSString stringWithFormat:@"@font-face {%@;}", [cssDescriptors componentsJoinedByString:@";"]];
}

- (NSString *)DTK_cssFontFaceDeclaration
{
    NSMutableSet * variations = [NSMutableSet set];
    Class fontDescriptorClass = [self class];
    UIFontDescriptor * fontDescriptor;
    NSString * cssFontFaceDeclaration;

    fontDescriptor = [self fontDescriptorWithSymbolicTraits:0];
    cssFontFaceDeclaration = [fontDescriptorClass DTK_cssFontFaceDeclarationForFontDescriptor:fontDescriptor];
    [variations addObject:cssFontFaceDeclaration];

    fontDescriptor = [self fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    cssFontFaceDeclaration = [fontDescriptorClass DTK_cssFontFaceDeclarationForFontDescriptor:fontDescriptor];
    [variations addObject:cssFontFaceDeclaration];

    fontDescriptor = [self fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    cssFontFaceDeclaration = [fontDescriptorClass DTK_cssFontFaceDeclarationForFontDescriptor:fontDescriptor];
    [variations addObject:cssFontFaceDeclaration];

    fontDescriptor = [self fontDescriptorWithSymbolicTraits:(UIFontDescriptorTraitBold |
                                                             UIFontDescriptorTraitItalic)];
    cssFontFaceDeclaration = [fontDescriptorClass DTK_cssFontFaceDeclarationForFontDescriptor:fontDescriptor];
    [variations addObject:cssFontFaceDeclaration];

    return [variations.allObjects componentsJoinedByString:@""];
}

+ (NSArray *)DTK_cssFontRuleValuesForCustomTextStylesForPreferredContentSizeCategory
{
    @synchronized(_fontDescriptorsByContentSizeCategoryByCustomTextStyle)
    {
        NSMutableArray * allValues = [NSMutableArray arrayWithCapacity:_fontDescriptorsByContentSizeCategoryByCustomTextStyle.count];
        NSString * contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
        UIFontDescriptor * descriptor;

        for (NSMutableDictionary * fontDescriptorsByContentSizeCategory in _fontDescriptorsByContentSizeCategoryByCustomTextStyle.allValues)
        {
            descriptor = fontDescriptorsByContentSizeCategory[contentSizeCategory];

            if (!descriptor)
            {
                descriptor = [self DTK_fontDescriptorByInterpolatingDescriptors:fontDescriptorsByContentSizeCategory
                                                          toContentSizeCategory:contentSizeCategory];
            }

            [allValues addObject:descriptor.DTK_cssFontRuleValuesForPreferredContentSizeCategory];
        }

        return allValues;
    }
}

- (NSDictionary *)DTK_cssFontRuleValuesForPreferredContentSizeCategory
{
    NSMutableDictionary * cssFontRuleValues = [NSMutableDictionary new];
    UIFontDescriptorSymbolicTraits symbolicTraits = self.symbolicTraits;
    NSDictionary * fontAttributes = self.fontAttributes;
    NSString * value;

    // The name by which to represent the font in CSS
    value = fontAttributes[UIFontDescriptorTextStyleAttribute];
    if (value)
    {
        cssFontRuleValues[@"textStyle"] = value;
    }

    // The system name for the font
    value = fontAttributes[UIFontDescriptorNameAttribute];
    if (value)
    {
        cssFontRuleValues[@"fontFamily"] = value;
    }

    cssFontRuleValues[@"fontSize"] = [NSString stringWithFormat:@"%.0fpx", self.pointSize];

    if ((symbolicTraits & UIFontDescriptorTraitBold) != 0)
    {
        cssFontRuleValues[@"fontWeight"] = @"bold";
    }

    if ((symbolicTraits & UIFontDescriptorTraitItalic) != 0)
    {
        cssFontRuleValues[@"fontStyle"] = @"italic";
    }

    if ((symbolicTraits & UIFontDescriptorTraitCondensed) != 0)
    {
        cssFontRuleValues[@"fontStretch"] = @"condensed";
    }
    else if ((symbolicTraits & UIFontDescriptorTraitExpanded) != 0)
    {
        cssFontRuleValues[@"fontStretch"] = @"expanded";
    }

    return cssFontRuleValues;
}

+ (void)DTK_updateCSSForPreferredContentSizeCategoryInWebView:(UIWebView *)webView
{
    NSArray * cssFontRuleValues = [self DTK_cssFontRuleValuesForCustomTextStylesForPreferredContentSizeCategory];
    NSData * cssFontRuleValuesJSON = [NSJSONSerialization dataWithJSONObject:cssFontRuleValues options:0 error:NULL];
    NSString * cssFontFaceDeclarations = [self DTK_cssFontFaceDeclarationsForCustomTextStylesForPreferredContentSizeCategory];

    // Closure compiled, see support/webViewFontManager.js
    NSString * command = [NSString stringWithFormat:@"(function(p,q){function r(){var e=document.styleSheets;m=e.length;for(var f=0;f<e.length;f++){"
                          "var g=e[f].cssRules;if(g)for(var h=0;h<g.length;h++){var a=g[h];if(a.style){a.DTK_originalStyle||(a.DTK_originalStyle="
                          "{fontWeight:a.style.fontWeight,fontStyle:a.style.fontStyle,fontStretch:a.style.fontStretch});var d=a.DTK_originalStyle,"
                          "k=a.style.font,l=a.style.fontFamily;(k||l)&&p.forEach(function(b){if(k&&0<=k.indexOf(b.textStyle)||l&&0<=l.indexOf(b.textStyle))"
                          "return 0>a.cssText.indexOf('@font-face')&&['fontWeight','fontStyle','fontStretch','fontSize'].forEach(function(c){!d[c]&&"
                          "c in b&&(a.style[c]=b[c])}),!1})}}}}function d(){document.styleSheets.length>m&&r();'completed'!=document.readyState&&"
                          "setTimeout(d,20)}var n=document.createElement('style');n.innerText=q;document.getElementsByTagName('head')[0].appendChild(n);"
                          "var m=0;d()})(%@,'%@');",
                          [[NSString alloc] initWithData:cssFontRuleValuesJSON encoding:NSUTF8StringEncoding],
                          cssFontFaceDeclarations];

    [webView stringByEvaluatingJavaScriptFromString:command];
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
