#import <UIKit/UIKit2.h>
#import <CaptainHook/CaptainHook.h>

%config(generator=internal)

%hook UIScrollView

static inline void SendFrameNotification(UIView *keyboardView, NSTimeInterval duration, CGRect beforeFrame)
{
	/*CGRect frame = keyboardView.frame;
	UIWindow *firstWindow = [UIApp.windows objectAtIndex:0];
	UIView *superview = keyboardView.superview;
	CGPoint beforeCenter;
	beforeCenter.x = beforeFrame.origin.x + 0.5f * beforeFrame.size.width;
	beforeCenter.y = beforeFrame.origin.y + 0.5f * beforeFrame.size.height;
	CGPoint center;
	center.x = frame.origin.x + 0.5f * frame.size.width;
	center.y = frame.origin.y + 0.5f * frame.size.height;
	NSValue *endFrameValue = [NSValue valueWithCGRect:[superview convertRect:frame toView:firstWindow]];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSValue valueWithCGRect:[superview convertRect:beforeFrame toView:firstWindow]], UIKeyboardFrameBeginUserInfoKey,
		endFrameValue, UIKeyboardFrameEndUserInfoKey,
		[NSValue valueWithCGPoint:[superview convertPoint:beforeCenter toView:firstWindow]], UIKeyboardCenterBeginUserInfoKey,
		[NSValue valueWithCGPoint:[superview convertPoint:center toView:firstWindow]], UIKeyboardCenterEndUserInfoKey,
		[NSNumber numberWithInt:UIViewAnimationCurveLinear], UIKeyboardAnimationCurveUserInfoKey,
		[NSNumber numberWithDouble:duration], UIKeyboardAnimationDurationUserInfoKey,
		endFrameValue, UIKeyboardBoundsUserInfoKey,
		nil];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:UIKeyboardWillChangeFrameNotification object:nil userInfo:userInfo];
	[nc postNotificationName:UIKeyboardDidChangeFrameNotification object:nil userInfo:userInfo];*/
}

static CGFloat offset;

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
	%orig;
	if ([UIKeyboardImpl activeInstance] && (kCFCoreFoundationVersionNumber < 675.0 || ![self isKindOfClass:%c(CKTranscriptTableView)])) {
		UIPeripheralHostView *view = CHIvar([UIPeripheralHost sharedInstance], _hostView, UIPeripheralHostView *);
		UIView *superview = self.superview;
		while (superview) {
			// Don't allow scrollviews inside the peripheral host to trigger dismissal
			// Happens when choosing a date in Reminders or using the Emoji keyboard
			if (superview == view)
				return;
			superview = superview.superview;
		}
		CGRect beforeFrame = view.frame;
		switch (recognizer.state) {
			case UIGestureRecognizerStateEnded: {
				CGFloat translation = [recognizer translationInView:view].y;
				if (translation + offset > 20.0f) {
					[UIView beginAnimations:nil context:NULL];
					CGFloat velocity = [recognizer velocityInView:view].y;
					NSTimeInterval time = 0.33;
					if (velocity > 0.0f) {
						// Attempt to match velocity of gesture
						// not accurate by any means, but is close enough
						CGFloat distanceToTravel = beforeFrame.size.height - translation;
						time = time * 0.5 + distanceToTravel * 0.5f / velocity;
						[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
					} else {
						[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
					}
					[UIView setAnimationDuration:time];
					view.transform = CGAffineTransformIdentity;
					// Resign both on key window and the window the scroll view is in
					//UIWindow *window = self.window;
					UIWindow *keyWindow = [UIApp keyWindow];
					[[keyWindow firstResponder] resignFirstResponder];
					//if (keyWindow != window)
					//	[[window firstResponder] resignFirstResponder];
					[UIView commitAnimations];
					break;
				}
			}
			case UIGestureRecognizerStateFailed:
			case UIGestureRecognizerStateCancelled:
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.33];
				view.transform = CGAffineTransformIdentity;
				SendFrameNotification(view, 0.33, beforeFrame);
				[UIView commitAnimations];
				break;
			case UIGestureRecognizerStateBegan:
				offset = [recognizer locationInView:view].y;
			default: {
				CGFloat translation = [recognizer translationInView:view].y + offset;
				if (translation < 0.0f)
					translation = 0.0f;
				else {
					CGFloat height = view.frame.size.height;
					if (translation > height)
						translation = height;
				}
				view.transform = CGAffineTransformMakeTranslation(0.0f, translation);
				SendFrameNotification(view, 0.0, beforeFrame);
				break;
			}
		}
	}
}

%end
