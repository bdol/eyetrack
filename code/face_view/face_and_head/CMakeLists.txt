cmake_minimum_required(VERSION 2.6)

SET( 	HEAD_DEMO
		src/CRForestEstimator.cpp
		src/CRTree.cpp
		src/gl_camera.cpp
		src/head_pose_main.cpp 
)

SET(	FACE_AND_HEAD
		src/CRForestEstimator.cpp
		src/CRTree.cpp
		src/gl_camera.cpp
		lib/IO.cc
		lib/PDM.cc
		lib/Patch.cc
		lib/CLM.cc
		lib/FDet.cc
		lib/PAW.cc
		lib/FCheck.cc
		lib/Tracker.cc
		src/main.cpp
)

SET(CMAKE_BUILD_TYPE "Release")

IF(WIN32)

	SET( OPENCV_INCLUDES C:/OpenCV2.3/build/include ) 
	SET( OPENCV_LIB C:/OpenCV2.3/my_build/lib ) 

	SET( OPENNI_INCLUDES "C:/Program Files\ (x86)/OpenNI/Include") 
	SET( OPENNI_LIB "C:/Program Files\ (x86)/OpenNI/Lib") 

	SET( FREEGLUT_LIB C:/Users/varsha/Documents/ResearchTools/freeglut/lib ) 
	
	SET( FACETRACKER_INCLUDES include/ )
	
	LINK_DIRECTORIES( ${OPENNI_LIB} ${OPENCV_LIB} ${FREEGLUT_LIB} )

	

ELSE(WIN32)

	SET( OPENCV_INCLUDES /include ) 
	SET( OPENCV_LIB /lib ) 
	SET( OPENNI_INCLUDES /home/biwi/gfanelli/OpenNI/Include ) 
	SET( OPENNI_LIB /home/biwi/gfanelli/OpenNI/Platform/Linux86/Bin/Release )

	#assuming freeglut installed on linux
	LINK_DIRECTORIES( ${OPENNI_LIB} ${OPENCV_LIB} )

ENDIF(WIN32)
	
INCLUDE_DIRECTORIES( . .. ${OPENNI_INCLUDES} ${OPENCV_INCLUDES} ${FACETRACKER_INCLUDES})

	
add_executable(face_and_head ${FACE_AND_HEAD})


IF(WIN32)
target_link_libraries (face_and_head opencv_core230 opencv_highgui230 opencv_imgproc230 opencv_objdetect230 OpenNI freeglut opengl32 glu32)
ELSE(WIN32)
target_link_libraries (face_and_head opencv_core opencv_highgui opencv_imgproc OpenNI GLU glut)
ENDIF(WIN32)

