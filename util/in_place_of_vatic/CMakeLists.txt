cmake_minimum_required(VERSION 2.6)
project(labeller)

# Dependencies
find_package(OpenCV 2.4 REQUIRED core imgproc highgui calib3d)

# configure a header file which will help load images from the
# images/ folder
file(TO_NATIVE_PATH "${PROJECT_SOURCE_DIR}/images/" IMAGES_PATH)
configure_file(
  "${PROJECT_SOURCE_DIR}/include/config.h.in"
  "${PROJECT_BINARY_DIR}/config.h"
)

# set the default path for includes
include_directories(
  ${OpenCV_INCLUDE_DIRS}
  "${PROJECT_SOURCE_DIR}/include"
  "${PROJECT_BINARY_DIR}"
)

#add_library(${PROJECT_NAME}
#  src/hw4.cpp
#  src/hw4_helpers.cpp
#  )
#target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBS})

#add_executable(hello_opencv src/hello_opencv.cpp)
#target_link_libraries(hello_opencv ${PROJECT_NAME})

add_library(${PROJECT_NAME}
src/label_interest_points.cpp
)
target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBS})

add_executable(label_interest_points src/label_interest_points)
target_link_libraries(label_interest_points ${PROJECT_NAME})

