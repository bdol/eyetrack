
clear;
D = imread('images/depth_0.png');
D_m = raw_depth_to_meters2(D);
D_m(D_m==2047) = 0;

%% Fit plane 
[xx yy] = meshgrid(1:size(D, 2), 1:size(D, 1));
X = xx(:); Y = yy(:);
Z = D_m(:);

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
% n_est = svd_find_plane([Xw Yw Zw]);
% norm(abs(n-n_est))
hp = size(Xp, 1); wp = size(Xp, 2);

% Show the fitted plane for debugging purposes
close all;
plot3(Xw(1:100:end), Yw(1:100:end), Zw(1:100:end),'ok'); hold on;
mesh(Xp,Yp,Zp);colormap([.8 .8 .8])
axis('off');

%% Now detect objects by finding points that are deviate from this plane
D = imread('images/depth_3.png');
D_m = raw_depth_to_meters2(D);
D_m(D_m==2047) = 0;

[xx yy] = meshgrid(1:size(D, 2), 1:size(D, 1));
X = xx(:); Y = yy(:);
Z = D_m(:);

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

close all;
plot3(Xw(1:100:end), Yw(1:100:end), Zw(1:100:end),'ok'); hold on;
plot3(Xobj, Yobj, Zobj,'rx');

%% Determine object clusters
% TODO: we need to do hierarchical clustering or something when # of
% objects is unknown
[L C D] = fkmeans([Xobj Yobj Zobj], 3);
close all;
plot3(Xobj(L==1), Yobj(L==1), Zobj(L==1),'rx'); hold on;
plot3(Xobj(L==2), Yobj(L==2), Zobj(L==2),'bx'); hold on;
plot3(Xobj(L==3), Yobj(L==3), Zobj(L==3),'gx');

%% Determine the rotation that maps plane to parallel to the Z-plane so we 
%  can determine the actual hulls
R = determine_plane_rotation(n_est);

%% Determine the actual hull cube location
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

B1 = make_box_3d(hulls(1, :));
B2 = make_box_3d(hulls(2, :));
B3 = make_box_3d(hulls(3, :));
B1_trans = (R*B1')';
B2_trans = (R*B2')';
B3_trans = (R*B3')';
close all; plot3(Xw(1:100:end), Yw(1:100:end), Zw(1:100:end), 'ok'); hold on;
plot3(Xobj, Yobj, Zobj, 'or'); hold on;
draw_box_3d(B1_trans, 'g');
draw_box_3d(B2_trans, 'b');
draw_box_3d(B3_trans, 'm');

% P = [(Xw)'; (Yw)'; (Zw)'];
% P_rot = R'*P;
% X_rot = P_rot(1, :)';
% Y_rot = P_rot(2, :)';
% Z_rot = P_rot(3, :)';
% plot3(X_rot(1:100:end), Y_rot(1:100:end), Z_rot(1:100:end),'ok');
% axis([-1 0 -1 1 0 1]);



%% Plot them on the Depth image
skip = 10;
Xobj_plot = Xobj(1:skip:end);
Yobj_plot = Yobj(1:skip:end);
Zobj_plot = Zobj(1:skip:end);
L_plot = L(1:skip:end);

% Calculate transform to Depth image plane
fx = 5.6009202708545865e+02;
fy = 5.5885814292051782e+02;
cx = 3.0015891816197120e+02;
cy = 2.5149932242225375e+02;
K = [fx 0 cx 0; 0 fy cy 0; 0 0 1 0];
P = [Xobj_plot Yobj_plot Zobj_plot ones(numel(Xobj_plot), 1)]';
pi = K*P;
pi = bsxfun(@rdivide, pi, pi(3, :));
im = imread('images/depth_3.png');
close all; imagesc(im); hold on;
for i=1:size(pi, 2)
    x = pi(1, i); y = pi(2, i);
    if L_plot(i)==1
        plot(x, y, 'rx');
    elseif L_plot(i)==2
        plot(x, y, 'wx');
    else
        plot(x, y, 'gx');
    end
end

%% Plot the points on the RGB image
R = [ 9.9993189761892909e-01, -3.2729355538435750e-03, 1.1202143414009318e-02; 
    3.3304519065922894e-03, 9.9998134867689581e-01, -5.1196082305675792e-03;
    -1.1185178331413474e-02, 5.1565677729480267e-03, 9.9992414792047979e-01 ];
T = [ 2.8788567238524864e-02; 6.3401893265889063e-04;
       1.3891577580578355e-03 ];
K_rgb = [ 4.9726263121508453e+02, 0., 3.1785221776747596e+02; 0., ...
       4.9691535190126677e+02, 2.7311575302513319e+02; 0., 0., 1. ];
im = imread('images/rgb_3.png');
close all; imshow(im); hold on;
pi = R'*P(1:3, :);
pi = K_rgb*bsxfun(@minus, pi, T);
pi = bsxfun(@rdivide, pi, pi(3, :));
for i=1:size(pi, 2)
    x = pi(1, i); y = pi(2, i);
    if L_plot(i)==1
        plot(x, y, 'rx');
    elseif L_plot(i)==2
        plot(x, y, 'wx');
    else
        plot(x, y, 'gx');
    end
end

%% Plot them on the RGB image
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
im = imread('images/rgb_5.png');
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


% for i=1:size(pi, 2)
%     x = pi(1, i); y = pi(2, i);
%     if L_plot(i)==1
%         plot(x, y, 'rx');
%     elseif L_plot(i)==2
%         plot(x, y, 'wx');
%     else
%         plot(x, y, 'gx');
%     end
% end