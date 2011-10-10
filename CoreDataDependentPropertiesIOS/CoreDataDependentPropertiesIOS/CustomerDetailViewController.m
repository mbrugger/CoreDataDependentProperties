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

@synthesize managedObjectContext=__managedObjectContext;
@synthesize editContext=__editContext;

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
    [__managedObjectContext release];
    [__editContext release];
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
    self.editContext = [[[LPManagedObjectContext alloc] init] autorelease];
    self.editContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
    [self.editContext prepareDependentProperties];
    
    Customer *customer = [Customer insertNewCustomerWithName:@"" inManagedObjectContext:self.editContext];
    self.customer = customer;
    
    self.customerNameTextField.text = customer.name;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
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
#pragma mark - 
#pragma mark Actions

- (void)doneAction
{
    self.customer.name = self.customerNameTextField.text;
    
    // merge context
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:self.editContext];
    NSError *error = nil;

    BOOL success = [self.editContext save:&error];	
    
    if (!success)
    {
        NSLog(@"error: %@", error);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.editContext];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelAction
{
    
    [self.navigationController popViewControllerAnimated:YES];    
}

#pragma mark Context merge - 

- (void)mergeChanges:(NSNotification *)notification
{
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}



@end
