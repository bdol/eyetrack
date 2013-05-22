% Grasp 18
clear;
addpath ../raw_processing/
addpath ../../code/table_view/test_code/
addpath(genpath('YAMLMatlab_0.4.3/'));
[K_rgb K_ir R T] = parse_kinect_yaml('grasp18.yml');

rgb = imread('~/Desktop/lowrestest/tv_rgb_3.png');
D = convert_rgbdemo_raw('~/Desktop/lowrestest/tv_depth_3.raw')*255;
D_m = raw_depth_to_meters2(D);
D_m(D_m==2047) = 0;

close all; imagesc(D_m); colormap('gray');
p = floor(ginput(1));
p_depth = [p'; D_m(p(2), p(1))];
p_W = p_depth;
p_W(1) = (p_depth(1)-K_ir(1, 3))*p_depth(3)/K_ir(1, 1);
p_W(2) = (p_depth(2)-K_ir(2, 3))*p_depth(3)/K_ir(2, 2);

p_Wp = R'*p_W-T;
p_rgb = zeros(2, 1);
p_rgb(1) = (p_Wp(1)*K_rgb(1, 1))/p_Wp(3)+K_rgb(1, 3);
p_rgb(2) = (p_Wp(2)*K_rgb(2, 2))/p_Wp(3)+K_rgb(2, 3);
% p_rgb = K_rgb*(R'*p_W-T);
% p_rgb = p_rgb./p_rgb(3);

hold on; plot(p_depth(1), p_depth(2), 'mx');
figure; imshow(rgb);
hold on; plot(p_rgb(1), p_rgb(2), 'mx');

%% imtransform test

