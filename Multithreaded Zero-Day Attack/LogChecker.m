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
#import <stdatomic.h>
#import "LevenshteinDistance.h"
#import "ViewController.h"
#import <Cocoa/Cocoa.h>
#if __has_feature(objc_arc)
  #define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#else
  #define DLog(format, ...) CFShow([NSString stringWithFormat:format, ## __VA_ARGS__]);
#endif //A simple macro for using NSLog with no stamps.

@implementation LogChecker : NSObject

- (void) setFilePath:(NSString *)givenFilePath{
    filePath = givenFilePath;
}


- (void) workerThread:(NSString*)lineToCheck
{

    LevenshteinDistance *myLevenshteinInstance = [[LevenshteinDistance alloc] init];
    
    [LevenshteinDistance computeDistance:lineToCheck andSecond:vulnerabilityPattern andCurrentInstance:myLevenshteinInstance ];
    if(![myLevenshteinInstance isAcceptableChange]){
        [self atomicVulnerabilityCountIncrement];
    }
    [self atomicLineCountIncrement];
}


- (NSThread*) createThread:(NSString*) myLine {
    NSRange myRange = NSMakeRange(41, myLine.length-41); //exact number directly determined by looking at the file;
    NSString *cleanedLine = [myLine substringWithRange:myRange];
    NSThread *myThread = [[NSThread alloc] initWithTarget:self selector:@selector(workerThread:) object:cleanedLine];
    [myThread start];
    [self->threadsArray addObject:myThread];
    return myThread;
}


- (NSObject*) init:(NSString *)givenFilePath andVulnerabilityPattern:(NSString*)testVulnerabilityPattern{
    
    LogChecker* myInstance = [self init];
    [myInstance setFilePath:givenFilePath];
    myInstance->vulnerabilityPattern = testVulnerabilityPattern;
    NSLog(@"Starting LogChecker on file at: %@", filePath);
    [myInstance setFile];
    myInstance->threadsArray = [NSMutableArray array];
    myInstance->lineCheckedCount = 0;
    return myInstance;
}


- (void) setFile {
    const char *cfilename=[filePath UTF8String];
    file = fopen(cfilename, "r");
}

- (void) onTick:(NSTimer *)timer {
        NSString *updateThreadWorkerCountMessage = [NSString stringWithFormat:@"Worker Count (Threads) : %d", sharedThreadCount];
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
            if(threadCount > 64){
                threadCount = 64;
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
