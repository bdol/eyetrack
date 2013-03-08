function varargout = display_gui(varargin)
% DISPLAY_GUI M-file for display_gui.fig
%      DISPLAY_GUI, by itself, creates a new DISPLAY_GUI or raises the existing
%      singleton*.
%
%      H = DISPLAY_GUI returns the handle to a new DISPLAY_GUI or the handle to
%      the existing singleton*.
%
%      DISPLAY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DISPLAY_GUI.M with the given input arguments.
%
%      DISPLAY_GUI('Property','Value',...) creates a new DISPLAY_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before display_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to display_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help display_gui

% Last Modified by GUIDE v2.5 04-Mar-2013 10:18:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @display_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @display_gui_OutputFcn, ...
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


% --- Executes just before display_gui is made visible.
function display_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to display_gui (see VARARGIN)

% Choose default command line output for display_gui
handles.rgb_size = [1024 1280];
handles.depth_size = [480 640];
handles.rgb_image = zeros(handles.rgb_size);
handles.depth_image = zeros(handles.depth_size);
handles.output = hObject;
set(handles.rgb,'NextPlot','add');
axes(handles.rgb);
imshow(handles.rgb_image);
set(handles.depth,'NextPlot','add');
axes(handles.depth);
imagesc(handles.depth_image); colormap('jet');
set(handles.depth,'NextPlot','add');
handles.image_index = -1;
handles.eyesel_status = 1;      % no region selected yet
% Add paths
addpath(genpath('C:\Users\varsha\Dropbox\Research\segbench'));
addpath(genpath('C:\Users\varsha\Dropbox\Research\workspace\eyetrack_data\'));
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes display_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = display_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Previous.
function Previous_Callback(hObject, eventdata, handles)
% hObject    handle to Previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% update image index
handles.image_index = handles.image_index - 1;
if(handles.image_index>-1)
    [handles.rgb_image handles.depth_image] = display_images(handles.image_index);
    if(length(handles.rgb_image)>0)
        set(handles.rgb,'NextPlot','add');
        axes(handles.rgb);
        imshow(handles.rgb_image);
    end
    if(length(handles.depth_image)>0)
        set(handles.depth,'NextPlot','add');
        axes(handles.depth);
        imagesc(handles.depth_image); colormap('jet');
        set(handles.depth,'NextPlot','add');
    end
    % Update handles structure
    guidata(hObject, handles);
end

% --- Executes on button press in Next.
function Next_Callback(hObject, eventdata, handles)
% hObject    handle to Next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update image index
handles.image_index = handles.image_index + 1;
[handles.rgb_image handles.depth_image] = display_images(handles.image_index);
if(length(handles.rgb_image)>0)
    set(handles.rgb,'NextPlot','add');
    axes(handles.rgb);
    imshow(handles.rgb_image);
end
if(length(handles.depth_image)>0)
    set(handles.depth,'NextPlot','add');
    axes(handles.depth);
    imagesc(handles.depth_image); colormap('jet');
    set(handles.depth,'NextPlot','add');
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in prob_boundary.
function prob_boundary_Callback(hObject, eventdata, handles)
% hObject    handle to prob_boundary (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(handles.eyesel_status==1)
    handles.eyesel_status = 2;  % crosshair comes up asking user to select a rectangular region
    [X Y] = ginput(2);
    X = round(X);
    Y = round(Y);
    [pb,theta] = pbBGTG(handles.rgb_image(Y(1):Y(2), X(1):X(2)));
    pb_mod = max(0,min(1,pb));
    figure;
    imshow(pb_mod);
end
