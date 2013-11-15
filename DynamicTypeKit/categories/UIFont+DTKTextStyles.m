//
//  UIFont+DTKTextStyles.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/12/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "UIFont+DTKTextStyles.h"

#import "UIFontDescriptor+DTKTextStyles.h"
#import "UIFontDescriptor+DTKTextStylesProtected.h"

#import <JRSwizzle.h>
#import <objc/runtime.h>

// An associated object allowing the text style to be stored in a UIFont instance
static char DTKTextStyleAttribute;

@implementation UIFont (DTKTextStyles)

+ (void)load
{
    Class fontInstanceClass = NSClassFromString(@"UICTFont");

    NSError * error;
    BOOL      success = [self jr_swizzleClassMethod:@selector(fontWithDescriptor:size:)
                                    withClassMethod:@selector(DTK_fontWithDescriptor:size:)
                                              error:&error];

    if (!success)
    {
        // TODO error handling
    }

    success = [self jr_swizzleClassMethod:@selector(preferredFontForTextStyle:)
                          withClassMethod:@selector(DTK_preferredFontForTextStyle:)
                                    error:&error];

    if (!success)
    {
        // TODO error handling
    }

    success = [fontInstanceClass jr_swizzleMethod:@selector(fontDescriptor)
                                       withMethod:@selector(DTK_fontDescriptor)
                                            error:&error];

    if (!success)
    {
        // TODO error handling
    }

    success = [fontInstanceClass jr_swizzleMethod:@selector(fontWithSize:)
                                       withMethod:@selector(DTK_fontWithSize:)
                                            error:&error];

    if (!success)
    {
        // TODO error handling
    }
}

#pragma mark - Preservation of text style between fonts and descriptors

+ (UIFont *)DTK_fontWithDescriptor:(UIFontDescriptor *)descriptor size:(CGFloat)pointSize
{
    NSString * textStyle = descriptor.fontAttributes[UIFontDescriptorTextStyleAttribute];

    // Force any invalid style overrides to be discarded
    if (textStyle)
    {
        descriptor = descriptor.DTK_fontDescriptorCleanedForTextStyle;
    }

    // Call the original implementation to get the font
    UIFont * font = [self DTK_fontWithDescriptor:descriptor size:pointSize];

    // TODO why is this happening? Sometimes when passing 0 as the size, rather
    // than taking the size from the descriptor the font is set to pointSize 0
    if (pointSize == 0.0f)
    {
        CGFloat targetPointSize = descriptor.pointSize;

        if (font.pointSize != targetPointSize)
        {
            font = [font fontWithSize:targetPointSize];
        }
    }

    if (textStyle)
    {
        font.DTK_textStyle = textStyle;
    }

    return font;
}

+ (UIFont *)DTK_preferredFontForTextStyle:(NSString *)style
{
    // +preferredFontForTextStyle: calls +preferredFontDescriptorWithTextStyle
    // but does not pass the result through +fontWithDescriptor:size: so
    // otherwise the custom style would be lost
    if ([UIFontDescriptor DTK_isCustomTextStyle:style])
    {
        UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
        UIFont           * font       = [UIFont fontWithDescriptor:descriptor size:0.0f];

        return font;
    }
    else
    {
        // Call original preferredFontForTextStyle:
        return [self DTK_preferredFontForTextStyle:style];
    }
}

- (UIFontDescriptor *)DTK_fontDescriptor
{
    // Call original fontDescriptor then add the style attribute if necessary
    UIFontDescriptor * descriptor = [self DTK_fontDescriptor];
    NSString         * textStyle  = self.DTK_textStyle;

    if (textStyle)
    {
        NSDictionary * attributes = @{
                                      UIFontDescriptorTextStyleAttribute : textStyle
                                      };
        descriptor = [descriptor fontDescriptorByAddingAttributes:attributes];
    }

    return descriptor;
}

- (UIFont *)DTK_fontWithSize:(CGFloat)fontSize
{
    // Call +fontWithDescriptor:size: which will preserve the text style
    if (self.DTK_textStyle)
    {
        UIFontDescriptor * descriptor = self.fontDescriptor;
        UIFont           * font       = [UIFont fontWithDescriptor:descriptor size:fontSize];

        return font;
    }

    // Call original -fontWithSize:
    return [self DTK_fontWithSize:fontSize];
}

#pragma mark - Associated Objects

- (void)setDTK_textStyle:(NSString *)textStyle
{
    [self willChangeValueForKey:@"DTK_textStyle"];

    objc_setAssociatedObject(self, &DTKTextStyleAttribute,
                             textStyle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self didChangeValueForKey:@"DTK_textStyle"];
}

- (NSString *)DTK_textStyle
{
    NSString * textStyle = objc_getAssociatedObject(self, &DTKTextStyleAttribute);
    
    return textStyle;
}

@end