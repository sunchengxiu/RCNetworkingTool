//
//  RCQueryModel.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/10.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCQueryModel.h"

/**
 字符串进行百分号编码，防止有特殊字符
 
 @param string 字符串
 @return 编码后的字符串
 */
NSString * RCPercentEscapedStringFromString(NSString *string) {
    static NSString * const kRCCharactersGeneralDelimitersToEncode = @":#[]@";
    static NSString * const kRCCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kRCCharactersGeneralDelimitersToEncode stringByAppendingString:kRCCharactersSubDelimitersToEncode]];
    static NSUInteger const batchSize = 50;
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        index += range.length;
    }
    return escaped;
}
@implementation RCQueryModel
-(instancetype)initWithField:(id)field value:(id)value{
    if (self = [super init]) {
        self.field =field;
        self.value = value;
    }
    return self;
}
-(NSString *)encodeQuery{
    if (!self.value || [self.value isEqual:[NSNull class]]) {
        return RCPercentEscapedStringFromString([self.field description]);
    } else {
        // name=sun
        return [NSString stringWithFormat:@"%@=%@",RCPercentEscapedStringFromString(self.field),RCPercentEscapedStringFromString(self.value)];
    }
}


@end
