addpath('Mex')
SAMPLE_XML_PATH='Config/SamplesIRConfig.xml';

% Start the Kinect Process
KinectHandles=mxNiCreateContext(SAMPLE_XML_PATH);

figure;
J=mxNiInfrared(KinectHandles); J=permute(J,[2 1]);
h=imshow(J,[0 1024]); 
for i=1:90
    J=mxNiInfrared(KinectHandles); J=permute(J,[2 1]);
    mxNiUpdateContext(KinectHandles);
    set(h,'Cdata',J); drawnow; 
end

% Stop the Kinect Process
mxNiDeleteContext(KinectHandles);
