//
//  DTKDynamicTypeManager.m
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/8/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "DTKDynamicTypeManager.h"

#import "UIApplication+DTKTextStyles.h"

#define getPreferredContentSizeCategory() [UIApplication sharedApplication].preferredContentSizeCategory

@implementation DTKDynamicTypeManager

+ (id)sharedManager
{
    // Thread-safe singleton
    static DTKDynamicTypeManager * sharedManager = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedManager = [[DTKDynamicTypeManager alloc] init];
    });

    return sharedManager;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _preferredContentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    }

    return self;
}

- (void)setTrackingDynamicType:(BOOL)trackingDynamicType
{
    [self willChangeValueForKey:@"trackingDynamicType"];
    _trackingDynamicType = trackingDynamicType;
    [self didChangeValueForKey:@"trackingDynamicType"];
}

- (void)beginTrackingDynamicType
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferredContentSizeDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    // If tracking was paused, the content size may have changed. Make sure that
    // the view hierarchy is up-to-date with the current content size.
    [self preferredContentSizeDidChange:nil];

    self.trackingDynamicType = YES;
}

- (void)endTrackingDynamicType
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];

    self.trackingDynamicType = NO;
}

- (void)dealloc
{
    [self endTrackingDynamicType];
}


#pragma mark - View Management

- (UIFont *)fontByUpdatingDynamicTypeFontIfNecessary:(UIFont *)font
{
    UIFontDescriptor    * fontDescriptor = font.fontDescriptor;
    NSMutableDictionary * fontAttributes = fontDescriptor.fontAttributes.mutableCopy;
    NSString            * textStyle      = fontDescriptor.fontAttributes[UIFontDescriptorTextStyleAttribute];

    if (textStyle)
    {
        UIFontDescriptor * newFontDescriptor;

        [fontAttributes removeObjectForKey:UIFontDescriptorSizeAttribute];

        newFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
        newFontDescriptor = [newFontDescriptor fontDescriptorByAddingAttributes:fontAttributes];
        newFontDescriptor = [newFontDescriptor fontDescriptorWithSymbolicTraits:fontDescriptor.symbolicTraits];

        return [UIFont fontWithDescriptor:newFontDescriptor size:0.0f];
    }

    return font;
}

- (void)updateFontsInViewsForPreferredContentSizeCategory:(NSArray *)views
{
    NSMutableArray     * viewsQueue          = [NSMutableArray arrayWithArray:views];
    UIApplication      * application         = [UIApplication sharedApplication];
    NSString           * contentSizeCategory = application.preferredContentSizeCategory;
    Class                labelClass          = [UILabel class];
    Class                textFieldClass      = [UITextField class];
    Class                textViewClass       = [UITextView class];
    Class                tableViewClass      = [UITableView class];
    Class                collectionViewClass = [UICollectionView class];
    Class                tableViewCellClass  = [UITableViewCell class];
    Class                buttonClass         = [UIButton class];
    Class                webViewClass        = [UIWebView class];
    Class                viewClass;
    id                   view;
    NSArray            * subviews;
    UIFont             * font;
    UIFont             * newFont;
    NSAttributedString * attributedText;
    NSNumber           * contentSizeMultiplier;
    NSNumber           * contentSizeDistanceFromDefault;

    // Records the size category for the most recent layout
    _preferredContentSizeCategory = contentSizeCategory;

    if ([_delegate respondsToSelector:@selector(dynamicTypeManager:willUpdateContentSizeInViews:)])
    {
        [_delegate dynamicTypeManager:self willUpdateContentSizeInViews:views];
    }

    // Perform a breadth-first traversal of the view hierarchy
    while ((view = viewsQueue.firstObject))
    {
        [viewsQueue removeObjectAtIndex:0];

        viewClass = [view class];
        subviews  = [view subviews];

        // Classes that support -font and -setFont:
        if ([viewClass isSubclassOfClass:labelClass] ||
            [viewClass isSubclassOfClass:textFieldClass] ||
            [viewClass isSubclassOfClass:textViewClass])
        {
            font           = [view font];
            attributedText = [view attributedText];

            if (attributedText)
            {
                NSMutableAttributedString * newAttributedText = attributedText.mutableCopy;
                __block BOOL                didChangeFont     = NO;

                [attributedText enumerateAttributesInRange:NSMakeRange(0, attributedText.length)
                                                   options:0
                                                usingBlock:^(NSDictionary * attrs, NSRange range, BOOL * stop) {
                                                    UIFont * font = attrs[NSFontAttributeName];
                                                    UIFont * newFont = [self fontByUpdatingDynamicTypeFontIfNecessary:font];

                                                    if (![font isEqual:newFont])
                                                    {
                                                        NSMutableDictionary * newAttributes = attrs.mutableCopy;

                                                        newAttributes[NSFontAttributeName] = newFont;

                                                        [newAttributedText setAttributes:newAttributes range:range];
                                                        didChangeFont = YES;
                                                    }
                                                }];

                if (didChangeFont)
                {
                    [view setAttributedText:newAttributedText];

                    [view invalidateIntrinsicContentSize];
                    [view setNeedsLayout];
                }
            }
            else
            {
                newFont = [self fontByUpdatingDynamicTypeFontIfNecessary:font];

                if (![font isEqual:newFont])
                {
                    [view setFont:newFont];

                    [view invalidateIntrinsicContentSize];
                    [view setNeedsLayout];
                }
            }
        }
        else if ([viewClass isSubclassOfClass:buttonClass])
        {
            UILabel * titleLabel = [view titleLabel];

            titleLabel.font = [self fontByUpdatingDynamicTypeFontIfNecessary:titleLabel.font];

            [titleLabel sizeToFit];
            [view sizeToFit];
            [view invalidateIntrinsicContentSize];
            [view setNeedsLayout];
        }
        else if ([viewClass isSubclassOfClass:tableViewCellClass])
        {
            // Standard UITableViewCells do not handle text size changes
            // automatically.
            [view setNeedsLayout];
        }
        else if ([viewClass isSubclassOfClass:tableViewClass] ||
                 [viewClass isSubclassOfClass:collectionViewClass])
        {
            // IMPORTANT: This is not for the sake of re-rendering the cells. A
            // table or collection view will usually have cells in a reuse queue
            // that are in no way accessible at this time. Every table or
            // collection view data source must set any font properties upon
            // reconfiguring the cell in order to adapt to changes in type size.
            // Instead, this allows the view to update its metrics such as cell
            // dimensions.
            [view reloadData];
        }
        else if ([viewClass isSubclassOfClass:webViewClass])
        {
            if (!contentSizeMultiplier)
            {
                contentSizeMultiplier          = @(application.DTK_preferredContentSizeCategoryStandardFontSizeMultiplier);
                contentSizeDistanceFromDefault = @(application.DTK_preferredContentSizeCategoryDistanceFromDefault);
            }

            NSDictionary * eventDetails = @{
                                            @"contentSizeCategory" : contentSizeCategory,
                                            @"contentSizeDistanceFromDefault" : contentSizeDistanceFromDefault,
                                            @"contentSizeMultiplier" : contentSizeMultiplier
                                            };
            NSData * detailsJSON = [NSJSONSerialization dataWithJSONObject:@{ @"detail" : eventDetails }
                                                                   options:0 error:NULL];
            NSString * command = [NSString stringWithFormat:@"document.body.dispatchEvent(new CustomEvent('contentsizecategorychange', %@));",
                                  [[NSString alloc] initWithData:detailsJSON encoding:NSUTF8StringEncoding]];

            [view stringByEvaluatingJavaScriptFromString:command];
        }

        if (subviews.count > 0)
        {
            [viewsQueue addObjectsFromArray:[view subviews]];
        }
    }
}

- (NSArray *)rootWindows
{
    NSMutableArray * rootWindows            = [NSMutableArray array];
    NSArray        * allWindows             = [UIApplication sharedApplication].windows;
    Class            textEffectsWindowClass = NSClassFromString(@"UITextEffectsWindow");

    for (UIWindow * window in allWindows)
    {
        // Keyboard
        if (![window isKindOfClass:textEffectsWindowClass])
        {
            [rootWindows addObject:window];
        }
    }

    return rootWindows;
}

#pragma mark - NSNotificationCenter notifications

- (void)preferredContentSizeDidChange:(NSNotification *)notification
{
    // The content size may change multiple times. If it changes back to the same
    // size for which the layout was prepared, there is no need to update the
    // layout.
    NSString * newPreferredContentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    
    _needsUpdate = ![_preferredContentSizeCategory isEqualToString:newPreferredContentSizeCategory];
    
    // Just in case future iOS versions allow the text size to be changed in-app
    // or from the control panel, update the layout immediately.
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self willEnterForeground];
        });
    }
}

- (void)willEnterForeground
{
    if (_needsUpdate)
    {
        NSArray  * rootViews;
        
        if ([_delegate respondsToSelector:@selector(rootViewsForDynamicTypeManager:)])
        {
            rootViews = [_delegate rootViewsForDynamicTypeManager:self];
        }
        else
        {
            rootViews = [self rootWindows];
        }
        
        _needsUpdate = NO;
        
        [self updateFontsInViewsForPreferredContentSizeCategory:rootViews];
    }
}

@end