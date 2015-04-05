//
//  ChatViewController.h
//  TCPClientDemo
//
//  Created by 赵 栓 on 09-10-10.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ChatViewController : UIViewController {
	UITextView *textView;
	UIToolbar *toolBar;
	UITextField *textField;
	UIBarButtonItem *button;
}

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolBar;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *button;

- (void)keyboardWillShown:(NSNotification *)aNotification;
- (void)keyboardWillHidden:(NSNotification *)aNotification;

@end
