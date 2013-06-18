project(simple_kinect)
cmake_minimum_required(VERSION 2.8)

# This project requires OpenCV and libfreenect
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
set(LIBS ${LIBS} ${OpenCV_LIBRARIES})

# This project includes a custom macro to find libfreenect
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules")
find_package(Freenect REQUIRED)
include_directories(${Freenect_INCLUDE_DIRS})
set(LIBS ${LIBS} ${Freenect_LIBRARIES})

# Look in the src directory for all source files
set(simple_kinect_sources 
        src/MutexWrapper.cpp 
        src/MyFreenectDevice.cpp
        src/main.cpp)
include_directories(src)

# Link the required libraries to the exectuable
add_executable(simple_kinect ${simple_kinect_sources})
target_link_libraries(simple_kinect ${LIBS})
