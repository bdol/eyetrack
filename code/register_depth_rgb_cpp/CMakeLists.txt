cmake_minimum_required(VERSION 2.6)

SET(	REGISTER
		src/main.cpp
)

SET(CMAKE_BUILD_TYPE "Release")

IF(WIN32)

	SET( OPENCV_INCLUDES C:/OpenCV2.3/build/include ) 
	SET( OPENCV_LIB C:/OpenCV2.3/my_build/lib ) 

	SET( OPENNI_INCLUDES "C:/Program Files\ (x86)/OpenNI/Include") 
	SET( OPENNI_LIB "C:/Program Files\ (x86)/OpenNI/Lib") 

	LINK_DIRECTORIES( ${OPENNI_LIB} ${OPENCV_LIB} )

	

ELSE(WIN32)

	SET( OPENCV_INCLUDES /include ) 
	SET( OPENCV_LIB /lib ) 
	
	SET( OPENNI_INCLUDES /home/biwi/gfanelli/OpenNI/Include ) 
	SET( OPENNI_LIB /home/biwi/gfanelli/OpenNI/Platform/Linux86/Bin/Release )
	
	LINK_DIRECTORIES( ${OPENNI_LIB} ${OPENCV_LIB})

ENDIF(WIN32)
	
INCLUDE_DIRECTORIES( . .. ${OPENNI_INCLUDES} ${OPENCV_INCLUDES})

	
add_executable(register ${REGISTER})


IF(WIN32)
target_link_libraries (register opencv_core230 opencv_highgui230 opencv_imgproc230 opencv_objdetect230 OpenNI)
ELSE(WIN32)
target_link_libraries (register opencv_core opencv_highgui opencv_imgproc OpenNI)
ENDIF(WIN32)

