//
//  MutexWrapper.h
//  TableTop
//
//  Created by Brian Dolhansky on 5/9/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#ifndef __TableTop__MutexWrapper__
#define __TableTop__MutexWrapper__

#include <iostream>
#include <pthread.h>

class MutexWrapper {
public:
	MutexWrapper();
	void lock();
	void unlock();
private:
	pthread_mutex_t m_mutex;
};

#endif /* defined(__TableTop__MutexWrapper__) */
