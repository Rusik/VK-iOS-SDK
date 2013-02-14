//
//  NSString+VK.m
//  vk
//
//  Created by Ruslan Kavetsky on 2/8/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import "NSString+VK.h"

@implementation NSString (VK)

- (NSString *)valueForParameter:(NSString *)param {
    NSRange paramRange = [self rangeOfString:param];
    if (paramRange.location == NSNotFound) {
        return nil;
    }
    NSString __block *result;
    [self enumerateSubstringsInRange:NSMakeRange(paramRange.location, self.length - paramRange.location) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if ([substring isEqualToString:@"&"]) {
            result = [self substringWithRange:
                      NSMakeRange(paramRange.location + paramRange.length + 1, substringRange.location - paramRange.location - paramRange.length - 1)];
            *stop = YES;
        }
    }];
    if (!result) {
        result = [self substringWithRange:
                  NSMakeRange(paramRange.location + paramRange.length + 1, self.length - paramRange.location - paramRange.length - 1)];
    }
    return result;
}

@end
