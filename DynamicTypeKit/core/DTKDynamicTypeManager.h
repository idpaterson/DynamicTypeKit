//
//  DTKDynamicTypeManager.h
//  DynamicTypeKit
//
//  Created by Ian Paterson on 11/8/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UIFont+DTKTextStyles.h"
#import "UIFontDescriptor+DTKTextStyles.h"

@protocol DTKDynamicTypeManagerDelegate;

/// Monitors the user's preferred content size, providing automatic support for
/// updating fonts and layout throughout the application. 

@interface DTKDynamicTypeManager : NSObject
{
@private
    BOOL       _needsUpdate;
    NSString * _preferredContentSizeCategory;
}

/// Returns the shared `DTKDynamicTypeManager` instance responsible for
/// monitoring important events related to Dynamic Type.
///
/// It is generally a good idea to call <beginTrackingDynamicType> on the shared
/// instance upon app startup; it is not called automatically.
///
/// @return the shared `DTKDynamicTypeManager` instance
+ (instancetype)sharedManager;

/// The delegate can be notified of important events in Dynamic Type handling
/// and may also participate in the process of updating the UI.
@property (nonatomic, weak) id<DTKDynamicTypeManagerDelegate> delegate;

/// Provides access to whether the manager is currently tracking changes in the
/// user's preferred content size.
@property (nonatomic, assign, readonly, getter = isTrackingDynamicType) BOOL trackingDynamicType;

/// Causes the app to observe the notifications that are emitted due to changes
/// in the user's preferred content size.
///
/// If the preferred content size changed while tracking was disabled, calling
/// `beginTrackingDynamicType` will immediately update the UI for the new size.
- (void)beginTrackingDynamicType;

/// Causes the app to stop observing the notifications that are emitted due to
/// changes in the user's preferred content size.
///
/// After calling this method the UI will no longer automatically update when
/// the preferred content size changes. However, any new fonts created after
/// changing the preferred content size will reflect the new size, regardless
/// of whether `DTKDynamicTypeManager` is tracking.
- (void)endTrackingDynamicType;

/// Updates fonts associated with views or attributed strings among all
/// descendants of the provided views for any fonts that use a text style.
///
/// While this method provides the mechanism by which text throughout the app
/// is updated, it is also a convenient way to show a preview of text changes
/// before they are applied. Simply call <endTrackingDynamicType>, allow the
/// user to change the font size, then call
/// `updateFontsInViewsForPreferredContentSizeCategory:` with a view that shows
/// a text preview. Be sure to call `beginTrackingDynamicType` after confirming
/// the change to update the font size throughout the app.
///
/// Do not observe the `UIContentSizeCategoryDidChangeNotification` notification
/// and call this method as a result of it. That is done automatically by asking
/// the shared manager instance to <beginTrackingDynamicType>. This is
/// specifically for use between calls to <endTrackingDynamicType> and
/// <beginTrackingDynamicType>.
///
/// @param views An array of top-level views or windows, the descendants of
/// which will be updated to match the current preferred content size category.
- (void)updateFontsInViewsForPreferredContentSizeCategory:(NSArray *)views;

@end

/// The delegate can be notified of important events in Dynamic Type handling
/// and may also participate in the process of updating the UI.

@protocol DTKDynamicTypeManagerDelegate <NSObject>

@optional

/// Called prior to making any changes to the descendants of the specified
/// views, whether in response to a change in the preferred content size or
/// manual invocation of <updateFontsInViewsForPreferredContentSizeCategory:>.
///
/// @param manager the dynamic type manager
/// @param views   An array of top-level views or windows, the descendants of
/// which will be updated to match the current preferred content size category.
///
/// @see updateFontsInViewsForPreferredContentSizeCategory:
- (void)dynamicTypeManager:(DTKDynamicTypeManager *)manager willUpdateContentSizeInViews:(NSArray *)views;

/// Allows customization of the views (or windows) that are updated when a
/// change to the preferred content size is detected.
///
/// @param manager the dynamic type manager
///
/// @return An array of top-level views or windows, the descendants of which
/// will be updated to match the current preferred content size category.
///
/// @see updateFontsInViewsForPreferredContentSizeCategory:
- (NSArray *)rootViewsForDynamicTypeManager:(DTKDynamicTypeManager *)manager;

@end