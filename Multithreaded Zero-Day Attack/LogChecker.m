//
//  LogChecker.m
//  Assignment1_COEN_346
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#ifndef LogChecker_m
#define LogChecker_m

#import <Foundation/Foundation.h>
#import "LogChecker.h"
#import <stdatomic.h> // Used for accessing C functions that give atomic variable increment.
#import "LevenshteinDistance.h"
#import <Cocoa/Cocoa.h>
#if __has_feature(objc_arc)
  #define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#else
  #define DLog(format, ...) CFShow([NSString stringWithFormat:format, ## __VA_ARGS__]);
#endif //A simple macro for using NSLog with no stamps.

@implementation LogChecker : NSObject

- (void) setFilePath:(NSString *)givenFilePath{ // Set the givenFilePath Property (Instance Method)
    filePath = givenFilePath; // set the property
}


- (void) workerThread:(NSString*)lineToCheck // Worker Thread --> Selector given as entry point to child threads
{

    LevenshteinDistance *myLevenshteinInstance = [[LevenshteinDistance alloc] init]; // Get an instance of the Levenstein Distance
    
    int numberOfTrials = lineToCheck.length - vulnerabilityPattern.length; // Number of times we need to iterate
    
    for(int i = 0; i<= numberOfTrials; i++){
        NSString *subStringToCheck = [lineToCheck substringWithRange:NSMakeRange(i, vulnerabilityPattern.length)]; //get a substring of the same length
        [LevenshteinDistance computeDistance:subStringToCheck andSecond:vulnerabilityPattern andCurrentInstance:myLevenshteinInstance ]; // compute the levenstein distance (Class Method so we message the class, not an instance of the class but we still pass a pointer to an instance of our class to use instance methods on the result
    }
//    [LevenshteinDistance computeDistance:lineToCheck andSecond:vulnerabilityPattern andCurrentInstance:myLevenshteinInstance ];
    if([myLevenshteinInstance isAcceptableChange]){ // If the change is acceptable
        [self atomicVulnerabilityCountIncrement]; //Atomically Increment the number of vulnerability
    }
    
    [self atomicLineCountIncrement]; // In any case, increment the number of lines we have looked at (atomically because other threads want to increment it too)
}


- (NSThread*) createThread:(NSString*) myLine { // Instance Method that returns a pointer to a new child thread

    NSRange myRange = NSMakeRange(41, myLine.length-41); // Exact number directly determined by looking at the file;
    NSString *cleanedLine = [myLine substringWithRange:myRange]; // Get substring with required range to "clean the line"
    NSThread *myThread = [[NSThread alloc] initWithTarget:self selector:@selector(workerThread:) object:cleanedLine]; // Create an NSThread Object and use the workerThread method as an entry point (selector) messsaging the object cleanedLine
    [myThread start]; // Message the thread object to start working
    [self->threadsArray addObject:myThread]; // Add the pointer to this new thread to the array keeping the list of currently executing
    return myThread; // Return the pointer to the new thread (myThread is of type NSThread*
}


- (NSObject*) init:(NSString *)givenFilePath andVulnerabilityPattern:(NSString*)testVulnerabilityPattern{ // Overriden Class Init() --> Returns a NSObject* that is "automatically casted into" LogChecker Type since LogChecker conforms to NSObject
    
    LogChecker* myInstance = [self init]; // Create an instance of LogChecker
    [myInstance setFilePath:givenFilePath]; // Set the file path (Access Variable Obj-C Style Using Message and Getter/Setter)
    myInstance->vulnerabilityPattern = testVulnerabilityPattern; // Set the Vulnerability Pattern (Access Variable C Style)
    NSLog(@"Starting LogChecker on file at: %@", filePath); // Log to the console
    [myInstance setFile]; // Set the file (use the path to open a file handler at the correct path
    myInstance->threadsArray = [NSMutableArray array]; // Set the Thread Array to an empty array
    myInstance->lineCheckedCount = 0; // Set to 0 the number of lines we have looked at
    return myInstance; // Return a pointer to this instance of type NSObject*
}


- (void) setFile {
    const char* pathConvertedToUTF8 = [filePath UTF8String]; // Convert the path to UTF8 to ensure compatibility (might have unicode filenames)
    file = fopen(pathConvertedToUTF8, "r"); // Use the common C fopen() (in read mode)
}

- (void) onTick:(NSTimer *)timer {
    NSString *updateThreadWorkerCountMessage = [NSString stringWithFormat:@"Worker Count (Threads) : %lld", sharedThreadCount];
        NSString *updateVulnerabilityRateMessage = [NSString stringWithFormat:@"Approximate Vulnerability Rate : %f", self->approximateVulnerabilityAverage];
        NSString *updateVulnerabilityCountMessage = [NSString stringWithFormat:@"Vulnerability Count : %lld", self->vulnerabilityCount];
        NSNumber *updateProgressBarMessage = [[NSNumber alloc] initWithDouble:( (double)lineCheckedCount / 200000.0 * 10000)];
    NSNumber *updateLevelIndicatorMessage = [[NSNumber alloc] initWithLong:sharedThreadCount];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeWorkerThreadCount" object:updateThreadWorkerCountMessage];
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeVulnerabilityRate" object:updateVulnerabilityRateMessage];
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeVulnerabilityCount" object:updateVulnerabilityCountMessage];
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeProgressBarIndicator" object:updateProgressBarMessage];
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeLevelIndicator" object:updateLevelIndicatorMessage];
        });
}

- (void) readFile {
    double deltaVulnerabilityAverage = -1;
    int threadCount = 64;
    int maxThreadCount = 64;
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->timer  = [NSTimer scheduledTimerWithTimeInterval: 0.3
                                                         target: self
                                                         selector:@selector(onTick:)
                                                         userInfo: nil repeats:YES];
    });
    
    while(!feof(file))
    {
        int threadNumber = 0 ;
        double previousVulnerabilityAverage = self->approximateVulnerabilityAverage;
        if(deltaVulnerabilityAverage < 0){
            threadCount = threadCount - 2;
            if(threadCount <= 0){
                threadCount = 2;
            }
        }else{
            threadCount = threadCount + 2;
            if(threadCount > maxThreadCount){
                threadCount = maxThreadCount;
            }
        }
        
        
        
        for (int i = 1; i <= threadCount; i++)
//            for (int i = 1; i <= threadCount; i++)
        {
            NSString *line = [LogChecker readLineAsNSString:file];
            if(!(line.length == 0)){
                [self createThread:line];
            }
        }
        
        threadNumber = (int)threadsArray.count;
        sharedThreadCount = threadNumber;
        
        while(![self allThreadsReturned]){} //Loops until all threads return. Basically a [waitUntil allThreadsReturned]. 
            
        deltaVulnerabilityAverage = (self->approximateVulnerabilityAverage - previousVulnerabilityAverage)/previousVulnerabilityAverage * 100;
        
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->timer invalidate];
        });
    fclose(file);
}


- (NSString*) getFilePath {
    return filePath;
}


+ (NSString*) readLineAsNSString:(FILE*)file {
    char buffer[4096];
    NSMutableString *result = [NSMutableString stringWithCapacity:256];
    int charsRead;
    do {
        if(fscanf(file, "%4095[^\n]%n%*c", buffer, &charsRead) == 1)
            [result appendFormat:@"%s", buffer];
        else
            break;
    } while(charsRead == 265);
    return result;
}


- (void) atomicVulnerabilityCountIncrement {
    atomic_fetch_add(&vulnerabilityCount, 1); //Atomic operation to ensure that there is no race condition between the threads.
    if(self->lineCheckedCount!=0){
        self->approximateVulnerabilityAverage = (double)self->vulnerabilityCount/(double)self->lineCheckedCount;
    }
}


- (void) atomicLineCountIncrement {
    atomic_fetch_add(&lineCheckedCount, 1);
    if(self->lineCheckedCount!=0){
        self->approximateVulnerabilityAverage = (double)self->vulnerabilityCount/(double)self->lineCheckedCount;
    }
}


- (int)getVulnerabilityCount {
    return self->vulnerabilityCount;
}


- (bool)allThreadsReturned {
    [threadsArray filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return !([object isFinished]); //If element of threadsArray points to a finished NSThread, remove it.
    }]];
    if(threadsArray.count == 0){
        return true; //If the array is empty, all threads have been finished and removed.
    }
    return false; // Still waiting for some threads to finish.
}


@end

#endif /* LogChecker_m */
