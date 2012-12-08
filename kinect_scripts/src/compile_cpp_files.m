function compile_cpp_files(OpenNiPath)
% This function compile_cpp_files will compile the c++ code files
% which wraps OpenNI for the Kinect in Matlab.
%
% Please install first on your computer:
% - NITE-Bin-Win32-v1.3.0.18
% - OpenNI-Bin-Win32-v1.0.0.25
%
% Just execute by:
%
%   compile_c_files 
%
% or with specifying the OpenNI path
% 
%   compile_cpp_files('C:\Program Files (x86)\OpenNI\');
%
%
if(nargin<1)
    OpenNiPathInclude=getenv('OPEN_NI_INCLUDE');
    OpenNiPathLib=getenv('OPEN_NI_LIB');
    if(isempty(OpenNiPathInclude)||isempty(OpenNiPathLib))
        error('OpenNI path not found, Please call the function like compile_cpp_files(''examplepath\openNI'')');
    end
else
    OpenNiPathLib=[OpenNiPath 'Lib'];
    OpenNiPathInclude=[OpenNiPath 'Include'];
end

cd('Mex');
files=dir('*.cpp');
for i=1:length(files)
    Filename=files(i).name;
    clear(Filename); 
    mex('-v',['-L' OpenNiPathLib],'-lopenNI',['-I' OpenNiPathInclude],Filename);
end
cd('..');