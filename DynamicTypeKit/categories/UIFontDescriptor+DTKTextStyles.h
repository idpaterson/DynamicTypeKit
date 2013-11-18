//
//  UIFontDescriptor+DTKTextStyles.h
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFontDescriptor (DTKTextStyles)

+ (void)DTK_registerFontDescriptors:(NSDictionary *)descriptorsByContentSizeCategory forCustomTextStyle:(NSString *)style;
+ (void)DTK_registerFontDescriptor:(UIFontDescriptor *)descriptor withPointSizes:(NSDictionary *)pointSizesByContentSizeCategory forCustomTextStyle:(NSString *)style;
+ (void)DTK_registerFontDescriptor:(UIFontDescriptor *)descriptor forCustomTextStyle:(NSString *)style;

+ (BOOL)DTK_isRegisteredTextStyle:(NSString *)textStyle;
+ (BOOL)DTK_isCustomTextStyle:(NSString *)textStyle;

#pragma mark - UIWebView support
/// @name      UIWebView support

/// Updates the CSS of the current page to reflect all available custom text
/// styles at the current preferred content size.
///
/// There is a lot of magic in `font: -apple-system-headline`, most of which has
/// been reproduced here. `DTKDynamicTypeManager` will call this whenever the
/// font size changes to ensure that the new sizes are adopted, but it is the
/// developer's responsibility to call it whenever a page requiring the custom
/// text styles is loaded.
///
/// The process of updating the text size involves updating in-memory style
/// sheets, no changes are made to HTML and there are no special class names
/// needed. Any CSS rule specifying @font-family: a-custom-text-style@ will
/// automatically be updated according to the normal inheritance rules of CSS.
///
/// @param webView A web view that is ready to receive JavaScript commands; that
/// is, `document.readyState` is either `interactive` or `completed`.
///
/// @see updateFontsInViewsForPreferredContentSizeCategory:
+ (void)DTK_updateCSSForPreferredContentSizeCategoryInWebView:(UIWebView *)webView;

@end
