@interface UIDateLabel: UILabel
@property(nonatomic, strong) NSDate *date;
@end

@interface MPRecentsTableViewCell: UITableViewCell
@property(nonatomic, strong) UIDateLabel *callerDateLabel;
@end

@interface PHBottomBarButton: UIView
@property(nonatomic, copy) UIView *overlayView;
- (void)layoutSubviews;
@end

@interface PHHandsetDialerDeleteButton: UIView
- (void)layoutSubviews;
@end