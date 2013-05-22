%% Add paths
close all
% addpath(genpath('../../MyNiViewer/Matlab'));
% addpath(genpath('../../../../ResearchTools/toolbox_calib/'));
% addpath(genpath('../../../../MATLAB'));

%% Load checkerboard
calib_num = 1;
ignore_cols = 8;
rgb = double(imread(sprintf('calibration5_pairs/Image_%d.jpg', calib_num)));
depth = double(imread(sprintf('calibration5_pairs/IR_%d.jpg', calib_num)));
% simulate the conditions under which our images are recorded...1:8 columns
% are 0 for some reason!
% depth_big = zeros(size(depth));
% depth_big(:,ignore_cols:end) = depth(:,1:end-ignore_cols+1);
% depth = depth_big;
% depth(:,1:8) = [];
% normalise the rgb channel
rgb = rgb./255;

%% Camera intrinsics
image_xRes = 1280;
image_yRes = 1024;
depth_xRes = 632;
depth_yRes = 480;

cx_d = 317.21643;
cy_d =  229.44027-5.4;
fx_d =  598.31727;
fy_d = 600.17755;
fx_rgb = 1063.90253;
fy_rgb = 1067.30164;
cx_rgb = 633.08273-7.1;
cy_rgb = 514.29293-7.1;

% distortion params
kc1= 0.29132;
kc2 = -0.91903;
kc3 =-0.01148;
kc4 = 0.00120;
kc1_d = -0.16090;
kc2_d = 0.98493;
kc3_d = -0.00593;
kc4_d = -0.00446;


om = [ 0.00437   -0.00319  0.00051 ] - [ 0.00434   0.00487  0.00020 ]; R = rodrigues(om);
% T = [ 0.01020   0.00012  -0.00158 ];
T = [ 0.02120   0.00012  -0.00158 ];
T = [ 0.02320   -0.0212  -0.00158 ];
R = [ 9.9984628826577793e-01 1.2635359098409581e-03 -1.7487233004436643e-02
    -1.4779096108364480e-03 9.9992385683542895e-01 -1.2251380107679535e-02
    1.7470421412464927e-02 1.2275341476520762e-02 9.9977202419716948e-01 ];
%% There are no depth values here since we are dealing with an IR image
depth_vals = ones(depth_yRes, depth_xRes);

%% Transform rgb image to depth space
[xir, yir] = meshgrid(1:depth_xRes, 1:depth_yRes);
% --------------experiment
v = normalize([xir(:)';yir(:)'],[fx_d;fy_d],[cx_d;cy_d],[kc1_d kc2_d kc3_d kc4_d 0 0],0);
XIR_mat = reshape(v(1,:)', depth_yRes, depth_xRes).*depth_vals;
YIR_mat = reshape(v(2,:)', depth_yRes, depth_xRes).*depth_vals;
% ----------end experiment
% XIR_mat = (xir - cx_d).*depth_vals*(1/fx_d);
% YIR_mat = (yir - cy_d).*depth_vals*(1/fy_d);
ZIR_mat = depth_vals;
ind = sub2ind(size(depth_vals),yir(:),xir(:));
XIR = XIR_mat(ind);
YIR = YIR_mat(ind);
ZIR = ZIR_mat(ind);
mat = [XIR YIR ZIR];
% transformed depth points that are in rgb space now
RGB_3D = bsxfun(@plus,mat*R,T);
% --------------experiment
xdashrgb = RGB_3D(:,1)./RGB_3D(:,3);
ydashrgb = RGB_3D(:,2)./RGB_3D(:,3);
r2 = xdashrgb.^2 + ydashrgb.^2;
xdashdashrgb = (1 + kc1*r2 + kc2*r2.^2).*xdashrgb + 2*kc3*xdashrgb.*ydashrgb + kc4*(r2 + 2.*xdashrgb.^2);
ydashdashrgb = (1 + kc1*r2 + kc2*r2.^2).*ydashrgb + kc3.*(r2 + 2.*ydashrgb.^2) + 2.*kc4.*xdashrgb.*ydashrgb;
xrgb = xdashdashrgb*fx_rgb + cx_rgb;
yrgb = ydashdashrgb*fy_rgb + cy_rgb;
% --------------End experiment
% xrgb = RGB_3D(:,1)*fx_rgb./RGB_3D(:,3) + cx_rgb;
% yrgb = RGB_3D(:,2)*fy_rgb./RGB_3D(:,3) + cy_rgb;
xrgb(xrgb<1) = 1;
xrgb(xrgb>image_xRes) = image_xRes;
yrgb(yrgb<1) = 1;
yrgb(yrgb>image_yRes) = image_yRes;
xrgb = round(xrgb);
yrgb = round(yrgb);

new_size = size(rgb);
depth_rep = depth./max(depth(:));
a = zeros(new_size);
a(1:depth_yRes,1:depth_xRes,1) = depth_rep;
a(1:depth_yRes,1:depth_xRes,2) = depth_rep;
a(1:depth_yRes,1:depth_xRes,3) = depth_rep;
% figure;
% subplot(1,2,1);
% imshow(uint8(a));
% ind_ir_red = sub2ind(size(rgb),yir(:),xir(:),ones(length(ind),1));
% ind_ir_green = sub2ind(size(rgb),yir(:),xir(:),2*ones(length(ind),1));
% ind_ir_blue = sub2ind(size(rgb),yir(:),xir(:),3*ones(length(ind),1));
% ind_rgb_red = sub2ind(size(rgb),yrgb(:),xrgb(:),ones(length(ind),1));
% ind_rgb_green = sub2ind(size(rgb),yrgb(:),xrgb(:),2*ones(length(ind),1));
% ind_rgb_blue = sub2ind(size(rgb),yrgb(:),xrgb(:),3*ones(length(ind),1));
% a(ind_ir_red) = rgb(ind_rgb_red);    a(ind_ir_green) = rgb(ind_rgb_green);    a(ind_ir_blue) = rgb(ind_rgb_blue);

ind_ir_red = sub2ind(new_size,yir(:),xir(:),ones(length(ind),1));
ind_ir_green = sub2ind(new_size,yir(:),xir(:),2*ones(length(ind),1));
ind_ir_blue = sub2ind(new_size,yir(:),xir(:),3*ones(length(ind),1));
ind_rgb_red = sub2ind(new_size,yrgb(:),xrgb(:),ones(length(ind),1));
ind_rgb_green = sub2ind(new_size,yrgb(:),xrgb(:),2*ones(length(ind),1));
ind_rgb_blue = sub2ind(new_size,yrgb(:),xrgb(:),3*ones(length(ind),1));
a(ind_ir_red) = rgb(ind_rgb_red);    a(ind_ir_green) = rgb(ind_rgb_green);    a(ind_ir_blue) = rgb(ind_rgb_blue);

%% DISPLAY RESULTS
I = edge(depth_rep, 'canny', 0.3);
% the zeros edge was added in to simulate our image taking conditions...we
% don't need it to interfere with the alignment result depiction here
I(:,1:ignore_cols) = 0;
[xx yy] = ind2sub(size(I), find(I==1));
ind = sub2ind(size(a), xx, yy, 2*ones(length(xx), 1));
A = a;
A(ind) = 1;
% subplot(1,2,1); 
imshow((imcrop(A, [0,0,depth_xRes,depth_yRes])));
% subplot(1,2,2); imshow(I);