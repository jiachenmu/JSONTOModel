//
//  Animals.h
//  CMGCD
//
//  Created by jiachenmu on 16/7/14.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

//test json
 
/*
 *

 {\"dog\":[{\"name\":\"dog_1\",\"age\":15,\"dog_pig\":{\"name\":\"dogAndPig1\",\"age\":666}},{\"name\":\"dog_2\",\"age\":null,\"dog_pig\":null}],\"pig\":[{\"name\":\"pig_1\",\"age\":10},{\"name\":\"pig_2\",\"age\":12}]}
**/

#import <Foundation/Foundation.h>

#import "NSObject+CMModel.h"

#import "Dog.h"
#import "Pig.h"


@interface Animals : NSObject

@property (strong, nonatomic) NSArray <Dog *> *dogs;
@property (strong, nonatomic) NSArray <Pig *> *pigs;


@end
