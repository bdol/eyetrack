# This project requires OpenCV and libfreenect
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
set(LIBS ${LIBS} ${OpenCV_LIBRARIES})

# This project includes a custom macro to find libfreenect
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules")
find_package(Freenect REQUIRED)
include_directories(${Freenect_INCLUDE_DIRS})
set(LIBS ${LIBS} ${Freenect_LIBRARIES})

# Define the global include path
include_directories("${PROJECT_SOURCE_DIR}/include")

# Include the source code for FaceTracker, libsvm and the head pose estimator
add_subdirectory(table_view_lib)
add_subdirectory(socket)
add_subdirectory(eye_gaze_lib)

set(table_view_main_sources main.cpp)

# Link the required libraries (OpenCV, freenect, face_tracker and libsvm) to the exectuable
add_executable(table_view ${table_view_main_sources})
target_link_libraries(table_view ${LIBS} table_view_lib socket eyegaze)

