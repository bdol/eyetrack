function varargout = save_video_to_location(varargin)
% SAVE_VIDEO_TO_LOCATION M-file for save_video_to_location.fig
%      SAVE_VIDEO_TO_LOCATION, by itself, creates a new SAVE_VIDEO_TO_LOCATION or raises the existing
%      singleton*.
%
%      H = SAVE_VIDEO_TO_LOCATION returns the handle to a new SAVE_VIDEO_TO_LOCATION or the handle to
%      the existing singleton*.
%
%      SAVE_VIDEO_TO_LOCATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SAVE_VIDEO_TO_LOCATION.M with the given input arguments.
%
%      SAVE_VIDEO_TO_LOCATION('Property','Value',...) creates a new SAVE_VIDEO_TO_LOCATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before save_video_to_location_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to save_video_to_location_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help save_video_to_location

% Last Modified by GUIDE v2.5 03-Dec-2012 21:56:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @save_video_to_location_OpeningFcn, ...
                   'gui_OutputFcn',  @save_video_to_location_OutputFcn, ...
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


% --- Executes just before save_video_to_location is made visible.
function save_video_to_location_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to save_video_to_location (see VARARGIN)

% Choose default command line output for save_video_to_location
handles.output = hObject;
handles.foldername = 'Location to save recorded video to';
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes save_video_to_location wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = save_video_to_location_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.foldername
% Hints: get(hObject,'String') returns contents of EditBox as text
%        str2double(get(hObject,'String')) returns contents of EditBox as a
%        double

% --- Executes during object creation, after setting all properties.
function EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in BrowseButton.
function BrowseButton_Callback(hObject, eventdata, handles)
% hObject    handle to BrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.foldername = uigetdir;
guidata(hObject, handles);
set(handles.EditBox, 'String', handles.foldername);


% --- Executes on button press in Ok.
function Ok_Callback(hObject, eventdata, handles)
% hObject    handle to Ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Close the file chooser dialog and call the second gui window
delete(handles.figure1);
recording_interface({handles.foldername});
