//
//  UIFont+DTKTextStylesTests.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "DynamicTypeKitTestCase.h"

@interface UIFont_DTKTextStylesTests : DynamicTypeKitTestCase

@end

@implementation UIFont_DTKTextStylesTests

#pragma mark - Text Styles

- (void)testPreferredFontWithSystemTextStyle
{
   [self registerABCTextStyles];

   NSString * textStyle = UIFontTextStyleBody;
   NSString * fontNamePrefix = @".";
   UIFont * font = [UIFont preferredFontForTextStyle:textStyle];

   assertThat(font.fontName, startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStyle
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFont * font = [UIFont preferredFontForTextStyle:textStyle];

   assertThat(font.fontName, startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStylePreservedAcrossSizeChanges
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFont * font = [UIFont preferredFontForTextStyle:textStyle];
   UIFont * derivedFont = [font fontWithSize:99.0f];

   assertThat(derivedFont.fontName, startsWith(fontNamePrefix));
}

@end
