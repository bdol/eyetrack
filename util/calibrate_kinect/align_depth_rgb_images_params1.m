%% Add paths
close all
addpath(genpath('../../MyNiViewer/Matlab'));
addpath(genpath('../../../../ResearchTools/toolbox_calib/'));
addpath(genpath('../../../../MATLAB'));

%% Load image
[rgb temp temp2 depth] = display_images(2, 2, 'images/1043.2.E');
depth = fliplr(imrotate(depth, -180));

%% Camera intrinsics
image_xRes = 1280;
image_yRes = 1024;
depth_xRes = 640;
depth_yRes = 480;

% cx_d = 317.21643+1.7;
% cy_d =  229.44027-5.4;
% fx_d =  598.31727-5.4;
% fy_d = 600.17755-5.4;
% fx_rgb = 1063.90253+7.4;
% fy_rgb = 1067.30164+7.4;
% cx_rgb = 633.08273-7.1;
% cy_rgb = 514.29293-7.1;
cx_d = 317.21643;
cy_d =  229.44027-5.4;
fx_d =  598.31727;
fy_d = 600.17755;
fx_rgb = 1063.90253;
fy_rgb = 1067.30164;
cx_rgb = 633.08273-7.1;
cy_rgb = 514.29293-7.1;

kc1= 0.29132;
kc2 = -0.91903;
kc3 =-0.01148;
kc4 = 0.00120;
kc1_d = -0.16090;
kc2_d = 0.98493;
kc3_d = -0.00593;
kc4_d = -0.00446;


om = [ 0.00437   -0.00319  0.00051 ] - [ 0.00434   0.00487  0.00020 ]; R = rodrigues(om);
% T = [ 0.03120   0.00012  -0.00158 ];
T = [ 0.02120   0.00012  -0.00158 ];
% T = [ 0.02120   0.00012  -0.00158 ] + [ -0.00046   0.00035  -0.00282 ];
% % om = [ -0.00466   -0.00089  0.00073 ]; R = rodrigues(om);
% T = [ 0.02610   0.00015  -0.00452 ];


%% Convert depth values to meters
depth_meters = 1./(depth(:)*-0.0030711016 + 3.3309495161);
depth_meters(depth(:)==2047) = 0;
depth_vals = (reshape(depth_meters, depth_yRes, depth_xRes));

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
% subplot(1,2,2);
% imshow((a));
dd = depth;
dd(dd<800 & dd>0) = 1;
dd(dd>=800) = 0;
% dd(dd<800) = 0;
% dd(dd~=0) = 1;
[I thresh] = edge(dd, 'canny');
[xx yy] = ind2sub(size(I), find(I==1));
ind = sub2ind(size(a), xx, yy, 2*ones(length(xx), 1));
A = a;
% imshow(A)
% imshow(uint8(A))
A(ind) = 0;
% imshow((imcrop(A, [0,0,640,480])));

% figure; subplot(2,2,1); imagesc(depth); 
% subplot(2,2,2); 
% imshow(rgb);
% % subplot(2,2,2); 
% figure; imshow((imcrop(A, [0,0,depth_xRes,depth_yRes])));  
% subplot(2,2,4); imshow(imcrop(a, [0 0 depth_xRes depth_yRes]));

% subplot(2,2,1); imagesc(depth); 
% subplot(2,2,2); imshow(uint8(A)); 
% subplot(2,2,3); imshow(uint8(rgb)); 
% subplot(2,2,4); imshow(uint8(a));

p = panel();
p.pack(1,2);
p(1,1).pack(2,1);
p(1,1,1,1).select();
imagesc(flipud(depth));
xlabel('depth image');
set(gca, 'YDir','normal');
xlim([1 640]); ylim([0 480]); axis equal;
p(1,1,2,1).select();
imshow(rgb);
xlabel('rgb image');
p(1,2).select();
imshow((imcrop(A, [0,0,depth_xRes,depth_yRes])));
xlabel('rgb mapped to depth');