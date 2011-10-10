//
//  CustomerDetailViewController.m
//  CoreDataDependentPropertiesIOS
//
//  Created by Martin Brugger on 10.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomerDetailViewController.h"
#import "LPManagedObjectContext.h"
#import "Customer.h"

@implementation CustomerDetailViewController
@synthesize customerNameTextField;
@synthesize standardDiscountTextField;
@synthesize customerSumLabel;


@synthesize customer=__customer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [customerNameTextfield release];
    [standardDiscountTextField release];
    [customerSumLabel release];
    [__customer release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    Customer *customer = [Customer insertNewCustomerWithName:@"" inManagedObjectContext:self.editContext];
    self.customer = customer;
    
    self.customerNameTextField.text = customer.name;
    

}

- (void)viewDidUnload
{
    [self setCustomerNameTextField:nil];
    [self setStandardDiscountTextField:nil];
    [self setCustomerSumLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)doneAction
{
    self.customer.name = self.customerNameTextField.text;
    [super doneAction];
}
@end
