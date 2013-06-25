//
//  Cluster.h
//  TableTopDebug
//
//  Created by Brian Dolhansky on 6/5/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef __TableTopDebug__Cluster__
#define __TableTopDebug__Cluster__

#include <iostream>
#include <opencv2/opencv.hpp>

using namespace cv;

class Cluster
{
public:
    Cluster();
    Mat getData();
    void setData(Mat data);

private:
    Mat data;
    
};


#endif /* defined(__TableTopDebug__Cluster__) */
