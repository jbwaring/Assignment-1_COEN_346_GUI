//
//  LevenshteinDistance.h
//  Assignment1_COEN_346
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#ifndef LevenshteinDistance_h
#define LevenshteinDistance_h

@interface LevenshteinDistance : NSObject //Inherits from NSObject
{
    double changeRatio; 
    bool acceptableChange;
    
}

- (LevenshteinDistance*)init;

+ (int) min:(int)first and:(int)second and:(int)third;

- (void) measureChangeRatio:(int)numberOfChanges andStringLenght:(int)stringLength;

+ (bool) substitutionCost:(char)a and:(char)b;

+ (int) computeDistance:(NSString*)firstString andSecond:(NSString*)secondString andCurrentInstance:(LevenshteinDistance*)instance;

- (bool) isAcceptableChange;

@end

#endif /* LevenshteinDistance_h */
