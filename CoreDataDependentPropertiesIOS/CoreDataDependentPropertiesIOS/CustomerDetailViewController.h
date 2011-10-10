//
//  CustomerDetailViewController.h
//  CoreDataDependentPropertiesIOS
//
//  Created by Martin Brugger on 10.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewController.h"

@class LPManagedObjectContext;
@class Customer;
@interface CustomerDetailViewController : DetailViewController {
    
    UITextField *customerNameTextfield;
    UITextField *standardDiscountTextField;
    UILabel *customerSumLabel;
}
@property (nonatomic, retain) IBOutlet UITextField *customerNameTextField;
@property (nonatomic, retain) IBOutlet UITextField *standardDiscountTextField;
@property (nonatomic, retain) IBOutlet UILabel *customerSumLabel;

@property (nonatomic, retain) Customer *customer;

@end
