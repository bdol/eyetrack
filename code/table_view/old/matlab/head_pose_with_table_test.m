clear;
close all;
addpath(genpath('../../../../util/calibrate_kinect/'));
debug = 1;
% range -> 1 to 40
k1_image_idx = 10;
yaw_range = 5;
pitch_range = 5;

%% Load all calibration parameters
[K_rgb_1, K_ir_1, R_1, T_1] = parse_kinect_yaml('../../../../util/calibrate_kinect/grasp18.yml');
[K_rgb_2, K_ir_2, R_2, T_2] = parse_kinect_yaml('../../../../util/calibrate_kinect/grasp8.yml');
% K_rgb_2(:,4) = [0;0;0];
% K_ir_2(:,4) = [0;0;0];
% K_rgb_1(:,4) = [0;0;0];
% K_ir_1(:,4) = [0;0;0];
fx_d_1 = K_ir_1(1, 1);
fy_d_1 = K_ir_1(2, 2);
cx_d_1 = K_ir_1(1, 3);
cy_d_1 = K_ir_1(2, 3);
fx_d_2 = K_ir_2(1, 1);
fy_d_2 = K_ir_2(2, 2);
cx_d_2 = K_ir_2(1, 3);
cy_d_2 = K_ir_2(2, 3);
fx_rgb_2 = K_rgb_2(1, 1);
fy_rgb_2 = K_rgb_2(2, 2);
cx_rgb_2 = K_rgb_2(1, 3);
cy_rgb_2 = K_rgb_2(2, 3);

%% First test object detection
im_prefix = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images';
D = imread(sprintf('%s/table_top_training_0/k2/depth_3.png',im_prefix));
im = imread(sprintf('%s/table_top_training_0/k2/rgb_3.png',im_prefix));
D_m_2 = raw_depth_to_meters2(D);
D_m_2(D_m_2==2047) = 0;
% D_m_2 = double(D)./1000;

% Fit plane
fprintf('Fitting plane... ');
[xx yy] = meshgrid(1:size(D, 2), 1:size(D, 1));
X = xx(:); Y = yy(:);
Z = D_m_2(:);

[Xw Yw Zw] = im_to_world(X, Y, Z, fx_d_2, fy_d_2, cx_d_2, cy_d_2);

% Remove bad depth points
Xw(Z==0) = [];
Yw(Z==0) = [];
Zw(Z==0) = [];
% Remove far depth points (more than 2m)
Xw(Zw>1) = [];
Yw(Zw>1) = [];
Zw(Zw>1) = [];

% Least squares to fit table cloud points
% [n_est ro_est Xp Yp Zp] = LSE([Xw Yw Zw]);
% table_plane = [Xw Yw Zw];
[n_est n_inliers Xin Yin Zin] = ransac_fit_plane([Xw Yw Zw]);
table_plane = [Xin(:) Yin(:) Zin(:)];
% hp = size(Xp, 1); wp = size(Xp, 2);
fprintf('Done!\n');
if(debug)
    figure;
    subplot(1,2,1);
    P = [table_plane(:,1)./table_plane(:,3) table_plane(:,2)./table_plane(:,3) ones(numel(Xin), 1)]';
    pi = K_ir_2*P;
    imagesc(D_m_2); hold on;
    plot(pi(1,:), pi(2,:), 'r.'); hold off;
    subplot(1,2,2);
    P_rgb = bsxfun(@minus, R_2'*P, T_2);
    Xobj_plot_rgb = P_rgb(1, :)';
    Yobj_plot_rgb = P_rgb(2, :)';
    Zobj_plot_rgb = P_rgb(3, :)';
    % Calculate transform to rgb image plane
    P = [Xobj_plot_rgb./Zobj_plot_rgb Yobj_plot_rgb./Zobj_plot_rgb ones(numel(Xobj_plot_rgb), 1)]';
    pi = K_rgb_2*P;
    imshow(im); hold on;
    plot(pi(1,:), pi(2,:),'r.'); hold off;
end

% Now detect objects by finding points that are deviate from this plane
fprintf('Finding objects... ');
D = point_plane_dist(n_est', [Xin(1) Yin(1) Zin(1)], [Xw Yw Zw]);
thresh = 0.02;
obj_idx = D>thresh;
Xobj = Xw(obj_idx);
Yobj = Yw(obj_idx);
Zobj = Zw(obj_idx);

Xw(obj_idx) = [];
Yw(obj_idx) = [];
Zw(obj_idx) = [];

[L C D] = fkmeans([Xobj Yobj Zobj], 3);

Pobj_1 = [Xobj(L==1) Yobj(L==1) Zobj(L==1)];
Pobj_2 = [Xobj(L==2) Yobj(L==2) Zobj(L==2)];
Pobj_3 = [Xobj(L==3) Yobj(L==3) Zobj(L==3)];

% Determine orientation of table so that hulls appear to sit on it
R = determine_plane_rotation(n_est);

% Determine the actual hull cube location
P = [(Xobj)'; (Yobj)'; (Zobj)'];
P_rot = R'*P;
X_rot = P_rot(1, :)';
Y_rot = P_rot(2, :)';
Z_rot = P_rot(3, :)';

if(debug)
    figure;
    plot3(table_plane(:,1), table_plane(:,2), table_plane(:,3), 'b.');
    hold on;
    plot3(Xobj, Yobj, Zobj, 'k.');
end



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
R = R_2;
T = T_2;


P = [Xobj_plot./Zobj_plot Yobj_plot./Zobj_plot ones(numel(Xobj_plot), 1)]';
pi = K_ir_2*P;
% pi = bsxfun(@rdivide, pi, pi(3, :));
if(debug)
    figure;
    subplot(1,2,1); imagesc(D_m_2); hold on;
    plot(pi(1,:), pi(2,:), 'r.');
end


Pd = [Xobj_plot Yobj_plot Zobj_plot]';
Pd_r = R'*Pd;
P_rgb = bsxfun(@minus, Pd_r, T);
Xobj_plot_rgb = P_rgb(1, :)';
Yobj_plot_rgb = P_rgb(2, :)';
Zobj_plot_rgb = P_rgb(3, :)';

% Calculate transform to rgb image plane
P = [Xobj_plot_rgb./Zobj_plot_rgb Yobj_plot_rgb./Zobj_plot_rgb ones(numel(Xobj_plot_rgb), 1)]';
pi = K_rgb_2*P;
% pi = bsxfun(@rdivide, pi, pi(3, :));
im = imread(sprintf('%s/table_top_training_0/k2/rgb_3.png',im_prefix));
if(debug)
    subplot(1,2,2);
    imshow(im); hold on;
    plot(pi(1,:), pi(2,:),'r.');
end

% Plot boxes
B2D_1 = bsxfun(@minus, R'*(B1_trans'), T);
B2D_1 = K_rgb_2*[B2D_1(1,:)./B2D_1(3,:); B2D_1(2,:)./B2D_1(3,:); ones(1, size(B2D_1, 2))];
B2D_1(3, :) = [];
draw_box_2d(B2D_1', 'g');
B2D_2 = bsxfun(@minus, R'*(B2_trans'), T);
B2D_2 = K_rgb_2*[B2D_2(1,:)./B2D_2(3,:); B2D_2(2,:)./B2D_2(3,:); ones(1, size(B2D_2, 2))];
B2D_2(3, :) = [];
draw_box_2d(B2D_2', 'm');
B2D_3 = bsxfun(@minus, R'*(B3_trans'), T);
B2D_3 = K_rgb_2*[B2D_3(1,:)./B2D_3(3,:); B2D_3(2,:)./B2D_3(3,:); ones(1, size(B2D_3, 2))];
B2D_3(3, :) = [];
draw_box_2d(B2D_3', 'b'); hold off;

%% Checkerboard corner data
% fid = fopen(sprintf('%s/table_top_test_0/checkerboard_corners.txt',im_prefix));
% C_text = textscan(fid, '%s', 2, 'delimiter', ',');
% C_data0 = textscan(fid, '%s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'delimiter',',');
% fclose(fid);
% % Count of valid checkerboard images
% valid_idx = find(~isnan(C_data0{2}));
% N = sum(~isnan(C_data0{2}));
% all_corners = [C_data0{2:25}];
% all_camera_centers = [C_data0{26:29}];
% img_idx = zeros(N, 1);
% C = zeros(12, 3, N);
% Y = zeros(2, 3, N);
% im_count = 1;
% for i=valid_idx'
%     im_count
%     % Get corner data
%     C(:, 1:2, im_count) = reshape(all_corners(i,:),2,12)';
%     Y(:, 1:2, im_count) = reshape(all_camera_centers(i,:),2,2)';
%
%     % Get depth data
%     depth_file_name = strrep(C_data0{1}{i},'IM_','DP_');
%     depth = imread(depth_file_name);
%     depth = double(depth)./1000;
%
%
%     [W depth_x depth_y] = get_warp_map_diffres([1024, 1280], depth, K_ir_1, K_rgb_1, R_1, ...
%         T_1, [C(:, :, im_count); Y(:,:,im_count)]);
%     if(debug)
%         figure
%         imshow(depth); colormap('jet'); hold on;
%         plot(depth_x, depth_y, 'c*');
%     end
%     for j=1:12
%         C(j, 1, im_count) = depth_x(j);
%         C(j, 2, im_count) = depth_y(j);
%         C(j, 3, im_count) = depth(depth_y(j), depth_x(j));
%     end
%     for j = 1:2
%         Y(j,3,im_count) = depth(depth_y(j+12), depth_x(j+12));
%     end
%
%     img_idx(im_count) = i;
%     im_count = im_count+1;
% end

% Determine k2 plane
rgbBase = sprintf('%s/table_top_training_0/k1_png/IM_For_Katie_',im_prefix);
depthBase = sprintf('%s/table_top_training_0/k1_raw/DP_For_Katie_',im_prefix);

N = 0;
for i=0:39
    if exist([rgbBase num2str(i) '.txt'], 'file')
        N = N+1;
    end
end

img_idx = zeros(N, 1);

Corners = zeros(12, 3, N);
Y = zeros(2, 3, N);
im_count = 1;
for i=0:40
    i
    if ~exist([rgbBase num2str(i) '.txt'], 'file')
        continue;
    end
    % Get corner data
    c_data = load([rgbBase num2str(i) '.txt']);
    Corners(:, 1:2, im_count) = c_data(1:12, :);
    Y(:, 1:2, im_count) = c_data(13:14, :);
    
    % Get depth data
    depth = get_raw_image([depthBase num2str(i) '.raw']);
    depth = flipdim(depth/1000, 2);
    
    
    W = get_warp_map(size(depth, 1), size(depth, 2), depth, K_ir_1, K_rgb_1, R_1, T_1);
    for j=1:12
        x = floor(640/1280*Corners(j, 1, im_count));
        y = floor(480/960*Corners(j, 2, im_count));
        Corners(j, 1, im_count) = x;
        Corners(j, 2, im_count) = y;
        Corners(j, 3, im_count) = W(y, x);
    end
    for j=1:2
        x = floor(640/1280*Y(j, 1, im_count));
        y = floor(480/960*Y(j, 2, im_count));
        Y(j, 3, i+1) = W(y, x);
    end
    img_idx(im_count) = i;
    im_count = im_count+1;
end

%% Find plane of checkerboard
close all;
addpath ../test_code/
Xw = []; Yw = []; Zw = [];
for i=1:im_count-1
    C_i = Corners(:, :, i);
    [X Y Z] = im_to_world(C_i(:, 1), C_i(:, 2), C_i(: ,3), fx_d_1, fy_d_1, cx_d_1, cy_d_1);
    Xw = [Xw; X];
    Yw = [Yw; Y];
    Zw = [Zw; Z];
end
[n, rho] = svd_find_plane([X Y Z]);
R_orient = determine_plane_rotation(n);
plot3(Xw, Yw, Zw, 'bo'); axis equal;
plane_center = mean([Xw, Yw, Zw]);

%% head pose output
fid = fopen(sprintf('%s/table_top_training_0/k1_png/head_pose_output.txt',im_prefix));
C_text = textscan(fid, '%s', 7, 'delimiter', ',');
C_data0 = textscan(fid, '%s %f %f %f %f %f %f', 'delimiter',',');
fclose(fid);
head_center_3d_k1 = zeros(3, length(C_data0{1}));
head_front_3d_k1 = zeros(3, length(C_data0{1}));
head_pose_direction_k1 = zeros(3, length(C_data0{1}));
fov_front_k1 = zeros(3, 4, length(C_data0{1}));
fov_dirn_k1 = zeros(3, 4, length(C_data0{1}));
for i = 1:length(C_data0{1})
    % K1 image with person
    k1_im = imread(sprintf('%s', C_data0{1}{i}));
    [width height] = size(k1_im);
    head_pose = [C_data0{2}(i), C_data0{3}(i), C_data0{4}(i)];
    [head_center_3d_k1(1,i) head_center_3d_k1(2,i), head_center_3d_k1(3,i)] = deal(C_data0{5}(i), C_data0{6}(i), C_data0{7}(i));
    g_face_dir = [0;0;-1];
    % convert euler angles to rotation matrix
    theta_x = 0.0174532925*head_pose(1);
    theta_y = 0.0174532925*head_pose(2);
    theta_z = 0.0174532925*head_pose(3);
    rot_matrix = euler_to_rotation_matrix(theta_x, theta_y, theta_z);
    g_face_curr_dir = rot_matrix * g_face_dir;
    [head_pose_direction_k1(1,i) head_pose_direction_k1(2,i) head_pose_direction_k1(3,i)] = deal(g_face_curr_dir(1), g_face_curr_dir(2), g_face_curr_dir(3));
    % 150 is an arbit length for the vector
    head_front = head_center_3d_k1(:,i) + 200*g_face_curr_dir;
    [head_front_3d_k1(1,i) head_front_3d_k1(2,i), head_front_3d_k1(3,i)] = deal(head_front(1), head_front(2), head_front(3));
    
    % head pose direction for the field of view given by yaw_range and
    % pitch_range
    theta_x_l = 0.0174532925*(head_pose(1) - yaw_range);
    theta_x_r = 0.0174532925*(head_pose(1) + yaw_range);
    theta_y_u = 0.0174532925*(head_pose(2) - pitch_range);
    theta_y_d = 0.0174532925*(head_pose(2) + pitch_range);
    angle_limits = [theta_x_l theta_x_r theta_x_r theta_x_l;
                    theta_y_u theta_y_u theta_y_d theta_y_d];
    for dir = 1:4
        rot_matrix = euler_to_rotation_matrix(angle_limits(1,dir), angle_limits(2,dir), theta_z);
        g_face_curr_dir = rot_matrix * g_face_dir;
        head_front = head_center_3d_k1(:,i) + 200*g_face_curr_dir;
        [fov_front_k1(1,dir,i) fov_front_k1(2,dir,i) fov_front_k1(3,dir,i)] = deal(head_front(1), head_front(2), head_front(3));
        [fov_dirn_k1(1,dir,i) fov_dirn_k1(2,dir,i) fov_dirn_k1(3,dir,i)] = deal(g_face_curr_dir(1), g_face_curr_dir(2), g_face_curr_dir(3));
    end
    
    % a = ([head_center(1)*fx_d_1/head_center(3) head_center(2)*fy_d_1/head_center(3)] + [cx_d_1 cy_d_1]);
    %     head_center_2d = [(head_center_3d(1,i)*575.8157/head_center_3d(3,i) + 320), (head_center_3d(2,i)*575.8157/head_center_3d(3,i) + 240)];
    %     head_front_2d = [(head_front_3d(1,i)*575.8157/head_front_3d(3,i) + 320), (head_front_3d(2,i)*575.8157/head_front_3d(3,i) + 240)];
end
% convert to meters
head_center_3d_k1 = head_center_3d_k1./1000;
head_front_3d_k1 = head_front_3d_k1./1000;
fov_front_k1 = fov_front_k1./1000;

%% Plot Results for image index = k1_image_idx

% K2 image with objects
D_2 = imread(sprintf('%s/table_top_training_0/k2/depth_9.png',im_prefix));
D_m_2 = flipdim(raw_depth_to_meters2(D_2), 2);
D_m_2(D_m_2==2047) = 0;
[xx yy] = meshgrid(1:size(D_2, 2), 1:size(D_2, 1));
X_2 = xx(:); Y_2 = yy(:); Z_2 = D_m_2(:);

[Xw_2 Yw_2 Zw_2] = im_to_world(X_2, Y_2, Z_2, fx_d_2, fy_d_2, cx_d_2, cy_d_2);
Xw_2(Z_2==0) = [];
Yw_2(Z_2==0) = [];
Zw_2(Z_2==0) = [];

% Transform objects to K1 frame
F = determine_k2_frame(Corners, fx_d_1, fy_d_1, cx_d_1, cy_d_1);
P_2 = [Xw_2 Yw_2 Zw_2]';
P_2 = bsxfun(@plus, F'*P_2, plane_center');
P_obj_k1 = [Xobj Yobj Zobj]';
P_obj_k1 = bsxfun(@plus, F'*P_obj_k1, plane_center');
% Transform table plane to K1 plane
table_plane_k1 = bsxfun(@plus, F'*table_plane', plane_center');

% Plot K2 checkerboard as well
Cxw = [];   Cyw = [];   Czw = [];
for i=1:N
    C_i = Corners(:, :, i);
    [X Y Z] = im_to_world(C_i(:, 1), C_i(:, 2), C_i(: ,3), fx_d_1, fy_d_1, cx_d_1, cy_d_1);
    Cxw = [Cxw; X];
    Cyw = [Cyw; Y];
    Czw = [Czw; Z];
end

head_pose_table_intersection_k1 = vector_plane_intersection(table_plane_k1, ...
    head_center_3d_k1(:,k1_image_idx), head_pose_direction_k1(:,k1_image_idx));

% Finally, the plot!
figure;
hold on;
plot3(table_plane_k1(1,:), table_plane_k1(2,:), table_plane_k1(3,:), 'b.');
plot3(P_obj_k1(1,:), P_obj_k1(2,:), P_obj_k1(3,:), 'k.');
line([head_center_3d_k1(1,k1_image_idx) head_front_3d_k1(1,k1_image_idx)], ...
    [head_center_3d_k1(2,k1_image_idx) head_front_3d_k1(2,k1_image_idx)], ...
    [head_center_3d_k1(3,k1_image_idx) head_front_3d_k1(3,k1_image_idx)], ...
    'LineWidth', 3, 'Color', 'y');
plot3(head_center_3d_k1(1,k1_image_idx), head_center_3d_k1(2,k1_image_idx), ...
    head_center_3d_k1(3,k1_image_idx), 'r*', 'MarkerSize', 20);
plot3(head_front_3d_k1(1,k1_image_idx), head_front_3d_k1(2,k1_image_idx), ...
    head_front_3d_k1(3,k1_image_idx), 'g*', 'MarkerSize', 20);
plot3(head_pose_table_intersection_k1(1), head_pose_table_intersection_k1(2), ...
    head_pose_table_intersection_k1(3), 'c.', 'MarkerSize', 50);
draw_field_of_view(table_plane_k1, head_center_3d_k1(:,k1_image_idx), fov_dirn_k1(:,:,k1_image_idx), 'm.')

view([-67 -32]);
axis equal;
grid on
xlabel('x axis'); ylabel('y axis'); zlabel('z axis');
hold off;
title('View wrt Kinect K1');
