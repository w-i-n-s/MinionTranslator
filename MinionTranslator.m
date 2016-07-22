//
//  MinionTranslator.m
//  MinionLanguageTranslator
//
//  Created by Sergey Vinogradov
//

#import "MinionTranslator.h"
#include <stdlib.h>
#import <malloc/malloc.h>

static NSString* kClearedFlag = @"";

@interface MinionTranslator()

@property (strong, nonatomic) NSDictionary *vocabulary;

@end

@implementation MinionTranslator

static NSArray *nonTranslateWordList() {
    static NSArray *array = nil;
    if (!array) {
        array = @[@"poo",@"too",@"goo",@"qi",@"wa",@"ere",@"tot",@"yok",@"uta",@"ipe",@"ore",@"pok",@"ata",@"si",@"du",@"hea",@"ku",@"lo",@"vaa",@"but",@"ne",@"moo"];
    }
    return array;
}

static NSArray *symbolsForClear() {
    static NSArray *array = nil;
    if (!array) {//according to keyboard from top to bottom
        array = @[@"±",@"!",@"/@",@"#",@"$",@"%",@"^",@"&",@"*",@"(",@")",@"_",@"+",
                  @"§",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0",@"-",@"=",
                  @"[",@"]",@"{",@"}",@":",@"\"",@"|",@";",@"'",@"\\",
                  @"~",@"<",@">",@"?",@"`",@",",@".",@"/",
                  @"\n",@"€",@"£"];
    }
    return array;
}

+ (instancetype)sharedTranslator{

    static MinionTranslator *translator = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        translator = [[MinionTranslator alloc] init];
    });
    
    return translator;
}

- (instancetype)init {
    if (self = [super init]) {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"minionVocab" ofType:@"plist"];
        self.vocabulary = [[NSDictionary alloc] initWithContentsOfFile:bundle];
    }
    return self;
}

#pragma mark - Public

- (NSString*)translateText:(NSString*)originText {

    NSString *trimString = [self trimString:originText];
    NSArray *originList = [trimString componentsSeparatedByString:@" "];
    
    BOOL capitalized;
    NSRange rangeOfClearString;
    NSUInteger suffixIndex;
    NSString *prefix,*suffix,*origin,*lowercaseOrigin,*clean,*translated,*result = @"";
    for (int i=0; i<[originList count]; i++) {
        
        origin = [originList objectAtIndex:i];
        if ([origin isEqualToString:@""]) {
            continue;
        }
        lowercaseOrigin = [origin lowercaseString];
        
        prefix = @"";
        suffix = @"";
        clean = [self cleanString:origin];
        capitalized = [clean isEqualToString:[clean capitalizedString]];
        clean = [clean lowercaseString];
        
        if ([clean isEqualToString:@""]) {
            translated = origin;
        } else {
            translated = [self.vocabulary objectForKey:clean];
            if (!translated) {
                translated = [self randomTranslationForString:translated];
            }
            
            if (![clean isEqualToString:lowercaseOrigin]) {
                
                rangeOfClearString = [lowercaseOrigin rangeOfString:clean];
                
                if (rangeOfClearString.location == NSNotFound) {
                    translated = origin;
                } else {
                    prefix = [origin substringToIndex:rangeOfClearString.location];
                    suffixIndex = rangeOfClearString.location+rangeOfClearString.length;
                    suffix = [origin substringFromIndex:(suffixIndex)];
                }
            }
        }
        
        result = [result stringByAppendingFormat:@"%@%@%@ ",
                  prefix,
                  (capitalized)?[translated capitalizedString]:translated,
                  suffix];
    }
    
    if (result.length && result.length>2) {
        result = [result substringToIndex:(result.length-1)];
    }
    
    return result;
}

- (NSString*)backTranslateText:(NSString*)originText {
    
    NSString *trimString = [self trimString:originText];
    NSArray *originList = [trimString componentsSeparatedByString:@" "];
    
    BOOL capitalized;
    NSRange rangeOfClearString;
    NSUInteger suffixIndex;
    NSString *prefix,*suffix,*origin,*lowercaseOrigin,*clean,*translated,*result = @"";
    NSArray *array;
    for (int i = 0; i<[originList count]; i++) {
        
        origin     = [originList objectAtIndex:i];
        if ([origin isEqualToString:@""]) {
            continue;
        }
        lowercaseOrigin = [origin lowercaseString];
        
        prefix = @"";
        suffix = @"";
        clean = [self cleanString:origin];
        capitalized = [clean isEqualToString:[clean capitalizedString]];
        clean = [clean lowercaseString];
        
        if ([clean isEqualToString:@""]) {
            translated = origin;
        } else {
            if ([nonTranslateWordList() containsObject:clean]) {
                translated = origin;
            } else {
                array = [self.vocabulary allKeysForObject:clean];
                
                if ([array count]) {
                    translated = [array firstObject];
                    if (![clean isEqualToString:lowercaseOrigin]) {
                        
                        rangeOfClearString = [lowercaseOrigin rangeOfString:clean];
                        
                        if (rangeOfClearString.location == NSNotFound) {
                            translated = origin;
                        } else {
                            if (![[clean substringToIndex:rangeOfClearString.location] isEqualToString:[origin substringToIndex:rangeOfClearString.location]]) {
                                prefix = [origin substringToIndex:rangeOfClearString.location];
                            }
                            suffixIndex = rangeOfClearString.location+rangeOfClearString.length;
                            if (![[clean substringFromIndex:suffixIndex] isEqualToString:[origin substringFromIndex:(suffixIndex)]]) {
                                suffix = [origin substringFromIndex:(suffixIndex)];
                            }
                        }
                    }
                } else {
                    translated = origin;
                }
            }
        }
        
        result = [result stringByAppendingFormat:@"%@%@%@ ",
                  prefix,
                  (capitalized)?[translated capitalizedString]:translated,
                  suffix];
    }
    
    if (result.length && result.length>2) {
        result = [result substringToIndex:(result.length-1)];
    }
    
    return result;
}

- (NSString*)description {

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.vocabulary forKey:@"dictKey"];
    [archiver finishEncoding];
    
    return [NSString stringWithFormat:@"%@; pairs:%lu size:%.2f kbytes;", [super description],(unsigned long)[[self.vocabulary allKeys] count], data.length/1024.0];
}

#pragma mark - Private

- (NSString *)trimString:(NSString *)string {
    NSString *result = string;
    if (string.length > 0) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:nil];
        result = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@" "];
        
        if (result.length && [[result substringToIndex:1] isEqualToString:@" "]) {
            result = [result substringFromIndex:1];
        }
        
        if (result.length && [[result substringFromIndex:(result.length-1)] isEqualToString:@" "]) {
            result = [result substringToIndex:(result.length-1)];
        }
    }
    return result;
}

- (NSString*)cleanString:(NSString*)sourceString {
    
    NSString *result = [NSString stringWithString:sourceString];
    for (NSString *spSymbol in symbolsForClear()) {
        result = [result stringByReplacingOccurrencesOfString:spSymbol withString:kClearedFlag];
    }
    
    return result;
}

- (NSString*)randomTranslationForString:(NSString*)originString {
    return [nonTranslateWordList() objectAtIndex:arc4random_uniform((int)[nonTranslateWordList() count])];
}

@end
