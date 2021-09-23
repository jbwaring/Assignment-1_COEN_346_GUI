//
//  ViewController.h
//  Multithreaded Zero-Day Attack
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

- (IBAction)checkFile:(NSButton *)sender;
- (IBAction)selectFile:(id)sender;
@property (weak) IBOutlet NSTextField *workerThreadCount;
@property (weak) IBOutlet NSTextField *selectedPathTextField;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSButton *checkFile;
@property (weak) IBOutlet NSTextField *vulnerabilityPaternTextField;
@property (weak) IBOutlet NSTextField *vulnerabilityRateTextField;
@property (weak) IBOutlet NSTextField *vulnerabilityCountTextField;
@property (weak) IBOutlet NSProgressIndicator *progressBarIndicator;
@property (weak) IBOutlet NSLevelIndicator *threadLevelIndicator;
-(void) handleChangeWorkerThreadCount:(NSNotification *) notification;
-(void) handleChangeVulnerabilityRate:(NSNotification *) notification;
-(void) handleChangeVulnerabilityCount:(NSNotification *) notification;
-(void) handleChangeProgressBarIndicator:(NSNotification *) notification;
-(void) handleChangeLevelIndicator:(NSNotification *) notification;
@end

