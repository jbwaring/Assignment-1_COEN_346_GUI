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
    [_progressBar setHidden:false];
    [_checkFile setStringValue:@"Stop"];
    
    //Checking wether the path exists.
    NSLog(@"Checking wether a file at: %@ exists.", myPath);
    bool fileExistsAtUserProvidedPath = [[NSFileManager defaultManager] fileExistsAtPath: myPath]; //Returns True if a file exists at the given path.
    
    
    if( fileExistsAtUserProvidedPath ) {
        
        NSLog(@"File exists.");
        NSString *vulnerabilityPatternCopy = [_vulnerabilityPaternTextField stringValue];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //Background Thread
            
            
            
            LogChecker *myLogChecker = [[LogChecker alloc] init:myPath andVulnerabilityPattern:vulnerabilityPatternCopy]; //Allocate memory for an instance of LogChecker and use an overriden init function.
            NSLog(@"myLogChecker is initialized with this file path: %@", [myLogChecker getFilePath]); //Confirming to the user that we will start reading the file.
            

             [myLogChecker readFile]; //Messages the readFile method of the LogChecker class with instance myLogChecker (Starts to check the file)
            NSLog(@"Vulnerability Count: %d",[myLogChecker getVulnerabilityCount] );
            
        });
        
        
        
//        readFile has returned (All worker threads are "finished" and vulerability count is final).
        
        
    }else{
        
//        If fileExistsAtUserProvidedPath is false quit program with Error.
        NSLog(@"File does not exist. Please input a valid file path.");
        [NSException raise:@"File does not exist!" format:@"%@ is not a valid path.", myPath];
//        NSException will not be caught and cause a fatal error.
        
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [_workerThreadCount setStringValue:@""];
    [_checkFile setEnabled:false];
    [_progressBar setDoubleValue:0.0];
    [_progressBar setHidden:true];
    [_workerThreadCount setStringValue:numberOfWorkerString];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeWorkerThreadCount:) name:@"changeWorkerThreadCount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeVulnerabilityRate:) name:@"changeVulnerabilityRate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeVulnerabilityCount:) name:@"changeVulnerabilityCount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeProgressBarIndicator:) name:@"changeProgressBarIndicator" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeLevelIndicator:) name:@"changeLevelIndicator" object:nil];

    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}



@end
