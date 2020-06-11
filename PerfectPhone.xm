#import "PerfectPhone.h"
#import <Cephei/HBPreferences.h>

static HBPreferences *pref;
static BOOL enabled;
static BOOL showExactTimeInRecentCalls;
static long defaultTab;
static BOOL hideFavourites;
static BOOL hideRecents;
static BOOL hideContacts;
static BOOL hideKeypad;
static BOOL hideVoicemail;
static BOOL longerCallButton;
static BOOL hideThirdParyCalls;

NSDateFormatter *dateFormatter;
CGFloat screenWidth;

// -------------------------- SHOW EXACT TIME IN RECENT CALLS --------------------------

%group showExactTimeInRecentCallsGroup

// Original Tweak by @gilshahar7: https://github.com/gilshahar7/ExactTimePhone

	%hook MPRecentsTableViewCell

	- (void)layoutSubviews
	{
		%orig;

		if(![[[self callerDateLabel] text] containsString: @":"])
		{
			[[self callerDateLabel] setTextAlignment: NSTextAlignmentRight];
			[[self callerDateLabel] setNumberOfLines: 2];
			[[self callerDateLabel] setText: [[[self callerDateLabel] text] stringByAppendingString: [dateFormatter stringFromDate: [[self callerDateLabel] date]]]];
		}
	}

	%end

%end

// -------------------------- CUSTOM DEFAULT OPENED TAB --------------------------

%group defaultTabGroup

	%hook PhoneTabBarController

	- (int)currentTabViewType
	{
		if(defaultTab == 1 && !hideFavourites 
		|| defaultTab == 2 && !hideRecents 
		|| defaultTab == 3 && !hideContacts 
		|| defaultTab == 4 && !hideKeypad
		|| defaultTab == 5 && !hideVoicemail)
			return defaultTab;
		else	
			return %orig;
	}

	- (int)defaultTabViewType
	{
		return defaultTab;
	}

	%end

%end

// -------------------------- HIDE TABS --------------------------

%group hideTabsGroup

	%hook PhoneTabBarController

	- (void)showFavoritesTab: (BOOL)tab recentsTab: (BOOL)tab2 contactsTab: (BOOL)tab3 keypadTab: (BOOL)tab4 voicemailTab: (BOOL)tab5
	{
		%orig(!hideFavourites, !hideRecents, !hideContacts, !hideKeypad, !hideVoicemail);
	}

	%end

%end

// -------------------------- LONGER CALL BUTTON --------------------------

%group longerCallButtonGroup

	%hook PHBottomBarButton

	- (void)layoutSubviews
	{
		%orig;

		CGRect newFrame = [self frame];
		newFrame.size.width = 282;
		newFrame.origin.x = screenWidth / 2.0 - newFrame.size.width / 2.0;
		[self setFrame: newFrame];

		[[[self overlayView] layer] setCornerRadius: [[self layer] cornerRadius]];
	}

	%end

	%hook PHHandsetDialerDeleteButton

	- (void)layoutSubviews
	{
		%orig;

		CGRect newFrame = [self frame];
		newFrame.origin.x = screenWidth / 2.0 - newFrame.size.width / 2.0;
		newFrame.origin.y = 187;
		[self setFrame: newFrame];
	}

	%end

%end

// -------------------------- HIDE THIRD PARTY CALLS FROM RECENT CALLS --------------------------

%group hideThirdParyCallsGroup

	%hook MobilePhoneApplication

	- (BOOL)showsThirdPartyRecents
	{
		return NO;
	}

	%end

%end

%ctor
{
	@autoreleasepool
	{
		pref = [[HBPreferences alloc] initWithIdentifier: @"com.johnzaro.perfectphoneprefs"];
		[pref registerDefaults:
		@{
			@"enabled": @NO,
			@"showExactTimeInRecentCalls": @NO,
			@"defaultTab": @1,
			@"hideFavourites": @NO,
			@"hideRecents": @NO,
			@"hideContacts": @NO,
			@"hideKeypad": @NO,
			@"hideVoicemail": @NO,
			@"longerCallButton": @NO,
			@"hideThirdParyCalls": @NO
    	}];

		enabled = [pref boolForKey: @"enabled"];
		if(enabled)
		{
			showExactTimeInRecentCalls = [pref boolForKey: @"showExactTimeInRecentCalls"];
			defaultTab = [pref integerForKey: @"defaultTab"];
			hideFavourites = [pref boolForKey: @"hideFavourites"];
			hideRecents = [pref boolForKey: @"hideRecents"];
			hideContacts = [pref boolForKey: @"hideContacts"];
			hideKeypad = [pref boolForKey: @"hideKeypad"];
			hideVoicemail = [pref boolForKey: @"hideVoicemail"];
			longerCallButton = [pref boolForKey: @"longerCallButton"];
			hideThirdParyCalls = [pref boolForKey: @"hideThirdParyCalls"];

			if(showExactTimeInRecentCalls) 
			{
				dateFormatter = [[NSDateFormatter alloc] init];

				NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
				[formatter setLocale: [NSLocale currentLocale]];
				[formatter setDateStyle: NSDateFormatterNoStyle];
				[formatter setTimeStyle: NSDateFormatterShortStyle];
				NSString *dateString = [formatter stringFromDate: [NSDate date]];
				if([dateString rangeOfString: [formatter AMSymbol]].location == NSNotFound && [dateString rangeOfString: [formatter PMSymbol]].location == NSNotFound)
					[dateFormatter setDateFormat: @"\nHH:mm"];
				else
					[dateFormatter setDateFormat: @"\nh:mm a"];

				%init(showExactTimeInRecentCallsGroup);
			}

			if((hideFavourites || hideRecents || hideContacts || hideKeypad || hideVoicemail) && !(hideFavourites && hideRecents && hideContacts && hideKeypad)) 
				%init(hideTabsGroup);
			else
			{
				hideFavourites = NO;
				hideRecents = NO;
				hideContacts = NO;
				hideKeypad = NO;
				hideVoicemail = NO;
			}

			if(defaultTab < 1 || defaultTab > 4)
				defaultTab = 1;
			while(defaultTab == 1 && hideFavourites || defaultTab == 2 && hideRecents || defaultTab == 3 && hideContacts || defaultTab == 4 && hideKeypad)
			{
				defaultTab++;
				if(defaultTab == 5)
					defaultTab = 1;
			}
			%init(defaultTabGroup);
			
			if(longerCallButton)
			{
				screenWidth = [[UIScreen mainScreen] bounds].size.width;
				%init(longerCallButtonGroup);
			}

			if(hideThirdParyCalls)
				%init(hideThirdParyCallsGroup);
		}
	}
}