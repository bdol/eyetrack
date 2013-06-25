clear; close all;
addpath ../../../util/raw_processing/
rgb_c = [272.0921630859375, 281.8406372070312, 290.9422607421875, 300.3952026367188, 274.9721984863281, 284.5048522949219, 294.1593017578125, 303.5368347167969, 278.32568359375, 287.3502502441406, 297.0829467773438, 306.8509521484375;
  387.7915649414062, 384.7892761230469, 381.4210815429688, 378.383056640625, 400.9962463378906, 397.592529296875, 394.3660278320312, 391.4391784667969, 413.8038330078125, 410.9039001464844, 407.3975219726562, 404.5681457519531];

im = imread('images/tv_highres_rgb_0.png');
% im = imresize(im, [480 640]);
% rgb_c(1, :) = rgb_c(1, :)*640/1280;
% rgb_c(2, :) = rgb_c(2, :)*480/1024;

% Get locations of camera centers
imshow(im);
n = 3;
[x y] = ginput(n);

% Show detected corners and camera centers
cam_p = zeros(3, n);
cam_p(1:2, :) = [x'; y'];
hold on;
plot(rgb_c(1, :), rgb_c(2, :), 'r*');
plot(cam_p(1, :), cam_p(2, :), 'g*');

%%
depth = convert_rgbdemo_raw('images/tv_depth_6.raw')*255;
depth = raw_depth_to_meters2(depth);

% Get (correct!) depth of corner points
K_ir = [ 5.6009202708545865e+02, 0., 3.0015891816197120e+02; 0., ...
       5.5885814292051782e+02, 2.5149932242225375e+02; 0., 0., 1. ];
fx = K_ir(1, 1);
fy = K_ir(2, 2);
cx = K_ir(1, 3);
cy = K_ir(2, 3);
R = [ 9.9993189761892909e-01, -3.2729355538435750e-03, 1.1202143414009318e-02; 
    3.3304519065922894e-03, 9.9998134867689581e-01, -5.1196082305675792e-03;
    -1.1185178331413474e-02, 5.1565677729480267e-03, 9.9992414792047979e-01 ];
T = [ 2.8788567238524864e-02; 6.3401893265889063e-04;
       1.3891577580578355e-03 ]; 
K_rgb = [ 4.9726263121508453e+02, 0., 3.1785221776747596e+02; 0., ...
       4.9691535190126677e+02, 2.7311575302513319e+02; 0., 0., 1. ];
depth_aligned = zeros(size(depth));
% First map depth to RGB
for x=1:size(depth, 2)
    for y=1:size(depth, 1)
        p = [x y depth(y, x)]';
        p(1) = (x-cx)*p(3)/fx;
        p(2) = (y-cy)*p(3)/fy;
        p = K_rgb*(R'*p - T);
        p = p./p(3);
        if floor(p(1))>0 && floor(p(1))<=640 && floor(p(2))>0 && floor(p(2))<=480
            depth_aligned(floor(p(2)), floor(p(1))) = depth(y, x);
        end
    end
end
for i=1:size(rgb_c, 2)
    rgb_c(3, i) = depth_aligned(floor(rgb_c(2, i)), floor(rgb_c(1, i)));
end

for i=1:size(cam_p, 2)
    cam_p(3, i) = depth_aligned(floor(cam_p(2, i)), floor(cam_p(1, i)));
end

% Transform to kinect coordinates
fx = K_rgb(1, 1);
fy = K_rgb(2, 2);
cx = K_rgb(1, 3);
cy = K_rgb(2, 3);
[Xw Yw Zw] = im_to_world(rgb_c(1, :), rgb_c(2, :), rgb_c(3, :), fx, fy, cx, cy);
[Xw_cam Yw_cam Zw_cam] = im_to_world(cam_p(1, :), cam_p(2, :), cam_p(3, :), fx, fy, cx, cy);

%% Find plane with correct rotation

% First find plane normal
% P = [Xw' Yw' Zw'];
% [n rho Xp Yp Zp] = svd_find_plane(P);

% Next rotate it to be parallel with z=0 plane and with 0 mean
% R = determine_plane_rotation(n);

% 
% 
% P_T = mean(P, 2);
% P = bsxfun(@minus, P, P_T);
% [~, ~, V] = svd(P*P');
% P = V'*P;
% 
% 
% close all; plot3(P(1, :), P(2, :), P(3, :), 'r*'); hold on; axis equal;
% plot3(P_proj(1, :), P_proj(2, :), P_proj(3, :), 'b*'); hold on;


% P_rot = R'*P;
% P_rot_T = mean(P_rot, 2);
% P_rot = bsxfun(@minus, P_rot, P_rot_T);
% [~, ~, V] = svd(P_rot*P_rot');
% % P_rot = V'*P_rot;
% 
% % close all;
% % plot3(P_rot(1, :), P_rot(2, :), P_rot(3, :), 'r*'); hold on;
% % plot3(P_rot_cam(1, :), P_rot_cam(2, :), P_rot_cam(3, :), 'g*'); hold on;
% % plot3(P_cam_ends(1, :), P_cam_ends(2, :), P_cam_ends(3, :), 'b*'); hold on;
% % axis equal
% 
% Pp = [Xp(:) Yp(:) Zp(:)]';
% Pp = bsxfun(@minus, R'*Pp, P_rot_T);
% [~, ~, V] = svd(Pp*Pp');
% Pp = V'*Pp;

%%


% 
% % close all;
% % plot3(P_rot(1, :), P_rot(2, :), P_rot(3, :), 'r*'); hold on;
% % mesh(Xp,Yp,Zp);colormap([.8 .8 .8])
% % axis equal
% 
% 
% P_cam = [Xw_cam; Yw_cam; Zw_cam];
% P_rot_cam = R'*P_cam;
% P_rot_cam = bsxfun(@minus, P_rot_cam, P_rot_T);
% P_rot_cam = V'*P_rot_cam;
% 
% % Now generate the mesh for the plane
% xmin = min(P_rot(1, :));
% xmax = max(P_rot(1, :));
% ymin = min(P_rot(2, :));
% ymax = max(P_rot(2, :));
% [Xpo Ypo] = meshgrid(linspace(xmin, xmax, 4), linspace(ymin, ymax, 3));
% Zpo = mean(P_rot(3, :))*ones(size(Xpo));
% hp = size(Xpo, 1); wp = size(Xpo, 2);
% 
% arrow_length = xmax-xmin;
% P_cam_ends = P_rot_cam;
% P_cam_ends(3, :) = P_cam_ends(3, :)-arrow_length;
% 
% 
% % Now transform the points back
% P_rot = V*P_rot;
% Xpo = Xpo(:); Ypo = Ypo(:); Zpo = Zpo(:);
% P_plane = [Xpo Ypo Zpo]';
% P_plane = V*P_plane;
% P_rot = R*bsxfun(@plus, P_rot, P_rot_T);
% P_plane = R*bsxfun(@plus, P_plane, P_rot_T);
% 
% P_rot_cam = R*bsxfun(@plus, V*P_rot_cam, P_rot_T);
% P_cam_ends = R*bsxfun(@plus, V*P_cam_ends, P_rot_T);
% 
% Xpo = P_plane(1, :); Ypo = P_plane(2, :); Zpo = P_plane(3, :);
% Xpo = reshape(Xpo, hp, wp);
% Ypo = reshape(Ypo, hp, wp);
% Zpo = reshape(Zpo, hp, wp);



%% Plot plane on image

P = [Xw; Yw; Zw];
[n rho Xp Yp Zp] = svd_find_plane(P');
point_on_plane = mean([Xp(:) Yp(:) Zp(:)]);
% Find projections of points onto Z plane
P_proj = point_plane_intersection(n', point_on_plane, P')';
close all; plot3(P(1, :), P(2, :), P(3, :), 'r*'); hold on;
plot3(P_proj(1, :), P_proj(2, :), P_proj(3, :), 'b*'); hold on;  axis equal;
Xp = P_proj(1, :)';
Yp = P_proj(2, :)';
Zp = P_proj(3, :)';
hp = 3; wp=4;

P = [Xp Yp Zp]';
pi = K_rgb*P;
pi = bsxfun(@rdivide, pi, pi(3, :));
Xpi = pi(1, :);
Ypi = pi(2, :);
Xpi = reshape(Xpi, hp, wp);
Ypi = reshape(Ypi, hp, wp);
Zpi = zeros(hp, wp);
for gx=1:wp
    if mod(gx, 2)==1
        clr = 0;
    else
        clr = 1;
    end
    for gy=1:hp
        Zpi(gy, gx) = clr;
        clr = 1-clr;
    end
end
close all; imshow(im); hold on;
h = pcolor(Xpi, Ypi, Zpi); colormap('gray'); caxis([0 1]);
% alpha(h, 0.6);
plot(rgb_c(1, :), rgb_c(2, :), 'r*');
% 
% P_cam = K_rgb*P_rot_cam;
% P_cam = bsxfun(@rdivide, P_cam, P_cam(3, :));
% plot(P_cam(1, :), P_cam(2, :), 'g*'); hold on;
% 
% P_ends = K_rgb*P_cam_ends;
% P_ends = bsxfun(@rdivide, P_ends, P_ends(3, :));
% plot([P_cam(1, :); P_ends(1, :)], [P_cam(2, :); P_ends(2, :)], 'm');