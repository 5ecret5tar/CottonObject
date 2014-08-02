//******************************************************************************
//  CottonObject - a thin wrapper around NSDictionary to make life better with
//  JSON (and other) network objects.  For more details, checkout the github
//  for this project http://github.com/hermiteer/CottonObject
//
//  Created by Christoph on 6/22/14.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Hermiteer, LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//******************************************************************************

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

//------------------------------------------------------------------------------

#import "CottonObject.h"
#import <objc/runtime.h>

//------------------------------------------------------------------------------

@interface CottonObject()

// internally the dictionary is mutable
// but publically exposed as readonly
@property (nonatomic, strong) NSMutableDictionary* mutableDictionary;

@end

//------------------------------------------------------------------------------

@implementation CottonObject

//------------------------------------------------------------------------------

- (instancetype) init
{
    self = [super init];
    if (self != nil)
    {
        _mutableDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

//------------------------------------------------------------------------------

- (instancetype) initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    if (self != nil)
    {
        ZAssert(dictionary != nil, @"Cannot be instanced with a nil dictionary");
        _mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    }
    return self;
}

//------------------------------------------------------------------------------

- (NSDictionary*) dictionary
{
    return self.mutableDictionary;
}

//------------------------------------------------------------------------------

- (NSString*) description
{
    return self.dictionary.description;
}

//------------------------------------------------------------------------------

- (BOOL) dictionaryMatchesDeclaredProperties
{
    // TODO
    // this might need to walk the inheritance chain
    // if there are subclasses of subclasses of CottonObject
    // read all the properties from the object
    unsigned int count;
    objc_property_t* properties = class_copyPropertyList(self.class, &count);
    NSMutableArray* keys = [NSMutableArray array];
    for (int i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        const char* propertyName = property_getName(property);
        NSString* key = [NSString stringWithUTF8String:propertyName];
        [keys addObject:key];
    }

    // if the dictionary matches the declared properties
    // then interestion of the two would be empty
    NSMutableSet* keysSet = [NSMutableSet setWithArray:keys];
    [keysSet minusSet:[NSSet setWithArray:self.dictionary.allKeys]];
    return (keysSet.count == 0);
}

//------------------------------------------------------------------------------
#pragma mark - NSCoding support
//------------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder*)aCoder
{
    if (self.dictionary != nil)
    {
        [self.dictionary encodeWithCoder:aCoder];
    }
}

//------------------------------------------------------------------------------

- (id) initWithCoder:(NSCoder*)aDecoder
{
    NSDictionary* dictionary = [[NSDictionary alloc] initWithCoder:aDecoder];
    return [self initWithDictionary:dictionary];
}

//------------------------------------------------------------------------------
#pragma mark - Getters by NSString key
//------------------------------------------------------------------------------

- (BOOL) boolForKey:(NSString*)key
{
    NSNumber* boolNumber = [self objectWithClass:NSNumber.class forKey:key];
    return boolNumber.boolValue;
}

//------------------------------------------------------------------------------

- (CGFloat) floatForKey:(NSString*)key
{
    NSNumber* floatNumber = [self objectWithClass:NSNumber.class forKey:key];
    return floatNumber.floatValue;
}

//------------------------------------------------------------------------------

- (NSInteger) integerForKey:(NSString*)key
{
    NSNumber* integerNumber = [self numberForKey:key];
    return integerNumber.integerValue;
}

//------------------------------------------------------------------------------

- (NSNumber*) numberForKey:(NSString*)key
{
    // already a number
    NSNumber* number = [self objectWithClass:NSNumber.class forKey:key];
    if (number != nil)
    {
        return number;
    }
    
    // number from a string
    NSString* stringValue = [self objectWithClass:NSString.class forKey:key];
    if (stringValue)
    {
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        number = [formatter numberFromString:stringValue];
    }
        
    // if this far then not a number
    return number;
}

//------------------------------------------------------------------------------

- (SEL) selectorForKey:(NSString*)key
{
    NSString* selectorString = [self stringForKey:key];
    SEL selector = (selectorString != nil ? NSSelectorFromString(selectorString) : nil);
    return selector;
}

//------------------------------------------------------------------------------

- (NSString*) stringForKey:(NSString*)key
{
    return [self objectWithClass:NSString.class forKey:key];
}

//------------------------------------------------------------------------------

- (NSUInteger) unsignedIntegerForKey:(NSString*)key
{
    return [self numberForKey:key].unsignedIntegerValue;
}

//------------------------------------------------------------------------------

- (NSURL*) urlForKey:(NSString*)key
{
    NSString* urlString = [self stringForKey:key];
    NSURL* url = (urlString != nil ? [NSURL URLWithString:urlString] : nil);
    return url;
}

//------------------------------------------------------------------------------
#pragma mark Getters by SEL
//------------------------------------------------------------------------------

- (BOOL) boolForGetter:(SEL)getter                      { return [self boolForKey:NSStringFromSelector(getter)]; }
- (CGFloat) floatForGetter:(SEL)getter                  { return [self floatForKey:NSStringFromSelector(getter)]; }
- (NSInteger) integerForGetter:(SEL)getter              { return [self integerForKey:NSStringFromSelector(getter)]; }
- (NSNumber*) numberForGetter:(SEL)getter               { return [self numberForKey:NSStringFromSelector(getter)]; }
- (SEL) selectorForGetter:(SEL)getter                   { return [self selectorForKey:NSStringFromSelector(getter)]; }
- (NSString*) stringForGetter:(SEL)getter               { return [self stringForKey:NSStringFromSelector(getter)]; }
- (NSURL*) urlForGetter:(SEL)getter                     { return [self urlForKey:NSStringFromSelector(getter)]; }
- (NSUInteger) unsignedIntegerForGetter:(SEL)getter     { return [self unsignedIntegerForKey:NSStringFromSelector(getter)]; }

//------------------------------------------------------------------------------
#pragma mark Setters by NSString key
//------------------------------------------------------------------------------

- (void) setBool:(BOOL)value forKey:(NSString*)key
{
    NSNumber* valueNumber = @(value);
    self.mutableDictionary[key] = valueNumber;
}

//------------------------------------------------------------------------------

- (void) setFloat:(CGFloat)value forKey:(NSString*)key
{
    NSNumber* valueNumber = @(value);
    self.mutableDictionary[key] = valueNumber;
}

//------------------------------------------------------------------------------

- (void) setInteger:(NSInteger)value forKey:(NSString*)key
{
    NSNumber* valueNumber = @(value);
    self.mutableDictionary[key] = valueNumber;
}

//------------------------------------------------------------------------------

- (void) setNumber:(NSNumber*)value forKey:(NSString*)key
{
    self.mutableDictionary[key] = value;
}

//------------------------------------------------------------------------------

- (void) setSelector:(SEL)selector forKey:(NSString*)key
{
    self.mutableDictionary[key] = NSStringFromSelector(selector);
}

//------------------------------------------------------------------------------

- (void) setString:(NSString*)value forKey:(NSString*)key
{
    self.mutableDictionary[key] = value;
}

//------------------------------------------------------------------------------

- (void) setUrl:(NSURL*)url forKey:(NSString*)key
{
    self.mutableDictionary[key] = url.absoluteString;
}

//------------------------------------------------------------------------------

- (void) setUnsignedInteger:(NSUInteger)value forKey:(NSString*)key
{
    NSNumber* valueNumber = @(value);
    self.mutableDictionary[key] = valueNumber;
}

//------------------------------------------------------------------------------
#pragma mark Setters by SEL
//------------------------------------------------------------------------------

- (void) setBool:(BOOL)value forSetter:(SEL)setter
{
    NSNumber* number = @(value);
    [self setObject:number forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setFloat:(CGFloat)value forSetter:(SEL)setter
{
    NSNumber* number = @(value);
    [self setObject:number forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setInteger:(NSInteger)value forSetter:(SEL)setter
{
    NSNumber* number = @(value);
    [self setObject:number forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setNumber:(NSNumber*)value forSetter:(SEL)setter
{
    [self setObject:value forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setSelector:(SEL)selector forSetter:(SEL)setter
{
    [self setObject:NSStringFromSelector(selector) forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setString:(NSString*)value forSetter:(SEL)setter
{
    [self setObject:value forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setUrl:(NSURL*)url forSetter:(SEL)setter
{
    [self setObject:url forSetter:setter];
}

//------------------------------------------------------------------------------

- (void) setUnsignedInteger:(NSUInteger)value forSetter:(SEL)setter
{
    NSNumber* number = @(value);
    [self setObject:number forSetter:setter];
}

//------------------------------------------------------------------------------
#pragma mark - Readwrite property support
//------------------------------------------------------------------------------

- (void) setObject:(id)object forSetter:(SEL)setter
{
    // key must be at least a 4 character string
    NSString* key = NSStringFromSelector(setter);
    ZAssert(key.length >= 4, @"Setter '%@' must be at least 4 characters long", key);

    // validate it for the form setBlah:
    NSArray* tokens = [key componentsSeparatedByString:@":"];
    ZAssert(tokens.count == 2, @"Setter '%@' can only have one argument", key);
    ZAssert([key hasPrefix:@"set"], @"Setter '%@' must start with 'set'", key);

    // strip the set and : from the name
    NSRange range = NSMakeRange(3, key.length - 4);
    key = [key substringWithRange:range];

    // turn the first character into a lower case letter
    NSString* character = [key substringToIndex:1];
    key = [key stringByReplacingOccurrencesOfString:character
                                         withString:character.lowercaseString];

    // insert the non-nil object into the mutable dictionary
    if (object != nil)
    {
        self.mutableDictionary[key] = object;
    }

    // otherwise remove it from the mutable dictionary
    else
    {
        [self.mutableDictionary removeObjectForKey:key];
    }
}

//------------------------------------------------------------------------------
#pragma mark - Factory methods
//------------------------------------------------------------------------------

+ (NSArray*) arrayFromArray:(NSArray*)array withClass:(Class)aClass
{
    // this only supports making arrays of CottonObject subclasses
    // this is what allows parent-child CottonObject classes to be instanced
    ZAssert([aClass isMemberOfClass:CottonObject.class] == NO,
            @"Class '%@' must be a subclass of CottonObject",
            NSStringFromClass(aClass));

    // if a nil array is specified
    // then a non-nil but zero length array will be returned
    NSMutableArray* newArray = [NSMutableArray arrayWithCapacity:array.count];

    // it's important to note that this only works with
    // classes that support initWithDictionary which happens
    // to be the CottonObject subclasses, if an unsupported class
    // is specified, this will probably blow up with a runtime error
    for (NSDictionary* dictionary in array)
    {
        id object = [[aClass alloc] initWithDictionary:dictionary];
        [newArray addObject:object];
    }

    // done
    return newArray;
}

//------------------------------------------------------------------------------

- (NSArray*) arrayWithClass:(Class)objectClass forKey:(NSString*)key
{
    // make sure the value is an array
    NSArray* array = self.dictionary[key];
    if ([array isKindOfClass:NSArray.class] == NO)
    {
        return nil;
    }

    // nothing else to do if empty
    if (array.count == 0)
    {
        return array;
    }

    // check the first element in the array
    // if it's of the specified class then nothing to do
    if ([[array.firstObject class] isSubclassOfClass:objectClass])
    {
        return array;
    }

    // create the array and backfill into the parent dictionary
    NSArray* classedArray = [CottonObject arrayFromArray:array withClass:objectClass];
    return classedArray;
}

//------------------------------------------------------------------------------

- (id) objectWithClass:(Class)objectClass forKey:(NSString*)key
{
    // get the instance for the key
    id value = self.dictionary[key];
    if (value == nil)
    {
        return nil;
    }

    // test the value for class type
    BOOL isDictionary = ([value isKindOfClass:NSDictionary.class]);
    BOOL isDesiredClass = [value isKindOfClass:objectClass];

    // nothing to do if already the desired class
    // or if it is not a dictionary
    if (isDesiredClass) { return value; };
    ZAssert(isDictionary, @"Value for key '%@' is not an NSDictionary", key);

    // TODO
    // need to make sure this is an CottonObject subclass
    // make an instance of the class with the confirmed dictionary
    id object = [[objectClass alloc] initWithDictionary:value];

    // update the dictionary with the class instance to avoid
    // the same work in the future, but note that this will NOT
    // update the object if it's cached to storage somewhere
    // doing so is architecturally messy from here and it's
    // probably slower than just instancing the property's class
    self.mutableDictionary[key] = object;

    // done
    return object;
}

//------------------------------------------------------------------------------

@end