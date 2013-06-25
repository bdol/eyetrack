find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
set(LIBS ${LIBS} ${OpenCV_LIBRARIES})

# Define the global include path
include_directories("${PROJECT_SOURCE_DIR}/include")

set(head_pose_sources 
    CRForestEstimator.cpp
    CRTree.cpp
    main.cpp)

# Link the required libraries to the exectuable
add_executable(head_pose ${head_pose_sources})
target_link_libraries(head_pose ${LIBS})

