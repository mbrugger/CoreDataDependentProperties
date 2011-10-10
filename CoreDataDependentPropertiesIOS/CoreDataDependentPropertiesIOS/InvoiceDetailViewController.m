//
//  InvoiceDetailViewController.m
//  CoreDataDependentPropertiesIOS
//
//  Created by Martin Brugger on 10.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InvoiceDetailViewController.h"
#import "Invoice.h"
#import "Customer.h"
#import "LPManagedObjectContext.h"

@implementation InvoiceDetailViewController
@synthesize invoiceNumberTextField;
@synthesize sumTextField;
@synthesize discountTextField;
@synthesize alreadyPaidSwitch;

@synthesize invoice=__invoice;
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
    [invoiceNumberTextField release];
    [sumTextField release];
    [discountTextField release];
    [alreadyPaidSwitch release];
    [__invoice release];
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

    NSAssert(self.customer != nil, @"Customer must be set!");
    
    if (self.invoice)
    {
        self.invoice = (Invoice *)[self.editContext objectWithID:self.invoice.objectID];
    }
    else
    {
        self.invoice = [Invoice insertNewInvoiceWithCustomer:(Person *)[self.editContext objectWithID:[self.customer objectID]] inManagedObjectContext:self.editContext];
    }
    
    self.invoiceNumberTextField.text = self.invoice.invoiceNumber;
    self.sumTextField.text = self.invoice.invoiceSum.stringValue;
    self.discountTextField.text = self.invoice.discount.stringValue;
    [self.alreadyPaidSwitch setOn:self.invoice.alreadyPaid.boolValue animated:NO];
    
}

- (void)viewDidUnload
{
    [self setInvoiceNumberTextField:nil];
    [self setSumTextField:nil];
    [self setDiscountTextField:nil];
    [self setAlreadyPaidSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)doneAction
{
    self.invoice.invoiceNumber = self.invoiceNumberTextField.text;
    self.invoice.invoiceSum = [NSNumber numberWithDouble:self.sumTextField.text.doubleValue];
    self.invoice.discount = [NSNumber numberWithDouble:self.discountTextField.text.doubleValue];
    self.invoice.alreadyPaid = [NSNumber numberWithBool:self.alreadyPaidSwitch.on];
    [super doneAction];
}

@end
