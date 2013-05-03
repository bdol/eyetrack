%% Add paths
addpath(genpath('../../MyNiViewer/Matlab'));
addpath(genpath('../../../../ResearchTools/toolbox_calib/'));

%% Load image
[rgb temp temp2 depth] = display_images(4, 3, 'images/1203.2.E');
depth = fliplr(imrotate(depth, -180));

%% Camera intrinsics
image_xRes = 1280;
image_yRes = 1024;
depth_xRes = 640;
depth_yRes = 480;
% Calib params were at 480x640 for rgb and depth
xmul = image_xRes/depth_xRes;
ymul = image_yRes/depth_yRes;
cx_d = 339.13010;
cy_d =  239.60424;
fx_d =  590.31068;
fy_d = 589.52492;
fx_rgb = xmul*527.29801;
fy_rgb = ymul*528.26617;
cx_rgb = xmul*339.06934;
cy_rgb = ymul*250.93700;

R =[ 9.9984628826577793e-01, 1.2635359098409581e-03,-1.7487233004436643e-02
    -1.4779096108364480e-03,9.9992385683542895e-01, -1.2251380107679535e-02,
1.7470421412464927e-02, 1.2275341476520762e-02,9.9977202419716948e-01 ];
T = [ 1.9985242312092553e-02, -7.4423738761617583e-04, -1.0916736334336222e-02 ];

%% Convert depth values to meters
depth_meters = 1./(depth(:)*-0.0030711016 + 3.3309495161);
depth_meters(depth(:)==2047) = 0;
depth_vals = (reshape(depth_meters, depth_yRes, depth_xRes));
% imshow(depth_vals);
% depth = flipud(depth);
% rgb = imresize(rgb, [depth_yRes depth_xRes], 'bicubic');

%% Transform rgb image to depth space
[xir, yir] = meshgrid(1:depth_xRes, 1:depth_yRes);
XIR_mat = (xir - cx_d).*depth_vals*(1/fx_d);
YIR_mat = (yir - cy_d).*depth_vals*(1/fy_d);
ZIR_mat = depth_vals;
ind = sub2ind(size(depth_vals),yir(:),xir(:));
XIR = XIR_mat(ind);
YIR = YIR_mat(ind);
ZIR = ZIR_mat(ind);
mat = [XIR YIR ZIR];
% transformed depth points that are in rgb space now
RGB_3D = bsxfun(@plus,mat*R,T);
xrgb = RGB_3D(:,1)*fx_rgb./RGB_3D(:,3) + cx_rgb;
yrgb = RGB_3D(:,2)*fy_rgb./RGB_3D(:,3) + cy_rgb;
xrgb(xrgb<1) = 1;
xrgb(xrgb>image_xRes) = image_xRes;
yrgb(yrgb<1) = 1;
yrgb(yrgb>image_yRes) = image_yRes;
xrgb = round(xrgb);
yrgb = round(yrgb);

new_size = size(rgb);
a = zeros(new_size);
depth_rep = depth./max(depth(:));
% a(:,:,1) = depth_rep;
% a(:,:,2) = depth_rep;
% a(:,:,3) = depth_rep;
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


% subplot(1,2,2);
% imshow((a));

I = edge(depth_rep, 'canny');
[xx yy] = ind2sub(size(I), find(I==1));
ind = sub2ind(size(a), xx, yy, 2*ones(length(xx), 1));
A = a;
imshow(A)
% imshow(uint8(A))
A(ind) = 255;
% imshow((imcrop(A, [0,0,640,480])));

subplot(2,2,1); imagesc(depth); 
subplot(2,2,2); imshow((imcrop(A, [0,0,640,480]))); 
subplot(2,2,3); imshow(rgb); 
subplot(2,2,4); imshow(imcrop(a, [0 0 640 480]));