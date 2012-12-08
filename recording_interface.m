function varargout = recording_interface(varargin)
% RECORDING_INTERFACE M-file for recording_interface.fig
%      RECORDING_INTERFACE, by itself, creates a new RECORDING_INTERFACE or raises the existing
%      singleton*.
%
%      H = RECORDING_INTERFACE returns the handle to a new RECORDING_INTERFACE or the handle to
%      the existing singleton*.
%
%      RECORDING_INTERFACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RECORDING_INTERFACE.M with the given input arguments.
%
%      RECORDING_INTERFACE('Property','Value',...) creates a new RECORDING_INTERFACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before recording_interface_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to recording_interface_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help recording_interface

% Last Modified by GUIDE v2.5 08-Dec-2012 00:01:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @recording_interface_OpeningFcn, ...
                   'gui_OutputFcn',  @recording_interface_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before recording_interface is made visible.
function recording_interface_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to recording_interface (see VARARGIN)

% Choose default command line output for recording_interface
handles.output = hObject;
device = varargin{1}{1};
parent_directory = varargin{2}{1};
handles.subjectname = varargin{3}{1};
status = mkdir(parent_directory, handles.subjectname);
if(~status)
    % pop up a dialog box to say could not create save location
    fprintf('Creating save location failed');
    delete(handles.figure1);
end
if(parent_directory(end)=='\')
    handles.save_location = [parent_directory handles.subjectname];
else
    handles.save_location = [parent_directory '\' handles.subjectname];
end
handles.device_name = [device '_scripts'];
addpath(handles.device_name);
addpath([handles.device_name '/src/Mex']);
addpath([handles.device_name '/src/Config']);
addpath(handles.save_location);
xmlpath=[handles.device_name '/src/Config/SamplesConfig.xml'];
handles.deviceHandles=init_device(xmlpath);
handles.timer = timer('ExecutionMode','fixedRate',...
                    'Period', 0.5,...
                    'TimerFcn', {@plot_data,handles});
global count;
count = 1;
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes recording_interface wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = recording_interface_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% - Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject handle to figure1 (see GCBO)
% eventdata reserved - to be defined in a future version of MATLAB
% handles structure with handles and user data (see GUIDATA)
stop_device(handles.deviceHandles);
i = -1
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop_device(handles.deviceHandles);
i = -1
% Hint: delete(hObject) closes the figure
delete(hObject);

% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
start(handles.timer)

% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.timer);


function plot_data(hObject, eventdata, handles)
imobj = findobj('parent',handles.RGBdata, 'type', 'image');
update_device_data(handles.deviceHandles);
I=get_rgb_data(handles.deviceHandles);
I=permute(I,[3 2 1]);
if(~isempty(imobj))
    set(imobj, 'Cdata',I);
else
    axes(handles.RGBdata);
    imshow(I, 'Parent', handles.RGBdata);
end
imobj = findobj('parent',handles.Depthdata, 'type', 'image');
XYZ= get_depth_data(handles.deviceHandles);
XYZ = permute(XYZ,[2 1 3]);
if(~isempty(imobj))
    set(imobj, 'Cdata',XYZ);
else
    axes(handles.Depthdata);
    imshow(XYZ, 'Parent', handles.Depthdata);
end
global count
imwrite(I,sprintf('%s/rgb_%d.png',handles.save_location, count),'png')
save(sprintf('%s/depth_%d.mat',handles.save_location, count),'XYZ')
count = count + 1