//
//  LogChecker.h
//  Assignment1_COEN_346
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#ifndef LogChecker_h
#define LogChecker_h
#import <Cocoa/Cocoa.h>
@interface LogChecker : NSObject //Inherits from NSObject
{
    _Atomic int64_t vulnerabilityCount;
    _Atomic int64_t lineCheckedCount;
    _Atomic int64_t sharedThreadCount;
    NSString *filePath;
    FILE *file;
    NSString *vulnerabilityPattern;
    double approximateVulnerabilityAverage;
    NSMutableArray *threadsArray;
    NSTimer *timer;
    
}

- (NSObject*) init:(NSString *)givenFilePath andVulnerabilityPattern:(NSString*)testVulnerabilityPattern; // Tell the user we will start scanning the file.
- (void) setFilePath:(NSString *)givenFilePath; // Set the path of the file to be evaluated.
- (void) setFile; //Set the file handle.
- (void) readFile; // Log the entire file, line by line.
+ (NSString*) readLineAsNSString:(FILE*)file; //read the next line
- (NSString*) getFilePath; //Returns the filePath property.
- (NSThread*) createThread:(NSString*)lineToCheck; //Create a new Thread and return a pointer to it.
- (void) atomicVulnerabilityCountIncrement; //Atomically increment the vulnerability count.
- (void) workerThread:(NSString*)lineToCheck; // Entry point method of newly created threads.
- (int) getVulnerabilityCount; // Returns vulnerabilityCount
- (bool) allThreadsReturned; // Returns true iff all threads in threadsArray are .finished
- (void) atomicLineCountIncrement; //Atomically increment the linecount. (This is a net count since the increment is called within a worker thread just before it finished).
- (void) onTick:(NSTimer *)timer; 

@end

#endif /* LogChecker_h */
