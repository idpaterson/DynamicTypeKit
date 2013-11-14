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

@end
