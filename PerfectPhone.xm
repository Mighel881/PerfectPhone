#import "PerfectPhone.h"
#import <Cephei/HBPreferences.h>

static HBPreferences *pref;
static BOOL enabled;
static BOOL showExactTimeInRecentCalls;
static BOOL hideVoicemail;
static BOOL longerCallButton;

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

// -------------------------- HIDE VOICEMAIL TAB --------------------------

%group hideVoicemailGroup

	%hook PhoneTabBarController

	- (void)showFavoritesTab: (BOOL)tab recentsTab: (BOOL)tab2 contactsTab: (BOOL)tab3 keypadTab: (BOOL)tab4 voicemailTab: (BOOL)tab5
	{
		%orig(YES, YES, YES, YES, NO);
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

%ctor
{
	@autoreleasepool
	{
		pref = [[HBPreferences alloc] initWithIdentifier: @"com.johnzaro.perfectphoneprefs"];
		[pref registerDefaults:
		@{
			@"enabled": @NO,
			@"showExactTimeInRecentCalls": @NO,
			@"hideVoicemail": @NO,
			@"longerCallButton": @NO
    	}];

		enabled = [pref boolForKey: @"enabled"];
		if(enabled)
		{
			showExactTimeInRecentCalls = [pref boolForKey: @"showExactTimeInRecentCalls"];
			hideVoicemail = [pref boolForKey: @"hideVoicemail"];
			longerCallButton = [pref boolForKey: @"longerCallButton"];

			if(showExactTimeInRecentCalls) 
			{
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat: @"\nHH:mm"];

				%init(showExactTimeInRecentCallsGroup);
			}
			if(hideVoicemail) %init(hideVoicemailGroup);
			if(longerCallButton)
			{
				screenWidth = [[UIScreen mainScreen] bounds].size.width;

				%init(longerCallButtonGroup);
			}
		}
	}
}