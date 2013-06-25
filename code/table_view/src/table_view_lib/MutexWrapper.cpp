//
//  MutexWrapper.cpp
//  TableTop
//
//  Created by Brian Dolhansky on 5/9/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <table_view_lib/MutexWrapper.h>

MutexWrapper::MutexWrapper() {
    pthread_mutex_init( &m_mutex, NULL );
}
void MutexWrapper::lock() {
    pthread_mutex_lock( &m_mutex );
}
void MutexWrapper::unlock() {
    pthread_mutex_unlock( &m_mutex );
}
