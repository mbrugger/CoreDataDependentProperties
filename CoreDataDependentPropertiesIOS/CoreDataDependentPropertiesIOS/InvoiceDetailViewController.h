//
//  InvoiceDetailViewController.h
//  CoreDataDependentPropertiesIOS
//
//  Created by Martin Brugger on 10.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewController.h"

@class Invoice;
@class Customer;
@interface InvoiceDetailViewController : DetailViewController {
    
    UITextField *invoiceNumberTextField;
    UITextField *sumTextField;
    UITextField *discountTextField;
    UISwitch *alreadyPaidSwitch;
}
@property (nonatomic, retain) IBOutlet UITextField *invoiceNumberTextField;
@property (nonatomic, retain) IBOutlet UITextField *sumTextField;
@property (nonatomic, retain) IBOutlet UITextField *discountTextField;
@property (nonatomic, retain) IBOutlet UISwitch *alreadyPaidSwitch;

@property (nonatomic, retain) Invoice *invoice;
@property (nonatomic, retain) Customer *customer;

@end
