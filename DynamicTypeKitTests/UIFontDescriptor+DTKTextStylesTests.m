//
//  UIFontDescriptor+DTKTextStylesTests.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "DynamicTypeKitTestCase.h"

#import "UIFontDescriptor+DTKTextStyles.h"
#import "UIFontDescriptor+DTKTextStylesProtected.h"

@interface UIFontDescriptor_DTKTextStylesTests : DynamicTypeKitTestCase
@end

@implementation UIFontDescriptor_DTKTextStylesTests

#pragma mark - Text Styles

- (void)testPreferredFontDescriptorWithSystemTextStyle
{
   [self registerABCTextStyles];

   NSString * textStyle = UIFontTextStyleBody;
   NSString * fontNamePrefix = @".";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   NSDictionary * fontAttributes = descriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStyle
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   NSDictionary * fontAttributes = descriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStylePreservedAcrossInnocuousAttributeChanges
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   NSDictionary * attributes = @{UIFontDescriptorSizeAttribute : @99.0f};
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   UIFontDescriptor * derivedDescriptor = [descriptor fontDescriptorByAddingAttributes:attributes];
   NSDictionary * fontAttributes = derivedDescriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStylePreservedAcrossUnsatisfiableAttributeChanges
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   NSDictionary * attributes = @{UIFontDescriptorFamilyAttribute : @"Not a Font Family @#&^@#"};
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   UIFontDescriptor * derivedDescriptor = [descriptor fontDescriptorByAddingAttributes:attributes];
   NSDictionary * fontAttributes = derivedDescriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStylePreservedAcrossTraitChanges
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   UIFontDescriptor * derivedDescriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | UIFontDescriptorTraitBold];
   NSDictionary * fontAttributes = derivedDescriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

#pragma mark Matching styles to supported fonts

- (void)testPreferredFontDescriptorWithCustomTextStylePreservedAcrossMatching
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   NSArray * matchingDescriptors = [descriptor matchingFontDescriptorsWithMandatoryKeys:nil];

   for (UIFontDescriptor * matchingDescriptor in matchingDescriptors)
   {
      NSDictionary * fontAttributes = matchingDescriptor.fontAttributes;

      assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
      assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
   }
}

- (void)testPreferredFontDescriptorWithCustomTextStyleDropsConflictingAttributesUponMatching
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   UIFontDescriptor * conflictingDescriptor = [descriptor fontDescriptorWithFamily:@"Helvetica"];
   NSArray * matchingDescriptors = [conflictingDescriptor matchingFontDescriptorsWithMandatoryKeys:nil];

   for (UIFontDescriptor * matchingDescriptor in matchingDescriptors)
   {
      NSDictionary * fontAttributes = matchingDescriptor.fontAttributes;

      assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
      assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
   }
}

- (void)testPreferredFontDescriptorWithCustomTextStylePreservedAcrossFontCreation
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   UIFont * matchingFont = [UIFont fontWithDescriptor:descriptor size:0.0f];
   UIFontDescriptor * matchingDescriptor = matchingFont.fontDescriptor;
   NSDictionary * fontAttributes = matchingDescriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

- (void)testPreferredFontDescriptorWithCustomTextStyleDropsConflictingAttributesUponFontCreation
{
   [self registerABCTextStyles];

   NSString * textStyle = @"A";
   NSString * fontNamePrefix = @"A";
   UIFontDescriptor * descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
   UIFontDescriptor * conflictingDescriptor = [descriptor fontDescriptorWithFamily:@"Helvetica"];
   UIFont * matchingFont = [UIFont fontWithDescriptor:conflictingDescriptor size:0.0f];
   UIFontDescriptor * matchingDescriptor = matchingFont.fontDescriptor;
   NSDictionary * fontAttributes = matchingDescriptor.fontAttributes;

   assertThat(fontAttributes[UIFontDescriptorTextStyleAttribute], equalTo(textStyle));
   assertThat(fontAttributes[UIFontDescriptorNameAttribute], startsWith(fontNamePrefix));
}

#pragma mark - Interpolation tests

- (void)testInterpolationToLessThanNormalSize
{
    [self registerABCTextStyles];

    NSString * textStyle = @"A";
    UIApplication * application = [UIApplication sharedApplication];
    UIFontDescriptor * beforeDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];

    application.DTK_preferredContentSizeCategory = UIContentSizeCategoryExtraSmall;

    UIFontDescriptor * afterDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];

    assertThat(@(afterDescriptor.pointSize), lessThan(@(beforeDescriptor.pointSize)));
    assertThat(@(afterDescriptor.pointSize), greaterThan(@0));
}

@end
