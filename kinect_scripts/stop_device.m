function stop_device(handles)
    % Stop the Kinect Process
    mxNiDeleteContext(handles);
end