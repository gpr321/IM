//
//  ConnectViewController.h
//  TCPClientDemo
//
//  Created by 赵 栓 on 09-10-10.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ConnectViewController : UIViewController {	
	UITextField *textField;
	UIButton *button;
}

@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UIButton *button;

@end
