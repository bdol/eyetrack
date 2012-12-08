addpath('Example');
I1=rgb2gray(im2double(imread('Example\frame1s.png')));
I2=rgb2gray(im2double(imread('Example\frame2s.png')));
D=I1-I2;
figure, 
subplot(1,3,1),imshow(I1,[]); title('Measurement');
subplot(1,3,2),imshow(I2,[]); title('Reference');
subplot(1,3,3),imshow(D,[]); title('Difference');

J1=imagemax(I1);
J2=imagemax(I2);
J=zeros([size(I1) 3]);
J(:,:,1)=J1;
J(:,:,2)=J2;
figure, imshow(J); imshow(D,[]); title('Difference in Color');

figure, imshow(I1); title('Select a small sub window');
[R rect]=imcrop(I1);
y1=rect(1)+rect(3)/2;
x1=rect(2)+rect(4)/2;
ry=size(R,2);
rx=size(R,1);

yd1=[y1-ry/2 y1-ry/2 y1+ry/2  y1+ry/2 y1-ry/2];
xd1=[x1-rx/2 x1+rx/2 x1+rx/2  x1-rx/2 x1-rx/2 ];
xd1=round(xd1);
yd1=round(yd1);
hold on, plot(yd1,xd1,'b');  drawnow('expose');

% Movement of the sub-window in horizontal direction is proportional to
% depth difference  (Points always stay on the same horizontal line, never move vertically)
% Cross-correlation must be horizontal tilt and horizontal-scaling independent.
IBlock=I2(xd1(1)-10:xd1(2)+10,:);
I_SSD=template_matching(R,IBlock);

[x2,y2]=find(I_SSD==max(I_SSD(:)));
x2=x2+xd1(1)-11;
yd2=[y2-ry/2 y2-ry/2 y2+ry/2  y2+ry/2 y2-ry/2];
xd2=[x2-rx/2 x2+rx/2 x2+rx/2  x2-rx/2 x2-rx/2 ];
hold on, plot(yd2,xd2,'r');  drawnow('expose');

figure, 
subplot(1,3,1), imshow(R,[]); title('ROI');
subplot(1,3,2), imshow(I_SSD,[]); title('Normalize Cross Correlation');
subplot(1,3,3), imshow(I1); title('Movement == Depth');
hold on, plot(yd1,xd1,'b');  drawnow('expose');
hold on, plot(yd2,xd2,'r');  drawnow('expose');

