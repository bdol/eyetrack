%%
close all; clear;
addpath(genpath('../../MyNiViewer/Matlab'));

% Load the image/depth data
f_prefix = '~/code/eyetrack_data';
rgb = imread([f_prefix '/png_data/1001.2.E/IM_1_1.png']);
depth = load_raw_depth([f_prefix '/raw_data/1001.2.E/DP_1_1.raw']);

depth_sz = size(depth);
rgb_sz = size(rgb);

% Align the image/depth
% Project depth to 3D
params = load_calibration_params;

indices = 1:numel(depth);
[y_d x_d] = ind2sub(depth_sz,indices);
x_d = x_d(:)'; y_d = y_d(:)';
P3D_x = (x_d - params.cx_d) .* depth(indices) ./ params.fx_d;
P3D_y = (y_d - params.cy_d) .* depth(indices) ./ params.fy_d;
P3D_z = depth(indices);

% change FoR/viewpoint from depth to rgb
P3D_vp_rgb = bsxfun(@plus, params.R*[P3D_x; P3D_y; P3D_z], params.T(:));

% reproject 3d rgb to rgb pixels
% (y_d, x_d) in depth --> (P2D_rgb_y, P2D_rgb_x) in rgb
P3D_vp_rgb_x = P3D_vp_rgb(1,:);
P3D_vp_rgb_y = P3D_vp_rgb(2,:);
P3D_vp_rgb_z = P3D_vp_rgb(3,:);
P2D_rgb_x = round((P3D_vp_rgb_x * params.fx_rgb ./ P3D_vp_rgb_z) + params.cx_rgb);
P2D_rgb_y = round((P3D_vp_rgb_y * params.fy_rgb ./ P3D_vp_rgb_z) + params.cy_rgb);

% color the depth image
% depth(y_d(valid_ind), x_d(valid_ind))  -->
% rgb(P2D_rgb_y(valid_ind), P2D_rgb_x(valid_ind)
valid_x = find(P2D_rgb_x<=rgb_sz(2) & P2D_rgb_x>=1);
valid_y = find(P2D_rgb_y<=rgb_sz(1) & P2D_rgb_y>=1);
valid_ind = intersect(valid_x, valid_y);
depth_color = zeros([depth_sz 3]);
for channel = 1:3
    % channel 1
    d_ind = sub2ind(size(depth_color), y_d(valid_ind), x_d(valid_ind), channel*ones(size(y_d(valid_ind))));
    r_ind = sub2ind(rgb_sz, P2D_rgb_y(valid_ind), P2D_rgb_x(valid_ind), channel*ones(size(y_d(valid_ind))));
    depth_color(d_ind) = rgb(r_ind);
end
% display results
%     imshow(raw_depth./(max(raw_depth(:)))); hold on; 
[I thresh] = edge(depth, 'canny');
[xx yy] = ind2sub(size(I), find(I==1));
h = imshow(depth_color/255);
hold on; plot(yy,xx,'g.','MarkerSize',4); hold off;

%% First figure out the plane of the wall behind the person
P3D_wall_idx = P3D_z>0.85;
P3D_x_wall = -P3D_x(P3D_wall_idx);
P3D_y_wall = P3D_y(P3D_wall_idx);
P3D_z_wall = P3D_z(P3D_wall_idx);
rand_idx = randsample(numel(P3D_x_wall), 500);
[n_est ro_est Xp Yp Zp] = LSE([P3D_x_wall(rand_idx)' P3D_y_wall(rand_idx)' P3D_z_wall(rand_idx)']);

% Next, since we know the normal of the floor and a location on the floor,
% figure out some points to draw the floor using surface.
% First figure out the floor normal using Graham Schmidt (it will have a
% large y component)
[va vb] = gs_orthog(n_est);
n_floor = [];
if (abs(va(2))>abs(vb(2)))
    n_floor = vb;
else
    n_floor = vb;
end
n_floor = floor_orthog(n_est)';
% Now figure out the position of the base plate. The kinect is ~0.8m from
% the ground
if (n_floor(2) < 0)
    base_pos = -0.8636*n_floor;
else
    base_pos = 0.8636*n_floor;
end

% Now we have a point on the plane (the base plate) and a normal. Determine
% some floor points to plot using surface for debug
[Xf Yf Zf] = gen_plane_points(n_floor, 0.8636);


% DEBUG PLOT NORMAL VECTORS
p0 = [P3D_x_wall(rand_idx(1)) P3D_y_wall(rand_idx(1)) P3D_z_wall(rand_idx(1))];
p1 = p0-0.5*n_est';

% Plot the person/board/kinect/etc. in the metric space
P3D_person_idx = P3D_z<0.85;
close all;
% Plot the point clouds
plot3(-P3D_x(P3D_person_idx), ...
      P3D_y(P3D_person_idx), ...
      P3D_z(P3D_person_idx), 'b.'); hold on;
plot3(-P3D_x(P3D_wall_idx), ...
      P3D_y(P3D_wall_idx), ...
      P3D_z(P3D_wall_idx), 'r.'); hold on;
% Draw the kinect location
plot3(0, 0, 0, 'gx', 'MarkerSize', 20);
plot3(base_pos(1), base_pos(2), base_pos(3), 'go', 'MarkerSize', 20, 'MarkerFaceColor', 'g');
% plot3([p0(1); p1(1)], [p0(2); p1(2)], [p0(3); p1(3)], 'k');
% Draw the wall plane for debug
% x_sz = size(Xp);
% C = 0.9*ones(x_sz(1), x_sz(2), 3);
% surface(Xp, Yp, Zp, C);
% % Draw the floor plane for debug
x_sz = size(Xf);
C = 0.9*ones(x_sz(1), x_sz(2), 3);
surface(Xf, Yf, Zf, C);
% 
% view([0 0 -1])

% Plot the board
board_bottom_loc = base_pos-n_est*0.6096;
% (This routine is not entirely correct!! Need to 
% Get approximate points of left/right corners
board_vec = cross(n_floor, n_est);
board_br_corner = board_bottom_loc-board_vec*0.254;
board_tr_corner = board_br_corner-n_floor*0.8128;
board_bl_corner = board_bottom_loc+board_vec*0.762;
board_tl_corner = board_bl_corner-n_floor*0.8128;
plot3(board_bl_corner(1), board_bl_corner(2), board_bl_corner(3), 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
plot3(board_br_corner(1), board_br_corner(2), board_br_corner(3), 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
plot3(board_tl_corner(1), board_tl_corner(2), board_tl_corner(3), 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
plot3(board_tr_corner(1), board_tr_corner(2), board_tr_corner(3), 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

pos_1 = board_tl_corner-0.1651*board_vec+0.1397*n_floor;
pos_2 = board_tl_corner-0.8382*board_vec+0.1397*n_floor;
pos_3 = board_tl_corner-0.8382*board_vec+0.6858*n_floor;
pos_4 = board_tl_corner-0.1651*board_vec+0.6858*n_floor;
pos_5 = board_tl_corner-0.5207*board_vec+0.4064*n_floor;
pos_6 = board_tl_corner-0.3302*board_vec+0.2794*n_floor;
pos_7 = board_tl_corner-0.6858*board_vec+0.2794*n_floor;
pos_8 = board_tl_corner-0.6858*board_vec+0.5588*n_floor;
pos_9 = board_tl_corner-0.3302*board_vec+0.5588*n_floor;

text(pos_1(1), pos_1(2), pos_1(3), '1');
text(pos_2(1), pos_2(2), pos_2(3), '2');
text(pos_3(1), pos_3(2), pos_3(3), '3');
text(pos_4(1), pos_4(2), pos_4(3), '4');
text(pos_5(1), pos_5(2), pos_5(3), '5');
text(pos_6(1), pos_6(2), pos_6(3), '6');
text(pos_7(1), pos_7(2), pos_7(3), '7');
text(pos_8(1), pos_8(2), pos_8(3), '8');
text(pos_9(1), pos_9(2), pos_9(3), '9');

axis equal