//
//  UIApplication+DTKTextStylesTests.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "DynamicTypeKitTestCase.h"

@interface UIApplication_DTKTextStylesTests : DynamicTypeKitTestCase

@end

@implementation UIApplication_DTKTextStylesTests

- (void)testSetPreferredContentSizeCategory
{
   UIApplication * application = [UIApplication sharedApplication];
   NSString * newPreferredContentSizeCategory = UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;

   application.DTK_preferredContentSizeCategory = newPreferredContentSizeCategory;

   assertThat(application.preferredContentSizeCategory, equalTo(newPreferredContentSizeCategory));
}

- (void)testSetInvalidPreferredContentSizeCategory
{
   UIApplication * application = [UIApplication sharedApplication];
   NSString * preferredContentSizeCategory = application.preferredContentSizeCategory;
   NSString * newPreferredContentSizeCategory = @"Not a real content size category";

   application.DTK_preferredContentSizeCategory = newPreferredContentSizeCategory;

   assertThat(application.preferredContentSizeCategory, equalTo(preferredContentSizeCategory));
}

- (void)testSetPreferredContentSizeCategoryAffectsSystemTextStyleSize
{
   UIApplication * application = [UIApplication sharedApplication];
   NSString * textStyle = UIFontTextStyleBody;
   NSString * newPreferredContentSizeCategory = UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;
   UIFont * fontWithDefaultSizeCategory = [UIFont preferredFontForTextStyle:textStyle];

   application.DTK_preferredContentSizeCategory = newPreferredContentSizeCategory;

   UIFont * fontWithCustomSizeCategory = [UIFont preferredFontForTextStyle:textStyle];

   NSLog(@"SIZE %f", fontWithCustomSizeCategory.pointSize);

   assertThat(@(fontWithDefaultSizeCategory.pointSize), lessThan(@(fontWithCustomSizeCategory.pointSize)));
}

- (void)testSetPreferredContentSizeCategoryAffectsCustomTextStyleSize
{
   [self registerABCTextStyles];

   UIApplication * application = [UIApplication sharedApplication];
   NSString * textStyle = @"A";
   NSString * newPreferredContentSizeCategory = UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;
   UIFont * fontWithDefaultSizeCategory = [UIFont preferredFontForTextStyle:textStyle];

   application.DTK_preferredContentSizeCategory = newPreferredContentSizeCategory;

   UIFont * fontWithCustomSizeCategory = [UIFont preferredFontForTextStyle:textStyle];

   assertThat(@(fontWithDefaultSizeCategory.pointSize), lessThan(@(fontWithCustomSizeCategory.pointSize)));
}

@end
