//
//  ViewController.h
//  Multithreaded Zero-Day Attack
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

- (IBAction)checkFile:(NSButton *)sender; //Function that is called when checkFile button is clicked.
- (IBAction)selectFile:(id)sender; //Function that is called when selectFile button is clicked.
@property (weak) IBOutlet NSTextField *workerThreadCount; // IBOutlet for TextField showing number of worker threads.
@property (weak) IBOutlet NSTextField *selectedPathTextField; // IBOutlet for TextField showing the path of the currently selected file.
@property (weak) IBOutlet NSProgressIndicator *progressBar; //IBOutlet for the progress bar.
@property (weak) IBOutlet NSButton *checkFile; //IBOutlet to access the checkFile Button
@property (weak) IBOutlet NSTextField *vulnerabilityPaternTextField; // IBOutlet for TextField (user-editable) that shows the vulnerability pattern.
@property (weak) IBOutlet NSTextField *vulnerabilityRateTextField; // IBOutlet for TextField showing approximate vulnerability rate
@property (weak) IBOutlet NSTextField *vulnerabilityCountTextField; // IBOutlet for TextField showing vulnerability count
@property (weak) IBOutlet NSProgressIndicator *progressBarIndicator; //IBOutlet for Progress Bar (Duplicate, can be removed later)
@property (weak) IBOutlet NSLevelIndicator *threadLevelIndicator; // IBOutlet to access the level indicator (green-orange-red gauge).
-(void) handleChangeWorkerThreadCount:(NSNotification *) notification; // Function to handle NSNotification changeWorkerThreadCount
-(void) handleChangeVulnerabilityRate:(NSNotification *) notification; // Function to handle NSNotification changeVulnerabilityRate
-(void) handleChangeVulnerabilityCount:(NSNotification *) notification; // Function to handle NSNotification changeVulnerabilityCount
-(void) handleChangeProgressBarIndicator:(NSNotification *) notification; // Function to handle NSNotification changeProgressBarIndicator
-(void) handleChangeLevelIndicator:(NSNotification *) notification; // Function to handle NSNotification changeLevelIndicator
@end

