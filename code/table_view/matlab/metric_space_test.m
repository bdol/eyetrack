%% First test object detection
clear;
D = imread('~/Desktop/table_top_training_0/k2/depth_0.png');
D_m_2 = raw_depth_to_meters2(D);
D_m_2(D_m_2==2047) = 0;

% Fit plane
fprintf('Fitting plane... ');
[xx yy] = meshgrid(1:size(D, 2), 1:size(D, 1));
X = xx(:); Y = yy(:);
Z = D_m_2(:);

% Depth intrinsics:
fx = 5.6009202708545865e+02;
fy = 5.5885814292051782e+02;
cx = 3.0015891816197120e+02;
cy = 2.5149932242225375e+02;
[Xw Yw Zw] = im_to_world(X, Y, Z, fx, fy, cx, cy);

% Remove bad depth points
Xw(Z==0) = [];
Yw(Z==0) = [];
Zw(Z==0) = [];
% Remove far depth points (more than 2m)
Xw(Zw>1) = [];
Yw(Zw>1) = [];
Zw(Zw>1) = [];

% Least squares to fit table cloud points
[n_est ro_est Xp Yp Zp] = LSE([Xw Yw Zw]);
hp = size(Xp, 1); wp = size(Xp, 2);
fprintf('Done!\n');

% Now detect objects by finding points that are deviate from this plane
fprintf('Finding objects... ');
D = imread('~/Desktop/table_top_training_0/k2/depth_3.png');
D_m_2 = raw_depth_to_meters2(D);
D_m_2(D_m_2==2047) = 0;

[xx yy] = meshgrid(1:size(D, 2), 1:size(D, 1));
X = xx(:); Y = yy(:);
Z = D_m_2(:);

% Depth intrinsics:
fx = 5.6009202708545865e+02;
fy = 5.5885814292051782e+02;
cx = 3.0015891816197120e+02;
cy = 2.5149932242225375e+02;
[Xw Yw Zw] = im_to_world(X, Y, Z, fx, fy, cx, cy);
% Remove bad depth points
Xw(Z==0) = [];
Yw(Z==0) = [];
Zw(Z==0) = [];
% Remove far depth points (more than 2m)
Xw(Zw>1) = [];
Yw(Zw>1) = [];
Zw(Zw>1) = [];

D = point_plane_dist(n_est', [Xp(1) Yp(1) Zp(1)], [Xw Yw Zw]);
thresh = 0.02;
obj_idx = D>thresh;
Xobj = Xw(obj_idx);
Yobj = Yw(obj_idx);
Zobj = Zw(obj_idx);

Xw(obj_idx) = [];
Yw(obj_idx) = [];
Zw(obj_idx) = [];

[L C D] = fkmeans([Xobj Yobj Zobj], 3);

% Determine orientation of table so that hulls appear to sit on it
R = determine_plane_rotation(n_est);

% Determine the actual hull cube location
P = [(Xobj)'; (Yobj)'; (Zobj)'];
P_rot = R'*P;
X_rot = P_rot(1, :)';
Y_rot = P_rot(2, :)';
Z_rot = P_rot(3, :)';

hulls = zeros(3, 6);
for i=1:3
    X_i = X_rot(L==i);
    Y_i = Y_rot(L==i);
    Z_i = Z_rot(L==i);
    xmax = max(X_i); ymax = max(Y_i); zmax = max(Z_i)+0.02;
    xmin = min(X_i); ymin = min(Y_i); zmin = min(Z_i);
    hulls(i, :) = [xmin ymin zmin xmax ymax zmax];
end

B1 = make_box_3d(hulls(1, :), 0.01);
B2 = make_box_3d(hulls(2, :), 0.01);
B3 = make_box_3d(hulls(3, :), 0.01);
B1_trans = (R*B1')';
B2_trans = (R*B2')';
B3_trans = (R*B3')';

fprintf('Done!\n');

% Plot them on the RGB image
skip = 10;
Xobj_plot = Xobj(1:skip:end);
Yobj_plot = Yobj(1:skip:end);
Zobj_plot = Zobj(1:skip:end);
L_plot = L(1:skip:end);

% Apply extrinsics
R = [9.9993189761892909e-01, -3.2729355538435750e-03, 1.1202143414009318e-02;
     3.3304519065922894e-03, 9.9998134867689581e-01, -5.1196082305675792e-03;
     -1.1185178331413474e-02, 5.1565677729480267e-03, 9.9992414792047979e-01];
T = [2.8788567238524864e-02; 6.3401893265889063e-04; 1.3891577580578355e-03];
Pd = [Xobj_plot Yobj_plot Zobj_plot]';
Pd_r = R'*Pd;
P_rgb = bsxfun(@minus, Pd_r, T);
Xobj_plot_rgb = P_rgb(1, :)';
Yobj_plot_rgb = P_rgb(2, :)';
Zobj_plot_rgb = P_rgb(3, :)';

% Calculate transform to rgb image plane
fx = 4.9726263121508453e+02;
fy = 4.9691535190126677e+02;
cx = 3.1785221776747596e+02;
cy = 2.7311575302513319e+02;
K = [fx 0 cx 0; 0 fy cy 0; 0 0 1 0];
P = [Xobj_plot_rgb Yobj_plot_rgb Zobj_plot_rgb ones(numel(Xobj_plot_rgb), 1)]';
pi = K*P;
pi = bsxfun(@rdivide, pi, pi(3, :));
im = imread('~/Desktop/table_top_training_0/k2/rgb_3.png');
close all; imshow(im); hold on;

% Plot boxes
B2D_1 = bsxfun(@minus, R'*(B1_trans'), T);
B2D_1 = K*[B2D_1; ones(1, size(B2D_1, 2))];
B2D_1 = bsxfun(@rdivide, B2D_1, B2D_1(3, :));
B2D_1(3, :) = [];
draw_box_2d(B2D_1', 'g');
B2D_2 = bsxfun(@minus, R'*(B2_trans'), T);
B2D_2 = K*[B2D_2; ones(1, size(B2D_2, 2))];
B2D_2 = bsxfun(@rdivide, B2D_2, B2D_2(3, :));
B2D_2(3, :) = [];
draw_box_2d(B2D_2', 'm');
B2D_3 = bsxfun(@minus, R'*(B3_trans'), T);
B2D_3 = K*[B2D_3; ones(1, size(B2D_3, 2))];
B2D_3 = bsxfun(@rdivide, B2D_3, B2D_3(3, :));
B2D_3(3, :) = [];
draw_box_2d(B2D_3', 'b');

%% Common metric space

addpath(genpath('../../../util/calibrate_kinect/'))
[K_rgb_1, K_ir_1, R_1, T_1] = parse_kinect_yaml('../../../util/calibrate_kinect/grasp18.yml');
[K_rgb_2, K_ir_2, ~, ~] = parse_kinect_yaml('../../../util/calibrate_kinect/grasp8.yml');
fx_1 = K_ir_1(1, 1);
fy_1 = K_ir_1(2, 2);
cx_1 = K_ir_1(1, 3);
cy_1 = K_ir_1(2, 3);
fx_2 = K_ir_2(1, 1);
fy_2 = K_ir_2(2, 2);
cx_2 = K_ir_2(1, 3);
cy_2 = K_ir_2(2, 3);

% Determine k2 plane
rgbBase = '/Users/bdol/Desktop/table_top_training_0/k1_png/IM_For_Katie_';
depthBase = '/Users/bdol/Desktop/table_top_training_0/k1_raw/DP_For_Katie_';

N = 0;
for i=0:39
    if exist([rgbBase num2str(i) '.txt'], 'file')
        N = N+1;
    end
end

img_idx = zeros(N, 1);

C = zeros(12, 3, N);
Y = zeros(2, 3, N);
im_count = 1;
for i=0:40
    i
    if ~exist([rgbBase num2str(i) '.txt'], 'file')
        continue;
    end
    % Get corner data
    c_data = load([rgbBase num2str(i) '.txt']);
    C(:, 1:2, im_count) = c_data(1:12, :);
    Y(:, 1:2, im_count) = c_data(13:14, :);

    % Get depth data
    depth = get_raw_image([depthBase num2str(i) '.raw']);
    depth = flipdim(depth/1000, 2);
    
       
    W = get_warp_map(size(depth, 1), size(depth, 2), depth, K_ir_1, K_rgb_1, R_1, T_1);
    for j=1:12
        x = floor(640/1280*C(j, 1, im_count));
        y = floor(480/960*C(j, 2, im_count));
        % Align
%         ind = sub2ind(size(depth), x, y);
        
        
        
%         close all;
%         rgbhigh = imread('~/Desktop/table_top_training_0/k1_png/IM_For_Katie_0.png');
%         rgbhigh = rgbhigh(1:960, :, :);
%         rgbhigh = imresize(rgbhigh, [480 640]);
%         imshow(rgbhigh);
%         figure;
%         imagesc(depth);
%         keyboard;
        
        C(j, 1, im_count) = x;
        C(j, 2, im_count) = y;
        C(j, 3, im_count) = W(y, x);
    end    
    for j=1:2
        x = floor(640/1280*Y(j, 1, im_count));
        y = floor(480/960*Y(j, 2, im_count));
        Y(j, 3, i+1) = W(y, x);
    end

    % DEBUG %%%%%%%%%%%%%%%%%%%%%
%     [xx yy] = meshgrid(1:size(depth, 2), 1:size(depth, 1));
%     X_1 = xx(:); Y_1 = yy(:); Z_1 = depth(:);
%     [Xw_1 Yw_1 Zw_1] = im_to_world(X_1, Y_1, Z_1, fx_1, fy_1, cx_1, cy_1);
%     Xw_1(Z_1<=0) = [];
%     Yw_1(Z_1<=0) = [];
%     Zw_1(Z_1<=0) = [];
%     C_i = C(:, :, i+1);
%     [X Y Z] = im_to_world(C_i(:, 1), C_i(:, 2), C_i(: ,3), fx_1, fy_1, cx_1, cy_1);
%     
%     close all;
%     figure;
%     h = plot3(Xw_1(1:100:end), Yw_1(1:100:end), Zw_1(1:100:end), 'gx'); hold on;
%     plot3(0, 0, 0, 'rx'); hold on;
%     plot3(X, Y, Z, 'bx');
%     axis([-0.4 -0.2 -0.05 0.1 0.7 0.8]);
%     axis equal;
%     keyboard;
    % DEBUG %%%%%%%%%%%%%%%%%%%%%
    
    img_idx(im_count) = i;
    im_count = im_count+1;
end

%%
close all;
addpath ../test_code/
Xw = []; Yw = []; Zw = [];
for i=1:40
    C_i = C(:, :, i);
    [X Y Z] = im_to_world(C_i(:, 1), C_i(:, 2), C_i(: ,3), fx_1, fy_1, cx_1, cy_1);
    Xw = [Xw; X];
    Yw = [Yw; Y];
    Zw = [Zw; Z];
end
[n, rho] = svd_find_plane([X Y Z]);
R_orient = determine_plane_rotation(n);
plot3(Xw, Yw, Zw, 'bo'); axis equal;
plane_center = mean([Xw, Yw, Zw]);

%%
% Plot in world
D_1 = get_raw_image('~/Desktop/table_top_training_0/k1_raw/DP_For_Katie_0.raw');
D_m_1 = flipdim(D_1/1000, 2);
[xx yy] = meshgrid(1:size(D_1, 2), 1:size(D_1, 1));
X_1 = xx(:); Y_1 = yy(:); Z_1 = D_m_1(:);

D_2 = imread('~/Desktop/table_top_training_0/k2/depth_9.png');
D_m_2 = flipdim(raw_depth_to_meters2(D_2), 2);
D_m_2(D_m_2==2047) = 0;
[xx yy] = meshgrid(1:size(D_2, 2), 1:size(D_2, 1));
X_2 = xx(:); Y_2 = yy(:); Z_2 = D_m_2(:);

[Xw_1 Yw_1 Zw_1] = im_to_world(X_1, Y_1, Z_1, fx_1, fy_1, cx_1, cy_1);
Xw_1(Z_1<=0) = [];
Yw_1(Z_1<=0) = [];
Zw_1(Z_1<=0) = [];

[Xw_2 Yw_2 Zw_2] = im_to_world(X_2, Y_2, Z_2, fx_2, fy_2, cx_2, cy_2);
Xw_2(Z_2==0) = [];
Yw_2(Z_2==0) = [];
Zw_2(Z_2==0) = [];

F = determine_k2_frame(C, fx_1, fy_1, cx_1, cy_1);

P_2 = [Xw_2 Yw_2 Zw_2]';
P_2 = bsxfun(@plus, F'*P_2, plane_center');
P_obj = [Xobj Yobj Zobj]';
P_obj = bsxfun(@plus, F'*P_obj, plane_center');

close all;
plot3(Xw_1(1:100:end), Yw_1(1:100:end), Zw_1(1:100:end), 'gx'); hold on;
% plot3(Xw, Yw, Zw, 'bo');
% plot3(Xw_2(1:100:end), Yw_2(1:100:end), Zw_2(1:100:end), 'bx'); hold on;
plot3(P_2(1, 1:100:end), P_2(2, 1:100:end), P_2(3, 1:100:end), 'rx');
hold on; plot3(plane_center(1), plane_center(2), plane_center(3), 'mx', 'MarkerSize', 30);
hold on; plot3(0, 0, 0, 'mx', 'MarkerSize', 30);
hold on; plot3(P_obj(1, :), P_obj(2, :), P_obj(3, :), 'bx');
% axis([-1 1 -1 1 -1 1]);
view([1 1 1]);
axis equal;