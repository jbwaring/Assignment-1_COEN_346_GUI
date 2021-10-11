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
    [myThread setQualityOfService:1.0]; //Set the Thread to the highest QoS (1.0) to ensure it gets highest priority.
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

- (void) onTick:(NSTimer *)timer { // UI Updating Function. Everytime the NSTimer Ticks, this will be the entry point. I use NSNotificationCenter to share information between threads. I send messages to this notifications center and then have the UI be listening for those messages. This has very little performance impact to the main task since this is performed on another thread.
    
    NSString *updateThreadWorkerCountMessage = [NSString stringWithFormat:@"Worker Count (Threads) : %lld", sharedThreadCount]; // Create the UI Message including the current number of threads
        NSString *updateVulnerabilityRateMessage = [NSString stringWithFormat:@"Approximate Vulnerability Rate : %f", self->approximateVulnerabilityAverage]; // Create the UI Message including the current approximate vulnerability rate
        NSString *updateVulnerabilityCountMessage = [NSString stringWithFormat:@"Vulnerability Count : %lld", self->vulnerabilityCount]; // Create the UI Message including the current vulnerability count
        NSNumber *updateProgressBarMessage = [[NSNumber alloc] initWithDouble:( (double)lineCheckedCount / 200000.0 * 10000)]; // Create the value to update the Progress Bar. Progress bar has 10,000 steps, which is fined enough not to be noticed.
    NSNumber *updateLevelIndicatorMessage = [[NSNumber alloc] initWithLong:sharedThreadCount]; //Create an NSNumber with long integer (NSNotifications use Objects and thus we need to perform this convertion.
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeWorkerThreadCount" object:updateThreadWorkerCountMessage]; // Send the message with id "changeWorkerThreadCount" to the notification center
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeVulnerabilityRate" object:updateVulnerabilityRateMessage]; // Send the message with id "changeVulnerabilityRate" to the notification center
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeVulnerabilityCount" object:updateVulnerabilityCountMessage]; // Send the message with id "changeVulnerabilityCount" to the notification center
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeProgressBarIndicator" object:updateProgressBarMessage]; // Send the message with id "changeProgressBarIndicator" to the notification center
            [NSNotificationCenter.defaultCenter postNotificationName:@"changeLevelIndicator" object:updateLevelIndicatorMessage]; // Send the message with id "changeLevelIndicator" to the notification center
        });
}

- (void) readFile { // "main function" that supervises the operation
    
    double deltaVulnerabilityAverage = -1; // Initialy set the vulnerability average to be -1 (that ensures we start with 2 threads )
    int threadCount = 64;
    int maxThreadCount = 64;
    
    
    dispatch_async(dispatch_get_main_queue(), ^{ //Dispatch the UI Updater Timer on another thread with selector OnTick and will tick ~3 times per seconds (and autostart). We keep a pointer to the timer in order to be able to message this thread to stop when we have finished reading the file (no need to update the UI since we are not doing anything anymore. Also we might have deleted the LogChecker Instance.
        self->timer  = [NSTimer scheduledTimerWithTimeInterval: 0.3
                                                         target: self
                                                         selector:@selector(onTick:)
                                                         userInfo: nil repeats:YES]; // Create Timer and rembember a poiter to it.
    });
    
    
    while(!feof(file)) // feof() returns true iff we are at the end of file indicator of the inputed stream (so the loop will run for as long as lines are remaining)
    {
        int threadNumber = 0 ; // Set the initial threadNumber to 0
        double previousVulnerabilityAverage = self->approximateVulnerabilityAverage; // Make a copy of the vulnerability average before it is mutated.

//        This deals with how to choose the number of threads. If the "~derivative" of the vulnerability average is negative (tendency to see less vulnerabilities, decrease number of threads. If the "~derivative" of the vulnerability average is positive (tendency to see more vulnerabilities, increase number of threads. (This is based on the supposition that vulnerabilities occur in lumps rather than homogenously in time. The max thread count is set to 64 but can be set to any reasonable value.
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


        
        for (int i = 1; i <= threadCount; i++) // Create n = threadCount number of worker threads.
        {
            NSString *line = [LogChecker readLineAsNSString:file]; // Store the next line in the file in NSSTring.
            if(!(line.length == 0)){ //If the file has ended during this loop, the strings are nil this .lenght = 0 so we do not dispatch the thread. This enables us to not take into account the number of remaining lines in choosing the number of threads.
                [self createThread:line]; //If the line exists, call createThread and message it a pointer to the line.
            }
        }

        threadNumber = (int)threadsArray.count; // Get the number of threads that were created --> because of the .length condition, it might be different than threadCount.
        sharedThreadCount = threadNumber; // Store this number in sharedThreadCount.

        while(![self allThreadsReturned]){} //Loops until all threads return. Basically a [waitUntil allThreadsReturned]. --> This is one main area of improvement since this is "busy wait" which is really bad for battery life and performance.
            
        deltaVulnerabilityAverage = (self->approximateVulnerabilityAverage - previousVulnerabilityAverage)/previousVulnerabilityAverage * 100; //All the threads have returned, compute the new "vulnerability average derivative"/
        
    } // End of File
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ // 2 Seconds after we have finished reading the file, kill the timer. 2 seconds timeout is just a very conservative way of making sure we have the lastest available information shown on the UI.
        [self->timer invalidate]; // Remove the timer.
        });
    
    fclose(file); // Close the file, we are done.
}


- (NSString*) getFilePath { //Getter for filePath
    return filePath;
}


+ (NSString*) readLineAsNSString:(FILE*)file { // Read one line of the file
    char buffer[4096]; //Create an array of Characters (4096 here)
    
    NSMutableString *result = [NSMutableString stringWithCapacity: 256];
    
    int charsRead; // Will be increment each time we find a char and serve as a stopping condition.
    
    do {
        if(fscanf(file, "%4095[^\n]%n%*c", buffer, &charsRead) == 1) // if 1 means we have one succesfully matched input that is one character
            [result appendFormat:@"%s", buffer]; // Append the buffer to the return value
        else
            break; // no char, give up
    } while(charsRead == 4095); // Do it 4095 times
    return result; //Return the result string (we should get a single Line)
}


- (void) atomicVulnerabilityCountIncrement { // Atomically Increment the Vulnerability Count
    atomic_fetch_add(&vulnerabilityCount, 1); //Atomic operation to ensure that there is no race condition between the threads.
    if(self->lineCheckedCount!=0){ // If it is not the first line, update the average
        self->approximateVulnerabilityAverage = (double)self->vulnerabilityCount/(double)self->lineCheckedCount; // casting to double
    }
}


- (void) atomicLineCountIncrement { // Atomically Increment the Line Count
    atomic_fetch_add(&lineCheckedCount, 1); //Atomic operation to ensure that there is no race condition between the threads.
    if(self->lineCheckedCount!=0){ //If it is not the first line, update the vulnerability count (gives a second chance at updating the vulnerability count
        self->approximateVulnerabilityAverage = (double)self->vulnerabilityCount/(double)self->lineCheckedCount; // casting to double
    }
}


- (int)getVulnerabilityCount { // Getter for Vulnerability Count
    return self->vulnerabilityCount; 
}


- (bool)allThreadsReturned {
    [threadsArray filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return !([object isFinished]); // If element of threadsArray points to a finished NSThread, remove it.
    }]];
    if(threadsArray.count == 0){
        return true; // If the array is empty, all threads have finished and have been removed.
    }
    return false; // Still waiting for some threads to finish.
}


@end

#endif /* LogChecker_m */
