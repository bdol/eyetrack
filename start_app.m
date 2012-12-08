function varargout = start_app(varargin)
% START_APP M-file for start_app.fig
%      START_APP, by itself, creates a new START_APP or raises the existing
%      singleton*.
%
%      H = START_APP returns the handle to a new START_APP or the handle to
%      the existing singleton*.
%
%      START_APP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in START_APP.M with the given input arguments.
%
%      START_APP('Property','Value',...) creates a new START_APP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before start_app_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to start_app_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help start_app

% Last Modified by GUIDE v2.5 07-Dec-2012 23:27:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @start_app_OpeningFcn, ...
                   'gui_OutputFcn',  @start_app_OutputFcn, ...
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


% --- Executes just before start_app is made visible.
function start_app_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to start_app (see VARARGIN)

% Choose default command line output for start_app
handles.output = hObject;
handles.device_name = 'kinect';
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes start_app wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = start_app_OutputFcn(hObject, eventdata, handles) 
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
handles.foldername = get(hObject, 'String');
guidata(hObject, handles);

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
handles.foldername
handles.subjectname
handles.device_name
recording_interface({handles.device_name},{handles.foldername},{handles.subjectname});



function SubjectNameBox_Callback(hObject, eventdata, handles)
% hObject    handle to SubjectNameBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SubjectNameBox as text
%        str2double(get(hObject,'String')) returns contents of SubjectNameBox as a double
handles.subjectname = get(hObject, 'String');
guidata(hObject, handles);
set(handles.SubjectNameBox, 'String', handles.subjectname);

% --- Executes during object creation, after setting all properties.
function SubjectNameBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubjectNameBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.subjectname = 'Subject1';
guidata(hObject, handles);


% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'kinectButton'
        % Code for when radiobutton1 is selected.
        handles.device_name = 'kinect';
    case 'XtionButton'
        % Code for when radiobutton2 is selected.
        handles.device_name = 'xtion';
end
guidata(hObject, handles);
