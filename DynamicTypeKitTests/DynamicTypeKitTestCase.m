//
//  DynamicTypeKitTestCase.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/13/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "DynamicTypeKitTestCase.h"

#import "UIFontDescriptor+DTKTextStylesProtected.h"

@implementation DynamicTypeKitTestCase

- (void)registerABCTextStyles
{
    NSString * aFontName  = @"Avenir";
    NSString * aTextStyle = @"A";
    NSString * bFontName  = @"Baskerville";
    NSString * bTextStyle = @"B";
    NSString * cFontName  = @"Cochin";
    NSString * cTextStyle = @"C";

    [UIFontDescriptor DTK_registerFontDescriptor:[UIFontDescriptor fontDescriptorWithName:aFontName size:16.0f]
                              forCustomTextStyle:aTextStyle];
    [UIFontDescriptor DTK_registerFontDescriptor:[UIFontDescriptor fontDescriptorWithName:bFontName size:16.0f]
                              forCustomTextStyle:bTextStyle];
    [UIFontDescriptor DTK_registerFontDescriptor:[UIFontDescriptor fontDescriptorWithName:cFontName size:16.0f]
                              forCustomTextStyle:cTextStyle];
}

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [UIFontDescriptor DTK_resetCustomTextStyles];
    [UIApplication sharedApplication].DTK_preferredContentSizeCategory = nil;

    [super tearDown];
}

@end
