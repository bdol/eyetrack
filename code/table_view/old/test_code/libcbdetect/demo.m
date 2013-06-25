clear variables; dbstop error; close all;
disp('================================');

addpath('matching');

I = imread('../images/tv_rgb_0.png');
corners = findCorners(I,0.01,1);
chessboards = chessboardsFromCorners(corners);

figure; imshow(uint8(I)); hold on;
plotChessboards(chessboards,corners);
