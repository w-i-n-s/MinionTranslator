//
//  MinionTranslator.h
//  MinionLanguageTranslator
//
//  Created by Sergey Vinogradov
//

#import <Foundation/Foundation.h>

@interface MinionTranslator : NSObject

+ (instancetype)sharedTranslator;

- (NSString*)translateText:(NSString*)originText;
- (NSString*)backTranslateText:(NSString*)originText;

@end
