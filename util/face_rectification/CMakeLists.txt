cmake_minimum_required(VERSION 2.6)
project(cis580_hw4)

# Dependencies
find_package(OpenCV 2.4 REQUIRED core imgproc highgui)

# configure a header file which will help load images from the
# images/ folder
#file(TO_NATIVE_PATH "${PROJECT_SOURCE_DIR}/images/" IMAGES_PATH)
#configure_file(
#  "${PROJECT_SOURCE_DIR}/include/config.h.in"
#  "${PROJECT_BINARY_DIR}/config.h"
#)

# set the default path for includes
include_directories(
  ${OpenCV_INCLUDE_DIRS}
  "${PROJECT_SOURCE_DIR}/include"
  "${PROJECT_BINARY_DIR}"
)

add_executable(face_rectification src/face_rectification.cpp)
target_link_libraries(face_rectification ${OpenCV_LIBS})
