//
//  UIApplication+DTKTextStyles.h
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Provides modification of the `preferredContentSizeCategory` and a few
/// utilities to facilitate working with the values of that property.

@interface UIApplication (DTKTextStyles)

#pragma mark - Working with content size categories
/// @name      Working with content size categories

/// Provides a numeric context to content sizes relative to the default size,
/// `UIContentSizeCategoryLarge`.
///
/// The "distance" is not in relation to the specific font size but rather the
/// number of categories between the application's current content size and the
/// default size. For example, `UIContentSizeCategoryMedium` will return `-1`
/// because it is one size smaller than the default.
/// `UIContentSizeCategoryAccessibilityExtraExtraExtraLarge`, the largest size,
/// will return `8`, and the default `UIContentSizeCategoryLarge` will return
/// `0`.
///
/// @return An integer in the range [-3, 8]
- (NSInteger)DTK_preferredContentSizeCategoryDistanceFromDefault;

/// Calculates and returns the ratio of the system body style font in the
/// current preferred content size category compared to the size in the default
/// content size category.
///
/// @return A ratio in the range (0,), in practice ranging from to.
- (CGFloat)DTK_preferredContentSizeCategoryStandardFontSizeMultiplier;

/// Provides access to the `UIContentSizeCategory*` values in ascending order.
///
/// @return An array of all `UIContentSizeCategory*` strings.
- (NSArray *)DTK_contentSizeCategories;

/// Aids in determining whether the provided content size category is one of the
/// accessibility sizes.
///
/// @param contentSizeCategory A `UIContentSizeCategory*` string.
///
/// @return `YES` if the size is `UIContentSizeCategoryAccessibilityMedium` or
/// larger.
- (BOOL)DTK_isContentSizeCategorySizedForAccessibility:(NSString *)contentSizeCategory;

#pragma mark - Modifying the preferredContentSizeCategory
/// @name      Modifying the preferredContentSizeCategory

/// Allows the preferredContentSizeCategory to be overridden by the app. Set to
/// `nil` to reset to the system default.
///
/// This has the same effect as the user changing the content size within
/// Settings.app, except that its scope is limited to your application. The
/// intention is to allow apps that have legitimate reasons to allow the user to
/// adjust the font size to do so in a way that does not require a secondary
/// implementation in addition to supporting Dynamic Type.
///
/// Upon setting the `preferredContentSizeCategory`, the standard
/// `UIContentSizeCategoryDidChangeNotification` notification is posted on the
/// main thread, allowing the UI to immediately react to the change.
///
/// @param preferredContentSizeCategory A `UIContentSizeCategory*` string
- (void)setDTK_preferredContentSizeCategory:(NSString *)preferredContentSizeCategory;

@end
