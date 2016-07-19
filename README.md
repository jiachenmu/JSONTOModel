# JSONTOModel
ManoBoo(iOS 如何写一个son转Model工具)文中的Demo

---

#前言
---
###好久没有写过新文章了，最近一直在忙工作的事情，我的新浪微博开源项目也停止了一周时间，目前完成了60%，就先写一篇关于JSON转Model的文章和大家聊聊天吧，为什么会写一个这个小工具呢，请看文末😄
---

#核心方法Runtime的介绍
---
##1. Runtime是什么？

顾名思义：Runtime就是运行时的意思，是系统在运行时的一些机制，其中最主要的就是消息机制，举个常用的例子，在面向对象编程的语言中，万物皆对象，对象如何调用方法呢，
`[target excuteSEL]`,需要一个对象，需要一个方法名，系统在运行时会自动转换成以下的形式：
`objc_msgSend(target,@selector(excuteSEL:))`

关于Runtime的详细介绍，网上有很多，这里就不做过多描述了。

---

##2.Runtime的常见用法
注:使用时需要`#import <objc/objc-runtime.h>`

### * 1 方法替换(黑魔法)
举个例子来说明一下：
将调用A方法替换为调用B方法
```
class_replaceMethod([self class], @selector(sendAMessage:), (IMP)changeAtoB, NULL);

//MARK: 方法替换_1
- (void)sendAMessage:(NSString *)message {
    NSLog(@"A_message: %@",message);
}

- (void)sendBMessage:(NSString *)message {
    NSLog(@"B_Message: %@",message);
}

ViewController * changeAtoB(ViewController *SELF, SEL _cmd, NSString *message) {
   
    if ([NSStringFromSelector(_cmd) isEqualToString:@"sendAMessage:"]) {
        //将方法进行替换
        [SELF sendBMessage:message];
    }
    return SELF;
}
//这里IMP可以理解为魔法通道，将源方法通过IMP指针转换为目标方法
```
### * 2 获取对象的属性和方法
 
注：获取对象的属性，这个方法在JSON转Model可以说是核心方法了
举例说明：
```
//class_copyPropertyList 这个方法会获取到一个类.h和.m文件中interface中的所有属性

//获取CMGCD类的属性名称
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([CMGCD class], &count);
    for (unsigned int i = 0; i < count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSLog(@"property ---> %@",[NSString stringWithUTF8String:propertyName]);
    }
```
```
//
unsigned int count;
Method *methodList = class_copyMethodList([CMGCD class], &count);
    for (unsigned int i; i < count; i++) {
        Method method = methodList[i];
        NSLog(@"Method ---> %@",NSStringFromSelector(method_getName(method)));
    }
```
---

### * 2 设置对象关联
定义：关联是指把两个对象相互关联起来，使其中的一个对象作为另外一个对象的一部分
再举个例子，我在对象中定义了一个属性
```
@property (strong, nonatomic) NSString *content;
```
```
//设置对象属性关联
static char associatedKey;
    objc_setAssociatedObject(self, &associatedKey, @"content_yeah", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSString *get_content = objc_getAssociatedObject(self, &associatedKey);
    NSLog(@"content = %@",get_content);

```
**Tips:**设置对象关联需要以下几个要点：
`源对象`、`关键字`、`关联的对象` `关联策略`
**解释一下：**这里我将`@"content_yeah"`这个对象与`self`使用`OBJC_ASSOCIATION_RETAIN_NONATOMIC`策略关联到一起，意思就是在`self`的生命周期之内关联的对象都不会被释放，通过这个方法，可以实现动态向类里面添加属性
另外还有一些关联的方法，如

 - 断开关联： 设置关联对象为`nil`即可
`objc_setAssociatedObject(self, &associatedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); `

 - 断开这个对象的所有关联关系
 
```
//断开所有关联
    objc_removeAssociatedObjects(self);
```

---

#JSON转Model工具的主要介绍

---
## 1. 为什么会写这样一个工具
很多时候我们并不是缺少实力，而且是缺少一种**`彼可取而代之`**的勇气，为什么会有`MJExtension`、`YYModel`的产生,查看源代码的过程中我有种想死的感觉，但是知道实现的原理后，为什么不能自己去实现一个呢？这个工具的源代码非常简单，我写这个工具的目的只是为了告诉朋友们，真的不复杂，不要因为看着复杂就放弃了自己动手的冲动

## 2. 工具的整体步骤简介
着重介绍一下我的思考过程

 - 1 核心方法？
    利用Runtime可以遍历出对象的所有属性，然后利用递归的思想逐层解析JSON
 - 2 怎么去做？
    基本所有的Model继承`NSObject`，我们可以写一个`NSObject`的`Category`，然后在其中写一些解析方法，我们需要一个对照JSON字符串的解析路径字典，比如说`JSON`的`狗`的属性名称为`dog`,我们的对象属性名称想定义为`xiaogou`，这就需要手写一个字典将解析中遇到的`dog`都给映射为`xiaogou`
 - 3 开始动手吧


---
## 3. 主要代码介绍：
---
### * 1 `NSObject+CMModel` 介绍

```
//NSObject+CMModel.h 
// 单个对象
- (NSDictionary *)dict_CMModelWithClass;

// 对象数组
- (NSDictionary *)dict_CMModelWIthArrayClass;

- (instancetype)cm_initWithJSONString:(NSString *)jsonString;

```
下面着重解释一下.m文件中的内容
```
//NSObject+CMModel.m
#import <objc/runtime.h>
#import "CMObject.h"
#import "CMProperty.h"

//返回单个对象的解析字典，默认为nil
- ( NSDictionary * _Nullable )dict_CMModelWithClass {
    return nil;
}

//返回对象数组的解析字典，默认为nil
- (NSDictionary *)dict_CMModelWIthArrayClass {
    return nil;
}

//调用方法
- (instancetype)cm_initWithJSONString:(NSString *)jsonString {
    if (self) {
        [self analysisWitnJsonString:jsonString];
    }
    return self;
}

```

 **取得对象的所有属性及其对应的类型**
 Tips: 这里自己写了一个类，将对象的属性及其名称封装到一个类型为`CMProperty`的数组

* 1 **CMProperty类简介**

```
//属性名称
@property (strong, nonatomic) NSString *propertyName;

//属性的类
@property (strong, nonatomic) Class propertyClass;

//是否基本类型
@property (assign, nonatomic) BOOL isBasicType;

```

 * 2 **获取对象属性及其类型，并且将其封装为类型为`CMProperty`的数组**

```
 //将该类的属性和对应的类型进行封装
- (NSArray <CMProperty *> *)propertyArray {
    NSMutableArray *propertyArray = [NSMutableArray array];
    
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (unsigned int i = 0; i < count; i++) {
        CMProperty *property = [[CMProperty alloc] init];
        property.propertyName = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        
        NSString *attrs = @(property_getAttributes(propertyList[i]));

        NSUInteger dotLoc = [attrs rangeOfString:@","].location;
        NSString *propertyType = nil;
        NSUInteger loc = 1;
        if (dotLoc == NSNotFound) { // 没有找到
            propertyType = [attrs substringFromIndex:loc];
        }else {
            propertyType = [attrs substringWithRange:NSMakeRange(loc, dotLoc - loc)];
            if ([propertyType isEqualToString:@"Q"]) {
                //基本类型
                property.isBasicType = true;
            }else {
                propertyType = [propertyType substringWithRange:NSMakeRange(2, propertyType.length - 3)];
            }
        }

        property.propertyClass = NSClassFromString(propertyType);
    
        [propertyArray addObject:property];
    }
    
    free(propertyList);
    
    return propertyArray;
}
```

**开始解析**
```
//进行解析
- (void)analysisWitnJsonString:(NSString *)json {
    
    //存在解析字典
    if ([self dict_CMModelWithClass] != nil || [self dict_CMModelWIthArrayClass] != nil) {
        CMObject *analysisTools = [[CMObject alloc] initWithGoalObject:self CMPropertyArray:[self propertyArray]];
        if ([self dict_CMModelWIthArrayClass]) {
            analysisTools.analysisObjectArrayDict = [self dict_CMModelWIthArrayClass];
        }
        if ([self dict_CMModelWithClass]) {
            analysisTools.analysisDict = [self dict_CMModelWithClass];
        }
        analysisTools.jsonString = json;
    }
}
```

### * 2 `CMObject` 介绍
这个类为实际进行解析工具的类，或者可以称之为工具,这里我们需要特殊对待`NSArray`、`NSDictionary`、`int、float等基本类型`

```
//CMObject.h

//要解析的对象
@property (strong, nonatomic) id object;

//解析key对应列表 单个对象
@property (strong, nonatomic) NSDictionary *analysisDict;

//解析key对应列表 对象数组
@property (strong, nonatomic) NSDictionary *analysisObjectArrayDict;

//属性列表
@property (strong, nonatomic) NSArray <CMProperty *> *propertyArray;

//init方法
- (instancetype)initWithGoalObject:(id)object CMPropertyArray:(NSArray <CMProperty *> *)propertyArray;

//解析的源JSON
@property (strong, nonatomic) NSString *jsonString;


BOOL Exist_(id obj,NSArray *existArray);

```
**Tips:** 下面代码可能看着会不舒服，我说一下整体的思路

#### * 1 `NSObject+CMModel`中将封装的属性数组传递过来，我们一个接一个的对属性进行遍历构造
#### * 2 遍历详解：举例，碰到`NSArray`的属性时，我们去看要解析的类中实现的`- (NSDictionary *)dict_CMModelWIthArrayClass`这个方法，找到目的对象的类型`OBJClass`，然后将`JSON字典`拆分后利用`- (instancetype)cm_initWithJSONString:(NSString *)jsonString`这个方法创建一个`OBJClass`类型的对象，并且添加到数组中，创建完后，使用`KVC`将数组赋给源对象，具体代码看下面
```
//CMObject.m
//这里说一下解析方法, 代码较多
//开始进行model解析
- (void)analysisModel {
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[_jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];

    //将`NSObject+CMModel`中获取的属性数组进行遍历构造，并赋值给对应的属性
    [_propertyArray enumerateObjectsUsingBlock:^(CMProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //单独处理数组类型
        if (obj.propertyClass == [NSArray class]) {
            //  对象为数组类型，
            NSString *key = [_analysisObjectArrayDict objectForKey:obj.propertyName];

            Class OBJClass = NSClassFromString(key);
        
            if (![jsonDict objectForKey:key]) {
                //名称与json中的名称并不相符
                if ([_analysisDict objectForKey:obj.propertyName]) {
                    NSMutableArray *objectArray = [NSMutableArray array];
                    
                    NSArray *obj_json_array = [jsonDict objectForKey:[_analysisDict objectForKey:obj.propertyName]];
                    [obj_json_array enumerateObjectsUsingBlock:^(NSDictionary   * _Nonnull obj_dict, NSUInteger idx, BOOL * _Nonnull stop) {
                        id objx = [[OBJClass alloc] cm_initWithJSONString:DataToJSONString(obj_dict)];
                        //解析好对象之后，存到数据中
                        [objectArray addObject:objx];
                        
                    }];
                    [_object setValue:objectArray forKey:obj.propertyName];
                }else {
                    
                }
            }
        }else if (Exist_(obj.propertyClass, @[[NSDictionary class],[NSMutableDictionary class]])) {
            NSDictionary *obj_dict = [jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]];
            if (!obj_dict) {
                [_object setValue:[NSNull null] forKey:obj.propertyName];
            }else {
                [_object setValue:obj_dict forKey:obj.propertyName];
            }
        }else if (obj.isBasicType){
            //基本类型
            id num = [jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]];
            if (!num || num == [NSNull null]) {
                //为空判断
                //这里我们默认设置为 0.00大小的NSNumber对象 
                [_object setValue:NULL_NUM forKey:obj.propertyName];
            }else {
                NSNumber *number = (NSNumber *)num;
                [_object setValue:number forKey:obj.propertyName];
            }
        }else {
            Class OBJClass = obj.propertyClass;
            if(!Exist_(OBJClass, foundationClasses_)) {
                //如果类型为自定义类
                id obj_dict = [jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]];
                //非空判断
                if (!obj_dict) {
                    id objx = [[OBJClass alloc] cm_initWithJSONString:DataToJSONString(obj_dict)];
                    [_object setValue:objx forKey:obj.propertyName];
                }else {
                    //这里可以赋值为[NSNull null] 可以赋值为一个新对象
//                    [_object setValue:[NSNull null] forKey:obj.propertyName];
                    [_object setValue:[[OBJClass alloc] init] forKey:obj.propertyName];
                }
            }else {
                [_object setValue:[jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]] forKey:obj.propertyName];
            }
        }
    }];
}

```

---
## 4. 如何使用
---
举例说明：
这里有三个类
**Animals(动物)**
```
@property (strong, nonatomic) NSArray <Dog *> *dogs;
@property (strong, nonatomic) NSArray <Pig *> *pigs;
```
---实现方法：
```
- (NSDictionary *)dict_CMModelWithClass {
    return @{
             @"dogs" : @"dog",
             @"pigs" : @"pig",
             };
}

- (NSDictionary *)dict_CMModelWIthArrayClass {
    return @{
             @"dogs" : @"Dog",
             @"pigs" : @"Pig",
             };
}
```

**Dog(狗)**
```
@property (strong, nonatomic) NSString *dog_name;
@property (assign, nonatomic) NSUInteger dog_age;

//狗养的猪
@property (strong, nonatomic) Pig *dog_pig;
```
---实现方法
```
- (NSDictionary *)dict_CMModelWithClass {
    return @{
             @"dog_age" : @"age",
             @"dog_name" : @"name",
             @"dog_pig" : @"dog_pig"
             };
}
```
**Pig(猪)**
```
@property (strong, nonatomic) NSString *pig_name;
@property (assign, nonatomic) NSUInteger pig_age;
```
---实现方法
```
- (NSDictionary *)dict_CMModelWithClass {
    return @{
             @"pig_age" : @"age",
             @"pig_name" : @"name"
             };
}
```
**调用方法**
```
NSString *testJSON = @"{\"dog\":[{\"name\":\"dog_1\",\"age\":15,\"dog_pig\":{\"name\":\"dogAndPig1\",\"age\":666}},{\"name\":\"dog_2\",\"age\":null,\"dog_pig\":null}],\"pig\":[{\"name\":\"pig_1\",\"age\":10},{\"name\":\"pig_2\",\"age\":12}]}";

Animals *animals = [[Animals alloc] cm_initWithJSONString:testJSON];
```

#写在后面的话
这个项目并不完善，比如说对于其中日期的格式化，非空的一些判断等，其中也有一些bug，本文权当是抛砖引玉，利用`Runtime`可以做很多事情，比如你可以实现，一句话完成归档与解归档，不会再出现Model属性过多时重写`initWithCoder`和`encodeWithCoder`的尴尬了，so，有时候我们更缺的是一种思考问题的方式，共勉！

PS：欢迎来我的简书、Github、个人博客交流😄
>[文中的Demo下载地址](https://github.com/jiachenmu/JSONTOModel)

>[我的简书](http://www.jianshu.com/users/232094594d02/latest_articles)
