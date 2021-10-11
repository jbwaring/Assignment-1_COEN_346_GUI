//
//  ViewController.m
//  Multithreaded Zero-Day Attack
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#import "ViewController.h"
#import "LogChecker.h"
@implementation ViewController

NSString *numberOfWorkerString = @"";
NSString *myPath;

-(void) handleChangeWorkerThreadCount:(NSNotification *) notification {
    NSString *message = notification.object;
    [_workerThreadCount setStringValue:message];
}
-(void) handleChangeLevelIndicator:(NSNotification *)notification{
    NSString *someObject = notification.object; // Some custom object that was passed with notification fire.
    [_threadLevelIndicator setDoubleValue: [someObject doubleValue]];
}

-(void) handleChangeVulnerabilityRate:(NSNotification *) notification{
    NSString *someObject = notification.object; // Some custom object that was passed with notification fire.
    [_vulnerabilityRateTextField setStringValue:someObject];
}
-(void) handleChangeVulnerabilityCount:(NSNotification *) notification{
    NSString *someObject = notification.object; // Some custom object that was passed with notification fire.
    [_vulnerabilityCountTextField setStringValue:someObject];
};

-(void) handleChangeProgressBarIndicator:(NSNotification *) notification{
    NSNumber *someObject = notification.object;// Some custom object that was passed with notification fire.
    [_progressBarIndicator setDoubleValue: [someObject doubleValue]];
};


- (IBAction)selectFile:(id)sender { //Select File Action
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];

    NSInteger clicked = [panel runModal];

    if (clicked == NSModalResponseOK) {
        for (NSURL *url in [panel URLs]) {
            // do sNSModalResponseOK
            NSLog(@"%@", url.path);
            myPath = url.path;
            [_selectedPathTextField setStringValue:url.path];
            [_checkFile setEnabled:true];
        }
    }
}

- (IBAction)checkFile:(NSButton *)sender {
    
    NSLog(@"Check File Pressed!");
    [_progressBar setHidden:false]; // Let the user see the progressBar at 0%/
    
    //Checking wether the path exists.
    NSLog(@"Checking wether a file at: %@ exists.", myPath);
    bool fileExistsAtUserProvidedPath = [[NSFileManager defaultManager] fileExistsAtPath: myPath]; //Returns True if a file exists at the given path.
    
    
    if(fileExistsAtUserProvidedPath) { //If we have a valid path
        
        NSLog(@"File exists.");
        NSString *vulnerabilityPatternCopy = [_vulnerabilityPaternTextField stringValue]; // Get a copy of the content of the TextField for Vulnerability Pattern.
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //Dispatch an instance of LogChecker and call readFile on it on a background thread. Staying here (main thread) will freeze the UI and make the user think the Application is unresponsive.
            
            
            
            LogChecker *myLogChecker = [[LogChecker alloc] init:myPath andVulnerabilityPattern:vulnerabilityPatternCopy]; //Allocate memory for an instance of LogChecker and use an overriden init function.
            NSLog(@"myLogChecker is initialized with this file path: %@", [myLogChecker getFilePath]); //Confirming to the user that we will start reading the file.
            

             [myLogChecker readFile]; // Messages the readFile method of the LogChecker class with instance myLogChecker (Starts to check the file)
            NSLog(@"Vulnerability Count: %d",[myLogChecker getVulnerabilityCount] );
            
        });
        
        
        
//        This will be executed even if readFile is not finished. Thus, if we would like, for example, to hide the checkfile button during execution, we would have to hide it here and use an NSNotification Listener to call a selector to setHidden:NO when readFile returns.
//        --> readFile is executing on background threads, back to the UI on the Main Thread.
        
    } else {
        
//        If fileExistsAtUserProvidedPath is false quit program with Error.
        NSLog(@"File does not exist. Please input a valid file path.");
        [NSException raise:@"File does not exist!" format:@"%@ is not a valid path.", myPath];
//        NSException will not be caught and cause a fatal error. //This should be inaccessible since the NSOpenPanel makes sure we are selecting a valid file. So this could be removed entirely, here for good measure.
        
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [_checkFile setEnabled:false]; // Cannot click on the checkFile button if no file is selected ( cannot call LogChecker with nil filepath.
    [_progressBar setDoubleValue:0.0]; // Set the progress to 0.
    [_progressBar setHidden:true]; // Set it hidden since nothing is happening.
    [_workerThreadCount setStringValue:numberOfWorkerString]; // set it to a string @"".
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeWorkerThreadCount:) name:@"changeWorkerThreadCount" object:nil]; // Add a NSNotification Observer on message name @"changeWorkerThreadCount" --> every time a message of this type is received in the NSNotificationCenter, the selector handleChangeWorkerThreadCount is called and we can update the UI.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeVulnerabilityRate:) name:@"changeVulnerabilityRate" object:nil]; // Add a NSNotification Observer on message name @"changeVulnerabilityRate" --> every time a message of this type is received in the NSNotificationCenter, the selector handleChangeVulnerabilityRate is called and we can update the UI.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeVulnerabilityCount:) name:@"changeVulnerabilityCount" object:nil]; // Add a NSNotification Observer on message name @"changeVulnerabilityCount" --> every time a message of this type is received in the NSNotificationCenter, the selector handleChangeVulnerabilityCount is called and we can update the UI.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeProgressBarIndicator:) name:@"changeProgressBarIndicator" object:nil]; // Add a NSNotification Observer on message name @"changeProgressBarIndicator" --> every time a message of this type is received in the NSNotificationCenter, the selector handleChangeProgressBarIndicator is called and we can update the UI.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeLevelIndicator:) name:@"changeLevelIndicator" object:nil]; // Add a NSNotification Observer on message name @"changeLevelIndicator" --> every time a message of this type is received in the NSNotificationCenter, the selector handleChangeLevelIndicator is called and we can update the UI.

    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}



@end
