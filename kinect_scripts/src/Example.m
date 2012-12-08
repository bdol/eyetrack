addpath('Mex')
SAMPLE_XML_PATH='Config/SamplesConfig.xml';

% Start the Kinect Process
filename='Example/SkelShort.oni';
KinectHandles=mxNiCreateContext(SAMPLE_XML_PATH,filename);

% To use the Kinect hardware use :
%KinectHandles=mxNiCreateContext(SAMPLE_XML_PATH);

figure;
I=mxNiPhoto(KinectHandles); I=permute(I,[3 2 1]);
D=mxNiDepth(KinectHandles); D=permute(D,[2 1]);
subplot(1,2,1),h1=imshow(I); 
subplot(1,2,2),h2=imshow(D,[0 9000]); colormap('jet');
    
for i=1:90
    I=mxNiPhoto(KinectHandles); I=permute(I,[3 2 1]);
    D=mxNiDepth(KinectHandles); D=permute(D,[2 1]);
    mxNiUpdateContext(KinectHandles);
    set(h1,'CDATA',I);
    set(h2,'CDATA',D);
    drawnow; 
end

% Stop the Kinect Process
mxNiDeleteContext(KinectHandles);
