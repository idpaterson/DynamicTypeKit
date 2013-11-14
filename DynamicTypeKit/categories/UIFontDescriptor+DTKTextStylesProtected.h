//
//  UIFontDescriptor+DTKTextStylesProtected.h
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIFontDescriptor (DTKTextStylesProtected)

#pragma mark - Protected methods
/// @name      Protected methods

/// Clears any custom text styles that have been registered with
/// `UIFontDescriptor`.
+ (void)DTK_resetCustomTextStyles;

/// Given a styled font descriptor, provides a descriptor that enforces a few
/// attributes that define the text style, such as font name and size.
///
/// @return A font descriptor conforming to its style
- (UIFontDescriptor *)DTK_fontDescriptorCleanedForTextStyle;

@end
