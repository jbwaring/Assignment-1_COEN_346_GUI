//
//  LevenshteinDistance.m
//  Assignment1_COEN_346
//
//  Created by Jean-Baptiste Waring on 2021-09-22.
//

#ifndef LevenshteinDistance_m
#define LevenshteinDistance_m

#import <Foundation/Foundation.h>
#import "LevenshteinDistance.h"

@implementation LevenshteinDistance : NSObject

// Implementation is a convertion from from Mohhamed Shebab's Java implementation. (Java implementation was already given).

- (LevenshteinDistance*) init {
    self->changeRatio = 0.0;
    self->acceptableChange = false;
    return self;
}


+ (int) min:(int)first and:(int)second and:(int)third { //Helper for a three integer valued minimum function
    return MIN(first, MIN(second, third));
}


- (void) measureChangeRatio:(int)numberOfChanges andStringLenght:(int)stringLength{
    self->changeRatio = 1.0 - (double)numberOfChanges/(double)stringLength;
    
    self->acceptableChange = self->changeRatio > 0.05 ? true : false;
}


+ (bool) substitutionCost:(char)a and:(char)b {
    return  (a == b) ? 0 : 1;
}



+ (int) computeDistance:(NSString*)firstString andSecond:(NSString*)secondString andCurrentInstance:(LevenshteinDistance*)instance {
    int distanceMatrix[firstString.length][secondString.length];

    for(int i = 0; i<=firstString.length; i++){
        for (int j = 0; j <= secondString.length; j++) {
            if (i == 0) {
                distanceMatrix[i][j] = j;
            }else if (j == 0){
                distanceMatrix[i][j] = i;
            }else {

// dp[i][j] = min(dp[i - 1][j - 1] + SubstitutionCost(str1.charAt(i - 1), str2.charAt(j - 1)) ||| dp[i - 1][j] + 1 |||, dp[i][j - 1] + 1);

                int first = distanceMatrix[i - 1][j - 1] + [self substitutionCost:[firstString characterAtIndex: i-1 ] and:[secondString characterAtIndex: j-1 ]];

                int second = distanceMatrix[i - 1][j];
                second += 1;

                int third = distanceMatrix[i][j - 1];
                third += 1;
                distanceMatrix[i][j] = [self min:first and:second and:third];
            }
        }
    }


    [instance measureChangeRatio:(int)distanceMatrix[firstString.length][secondString.length] andStringLenght:(int)firstString.length];

//    NSLog(@"Using mine: %d, using Internet: %d", distanceMatrix[firstString.length][secondString.length],[firstString levenshteinDistanceFromString:secondString]);
    return distanceMatrix[firstString.length][secondString.length];
//    int cost;
//    if ( [firstString  isEqual: @""]) { return [secondString length];}
//    if ( [secondString  isEqual: @""]) { return [firstString length];}
//    if ([firstString characterAtIndex:-1] == [secondString characterAtIndex:-1]) {
//        cost = 0;
//    } else {
//        cost = 1;
//    }
//    int first = [self computeDistance:[firstString substringWithRange:NSMakeRange(0, [firstString length] -1)]
//                             andSecond:secondString andCurrentInstance:instance]+1;
//    int second = [self computeDistance:firstString andSecond:[secondString substringWithRange:NSMakeRange(0, [secondString length] -1)] andCurrentInstance:instance]+1;
//    int third = [self computeDistance:[firstString substringWithRange:NSMakeRange(0, [firstString length] -1)] andSecond:[secondString substringWithRange:NSMakeRange(0, [secondString length] -1)] andCurrentInstance:instance]+cost;
//
////    [instance measureChangeRatio:(int)distanceMatrix[firstString.length][secondString.length] andStringLenght:(int)firstString.length];
//    return [self min:first and:second and:third];
}

- (bool) isAcceptableChange {
    return self->acceptableChange;
}

@end


#endif /* LevenshteinDistance_m */
