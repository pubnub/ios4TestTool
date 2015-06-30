//
//  ViewController.m
//  PN4Test
//
//  Created by Sergey Mamontov on 6/3/15.
//  Copyright (c) 2015 Sergey Mamontov. All rights reserved.
//

#import "ViewController.h"
#import <PubNub/PubNub.h>


#pragma mark Protected interface declaration

@interface ViewController () <PNObjectEventListener, UITextFieldDelegate>


#pragma mark - Properties

@property (nonatomic, weak) IBOutlet UILabel *status;
@property (nonatomic, weak) IBOutlet UITextField *messageField;
@property (nonatomic, weak) IBOutlet UITextField *channelNameField;
@property (nonatomic, weak) IBOutlet UITextView *messagesField;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) PubNub *client;


#pragma mark - PubNub client

- (void)prepareClient;
- (void)subscribeClient;


#pragma mark - Interface update

- (void)addMessage:(id)message;

#pragma mark -


@end


#pragma mark - Interface implementation

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    // Check whether initialization was successful or not.
    if ((self = [super initWithCoder:aDecoder])) {
        
        _messages = [NSMutableArray new];
        [self prepareClient];
        [self subscribeClient];
    }
    
    return self;
}


- (void)viewDidLoad {
    
    // Forward method call to the super class.
    [super viewDidLoad];
}


#pragma mark - PubNub client

- (void)prepareClient {

    [PNLog enabled:YES];
    [PNLog setMaximumLogFileSize:100];
    [PNLog setMaximumNumberOfLogFiles:10];

    PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"demo"
                                                                     subscribeKey:@"demo"];
    self.client = [PubNub clientWithConfiguration:configuration];
    [self.client addListener:self];
}

- (void)subscribeClient {
    
    [self.client subscribeToChannels:@[@"bot"] withPresence:NO];
}

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult*)message {
    
    [self addMessage:message.data.message];
    [self.messagesField scrollsToTop];
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    
    if (status.category == PNAccessDeniedCategory) {
        
        self.status.text = @"Access Rights";
    }
    else if (status.category == PNConnectedCategory) {
        
        self.status.text = @"Connected";
    }
    else if (status.category == PNReconnectedCategory) {
        
        self.status.text = @"Reconnected";
    }
    else if (status.category == PNDisconnectedCategory) {
        
        self.status.text = @"Expected Disconnect";
    }
    else if (status.category == PNUnexpectedDisconnectCategory) {
        
        self.status.text = @"Unexpected Disconnect";
    }
}


#pragma mark - Interface update

- (void)addMessage:(id)message {
    
    if (message) {
        
        [self.messages insertObject:message atIndex:0];
        if ([self.messages count] > 50) {
            
            [self.messages removeObject:[self.messages lastObject]];
        }
        self.messagesField.text = [self.messages componentsJoinedByString:@"\n"];
    }
}


#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:self.messageField] && [textField.text length]) {
        
        [textField resignFirstResponder];
        textField.userInteractionEnabled = NO;
        NSString *originalPlaceHolder = [textField.placeholder copy];
        NSString *message = [textField.text copy];
        textField.text = nil;
        textField.placeholder = @"Sending...";
        [self.client publish:message toChannel:self.channelNameField.text
                  compressed:NO withCompletion:^(PNPublishStatus *status) {
                      
                      textField.placeholder = (!status.isError ? @"Message sent" : @"Message sending error");
                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                          
                          textField.placeholder = originalPlaceHolder;
                          textField.userInteractionEnabled = YES;
                      });
                  }];
    }
    else if ([textField isEqual:self.channelNameField]) {
        
        [textField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark -


@end
