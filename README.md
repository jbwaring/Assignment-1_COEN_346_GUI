# COEN 346 Assignment 1

**Jean-Baptiste Waring - 40054925**

The project is divided in five files
 - `main.m`: main entry point to the program.
 - `LevenshteinDistance.h`: header of `LevenshteinDistance` class. 
  - `LevenshteinDistance.m`: implementation of `LevenshteinDistance` class. 
 - `LogChecker.h`: header of `LogChecker` class. 
  - `LogChecker.m`: implementation of `LogChecker` class. 

  ## Main

```objectivec
int main(int argc, char** argv)
```
  The main starts by getting the file path from `argv` and checks whether this is an existing path using :
  ```objectivec 
  [[NSFileManager defaultManager] fileExistsAtPath: myPath];
  ```
If it does exist, an instance of `LogChecker` is created using :

```objectivec 
LogChecker *myLogChecker = [[LogChecker alloc] init:myPath and:vulnerabilityPattern];
```
Then the `readFile` method is messaged to start checking the file :
```objectivec 
[myLogChecker readFile];
```
Once `readFile` returns, the main exits.

 ## Levenshtein Distance

 The class is a conversion of Mohammed Shebab implementation from `Java` to `Objective-C` as given in the Assignment's ressources.

## LogChecker

The `LogChecker` class opens the log file and, using multiple threads and the methods exposed by `LevenshteinDistance`, computes the number of vulnerabilities. It inherits from `NSObject`. The class properties are as follows :

```objecivec
@interface LogChecker : NSObject
{
    _Atomic int64_t vulnerabilityCount;
    _Atomic int64_t lineCheckedCount;
    NSString *filePath;
    FILE *file;
    NSString *vulnerabilityPattern;
    double approximateVulnerabilityAverage;
    NSMutableArray *threadsArray;

}
```
The function prototypes are as follows :

An overriden `init` function creates an instance of `LogChecker` and returns its pointer.
```objectivec
(NSObject*) init:(NSString *)givenFilePath and:(NSString*)testVulnerabilityPattern;
```

The `setFilePath` function sets the `filePath` property.
```objectivec
- (void) setFilePath:(NSString *)givenFilePath;
```

The `getFilePath` function returns the `filePath` property.
```objectivec
- (NSString*) getFilePath;
```

The `setFile` function sets the `FILE*` handle.
```objectivec
- (void) setFile;
```

The `readFile` function checks the content of the given file for vulnerabilities using methods from the `LavenshteinDistance` class.
```objectivec
- (void) readFile;
```

The `readLineAsNSString` function is a class method helper to get the next line of the file as `NSString`.
```objectivec
+ (NSString*) readLineAsNSString:(FILE*)file;
```
The `createThread` creates a new thread and starts it. It also returns a `NSThread*` pointer to enable the main thread to keep track of worker threads.
```objectivec
- (NSThread*) createThread:(NSString*)lineToCheck;
```
The `atomicVulnerabilityCountIncrement` atomically increments the `vulnerabilityCount` property. According to Apple, the operation is *performed atomically with respect to all devices that participate in the coherency architecture of the platform.*
```objectivec
- (void) atomicVulnerabilityCountIncrement; 
```
The `createThread` creates a new thread and starts it. It also returns a `NSThread*` pointer to enable the main thread to keep track of worker threads.
```objectivec
- (NSThread*) createThread:(NSString*)lineToCheck;
```
The `createThread` creates a new thread and starts it. It also returns a `NSThread*` pointer to enable the main thread to keep track of worker threads.
```objectivec
- (NSThread*) createThread:(NSString*)lineToCheck;
```



 
