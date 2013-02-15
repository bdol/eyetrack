@echo off
::start /WAIT /d ".\Debug\" MyNiSimpleViewer.exe
IF "%OPEN_NI_INSTALL_PATH%" == "" GOTO NOPATH
   :YESPATH
@ECHO Starting the openni recording app now...
::start /d "%OPEN_NI_INSTALL_PATH%Samples\Bin\Release\" NiViewer.exe
start /d ".\Debug\" MyNiViewer.exe
 GOTO END
   :NOPATH
 @ECHO You do not have OpenNI installed. A good starting place is http://kinect-i.blogspot.com.br/2012/05/how-to-install-and-use-openni-microsoft.html
 GOTO END
   :END
 @ECHO Task Complete. Hurrah!
 PAUSE
