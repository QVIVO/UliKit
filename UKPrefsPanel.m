//
//	UKPrefsPanel.m
//	Shovel
//
//	Created by Uli Kusterer on 30.6.2003.
//	Copyright 2003 Uli Kusterer.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

/*
		UKPrefsPanel is ridiculously easy to use: Create a tabless NSTabView,
		where the name of each tab is the name for the toolbar item, and the
		identifier of each tab is the identifier to be used for the toolbar
		item to represent it. Then create image files with the identifier as
		their names to be used as icons in the toolbar.
	
		Finally, drag UKPrefsPanel.h into the NIB with the NSTabView,
		instantiate a UKPrefsPanel and connect its tabView outlet to your
		NSTabView. When you open the window, the UKPrefsPanel will
		automatically add a toolbar to the window with all tabs represented by
		a toolbar item, and clicking an item will switch between the tab view's
		items.
*/

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import "UKPrefsPanel.h"


@implementation UKPrefsPanel

/* -----------------------------------------------------------------------------
	Constructor:
   -------------------------------------------------------------------------- */

-(id) initWithWindow:(NSWindow *)window
{
	if( self = [super initWithWindow:window] )
	{
		tabView = nil;
		itemsList = [[NSMutableDictionary alloc] init];
		imagesList = [[NSMutableDictionary alloc] init];
		heightList = [[NSMutableDictionary alloc] init];
		
		baseWindowName = [@"" retain];
		autosaveName = [@"com.ulikusterer" retain];
	}
	
	return self;
}


/* -----------------------------------------------------------------------------
	Destructor:
   -------------------------------------------------------------------------- */

-(void)	dealloc
{
	[itemsList release];
	[imagesList release];
	[heightList release];
	[baseWindowName release];
	[autosaveName release];
	
	[super dealloc];
}


/* -----------------------------------------------------------------------------
	awakeFromNib:
		This object and all others in the NIB have been created and hooked up.
		Fetch the window name so we can modify it to indicate the current
		page, and add our toolbar to the window.
		
		This method is the great obstacle to making UKPrefsPanel an NSTabView
		subclass. When the tab view's awakeFromNib method is called, the
		individual tabs aren't set up yet, meaning mapTabsToToolbar gives us an
		empty toolbar. ... bummer.
		
		If anybody knows how to fix this, you're welcome to tell me.
   -------------------------------------------------------------------------- */

-(void)	awakeFromNib
{	
	NSString*		key;
	int				index = 0;
	NSString*		wndTitle = nil;
	
	// Generate a string containing the window's title so we can display the original window title plus the selected pane:
	wndTitle = [[tabView window] title];
	if( [wndTitle length] > 0 )
	{
		[baseWindowName release];
		baseWindowName = [[NSString stringWithFormat: @"%@ : ", wndTitle] retain];
	}
	
	// Make sure our autosave-name is based on the one of our prefs window:
	[self setAutosaveName: [[tabView window] frameAutosaveName]];
	
	// Select the preferences page the user last had selected when this window was opened:
	key = [NSString stringWithFormat: @"%@.prefspanel.recentpage", autosaveName];
	index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
	if (index < [tabView numberOfTabViewItems])
	{
		[tabView selectTabViewItemAtIndex: index];
	}
	
	// Actually hook up our toolbar and the tabs:
	[self mapTabsToToolbar];
	
	[super awakeFromNib];

}


/* -----------------------------------------------------------------------------
	mapTabsToToolbar:
		Create a toolbar based on our tab control.
		
		Tab title		-   Name for toolbar item.
		Tab identifier  -	Image file name and toolbar item identifier.
   -------------------------------------------------------------------------- */

-(void) mapTabsToToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar		*toolbar =[[tabView window] toolbar];
	int				itemCount = 0,
					x = 0;
	NSTabViewItem	*currPage = nil;
	
	if( toolbar == nil )   // No toolbar yet? Create one!
		toolbar = [[[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat: @"%@.prefspanel.toolbar", autosaveName]] autorelease];
	
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	
	// Set up item list based on Tab View:
	itemCount = [tabView numberOfTabViewItems];
	
	[itemsList removeAllObjects];	// In case we already had a toolbar.
	
	for( x = 0; x < itemCount; x++ )
	{
		NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:x];
		NSString*			theIdentifier = [theItem identifier];
		NSString*			theLabel = [theItem label];
		
		[itemsList setObject:theLabel forKey:theIdentifier];
	}
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[tabView window] setToolbar: toolbar];
	
	// Set up window title:
	currPage = [tabView selectedTabViewItem];
	if ( currPage == nil )
		currPage = [tabView tabViewItemAtIndex:0];
	
	if ( currPage )
		[[tabView window] setTitle: [baseWindowName stringByAppendingString: [currPage label]]];
	
	#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
	if( [toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)] )
		[toolbar setSelectedItemIdentifier: [currPage identifier]];
	#endif
}


/* -----------------------------------------------------------------------------
	orderFrontPrefsPanel:
		IBAction to assign to "Preferences..." menu item.
   -------------------------------------------------------------------------- */

-(IBAction)		orderFrontPrefsPanel: (id)sender
{
//	[[tabView window] makeKeyAndOrderFront:sender];
	[[tabView window] makeKeyWindow];
	[[tabView window] orderFrontRegardless];
}


/* -----------------------------------------------------------------------------
	setTabView:
		Accessor for specifying the tab view to query.
   -------------------------------------------------------------------------- */

-(void)			setTabView: (NSTabView*)tv
{
	tabView = tv;
}


-(NSTabView*)   tabView
{
	return tabView;
}


/* -----------------------------------------------------------------------------
	setAutosaveName:
		Name used for saving state of prefs window.
   -------------------------------------------------------------------------- */

-(void)			setAutosaveName: (NSString*)name
{
	[name retain];
	[autosaveName release];
	autosaveName = name;
}


-(NSString*)	autosaveName
{
	return autosaveName;
}


/* -----------------------------------------------------------------------------
	toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
		Create an item with the proper image and name based on our list
		of tabs for the specified identifier.
   -------------------------------------------------------------------------- */

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem   *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSString*		itemLabel;
	
    if( (itemLabel = [itemsList objectForKey:itemIdent]) != nil )
	{
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: itemLabel];
		[toolbarItem setPaletteLabel: itemLabel];
		[toolbarItem setTag:[tabView indexOfTabViewItemWithIdentifier:itemIdent]];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: itemLabel];
		
		// Set image
		NSString *imageName = [imagesList objectForKey:itemIdent];
		if (!imageName)
		{
			imageName = itemIdent;
		}
		[toolbarItem setImage: [NSImage imageNamed:imageName]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(changePanes:)];
    }
	else
	{
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
	
    return toolbarItem;
}


/* -----------------------------------------------------------------------------
	toolbarSelectableItemIdentifiers:
		Make sure all our custom items can be selected. NSToolbar will
		automagically select the appropriate item when it is clicked.
   -------------------------------------------------------------------------- */

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
	return [itemsList allKeys];
}
#endif


/* -----------------------------------------------------------------------------
	changePanes:
		Action for our custom toolbar items that causes the window title to
		reflect the current pane and the proper pane to be shown in response to
		a click.
   -------------------------------------------------------------------------- */

-(IBAction)	changePanes: (id)sender
{
	NSString*		key;
	
	[tabView selectTabViewItemAtIndex: [sender tag]];
	[[tabView window] setTitle: [baseWindowName stringByAppendingString: [sender label]]];
	
	key = [NSString stringWithFormat: @"%@.prefspanel.recentpage", autosaveName];
	[[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:key];
}


/* -----------------------------------------------------------------------------
	toolbarDefaultItemIdentifiers:
		Return the identifiers for all toolbar items that will be shown by
		default.
		This is simply a list of all tab view items in order.
   -------------------------------------------------------------------------- */

-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	int					itemCount = [tabView numberOfTabViewItems],
						x;
	NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:0];
	//NSMutableArray*	defaultItems = [NSMutableArray arrayWithObjects: [theItem identifier], NSToolbarSeparatorItemIdentifier, nil];
	NSMutableArray*	defaultItems = [NSMutableArray array];
	
	for( x = 0; x < itemCount; x++ )
	{
		theItem = [tabView tabViewItemAtIndex:x];
		
		[defaultItems addObject: [theItem identifier]];
	}
	
	return defaultItems;
}


/* -----------------------------------------------------------------------------
	toolbarAllowedItemIdentifiers:
		Return the identifiers for all toolbar items that *can* be put in this
		toolbar. We allow a couple more items (flexible space, separator lines
		etc.) in addition to our custom items.
   -------------------------------------------------------------------------- */

-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray*		allowedItems = [[[itemsList allKeys] mutableCopy] autorelease];
	
	[allowedItems addObjectsFromArray: [NSArray arrayWithObjects: NSToolbarSeparatorItemIdentifier,
				NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarCustomizeToolbarItemIdentifier, nil] ];
	
	return allowedItems;
}


#pragma mark -
#pragma mark NSTabViewDelegate

// auto resize tabview height
- (void)tabView:(NSTabView *)_tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSLog(@"tabViewItem selected: %@", [tabViewItem label]);
	
    // current tabview height
	 NSRect frame = [[_tabView window] frame];
	NSRect viewFrame = [[tabViewItem view]frame];

	NSLog(@"view frame: {%f, %f}, {%f, %f}", viewFrame.origin.x, viewFrame.origin.y, viewFrame.size.width, viewFrame.size.height);
	
	NSString *ident = [tabViewItem identifier];
	NSLog(@"item identifier: %@", ident);
	// origin view height
	NSNumber* origHeight = [heightList objectForKey:ident];
	if (origHeight && [origHeight intValue] > 0)
	{
		int delta = NSHeight(viewFrame) - [origHeight intValue];
		frame.size.height -= delta;
		frame.origin.y += delta;
	}

	// Now set the new window frame and animate it.
	[[tabView window] setFrame:frame display:YES animate:YES];
}
@end
