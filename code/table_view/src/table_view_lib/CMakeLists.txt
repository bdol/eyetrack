set(table_view_lib_sources 
    Box3D.cpp
    Cluster.cpp
    KinectCalibParams.cpp
    KinectUtilities.cpp
    MutexWrapper.cpp
    MyFreenectDevice.cpp
    TableObjectDetector.cpp
    TableObject.cpp)

add_library(table_view_lib ${table_view_lib_sources})
