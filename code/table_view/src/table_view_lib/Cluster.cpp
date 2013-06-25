//
//  Cluster.cpp
//  TableTopDebug
//
//  Created by Brian Dolhansky on 6/5/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <table_view_lib/Cluster.h>

Cluster::Cluster() {
    
}

Mat Cluster::getData() {
    return data;
}

void Cluster::setData(Mat data) {
    this->data = data;
}
