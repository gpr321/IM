//
//  ChatViewController.m
//  TCPClientDemo
//
//  Created by 赵 栓 on 09-10-10.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController.h"


@implementation ChatViewController

@synthesize textView;
@synthesize toolBar;
@synthesize textField;
@synthesize button;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)keyboardWillShown:(NSNotification *)aNotification {
	// 获得键盘大小
	NSDictionary *info = [aNotification userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;
	[UIView beginAnimations:nil context:NULL];
	// 设置动画
	[UIView setAnimationDuration:0.3];
	// 将toolBar的位置放到键盘上方
	CGRect frame = toolBar.frame;
	frame.origin.y -= keyboardSize.height;
	toolBar.frame = frame;
	//调整textView的高度
	frame = textView.frame;
	frame.size.height -= keyboardSize.height;
	textView.frame = frame;
	[UIView commitAnimations];
	NSRange endRange;
	endRange.location = [textView.text length];
	endRange.length = 1;
	// 将textView滚动到最后
	if(endRange.location > 0)
		[textView scrollRangeToVisible:endRange];
}

- (void)keyboardWillHidden:(NSNotification *)aNotification {
	NSDictionary *info = [aNotification userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	CGRect frame = toolBar.frame;
	frame.origin.y += keyboardSize.height;
	toolBar.frame = frame;
	frame = textView.frame;
	frame.size.height += keyboardSize.height;
	textView.frame = frame;
	[UIView commitAnimations];
	NSRange endRange;
	endRange.location = [textView.text length];
	endRange.length = 1;
	if(endRange.location > 0)
		[textView scrollRangeToVisible:endRange];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[textView release];
	[toolBar release];
	[textField release];
	[button release];
    [super dealloc];
}


@end
