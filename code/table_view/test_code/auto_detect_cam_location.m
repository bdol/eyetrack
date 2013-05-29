clear; close all;
addpath ../../../util/raw_processing/
addpath ../matlab/

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
    if ~exist([rgbBase num2str(i) '.txt'], 'file')
        continue;
    end
    % Get corner data
    c_data = load([rgbBase num2str(i) '.txt']);
    C(:, 1:2, im_count) = c_data(1:12, :);
    Y(:, 1:2, im_count) = c_data(13:14, :);

    % Get depth data
    depth = get_raw_image([depthBase num2str(i) '.raw'])*255;
    depth = depth/1000;
    keyboard;
    for j=1:12
        x = floor(640/1280*C(j, 1, im_count));
        y = floor(480/960*C(j, 2, im_count));
        C(j, 3, im_count) = depth(y, x);
    end    
    for j=1:2
        x = floor(640/1280*Y(j, 1, im_count));
        y = floor(480/960*Y(j, 2, im_count));
        Y(j, 3, i+1) = depth(y, x);
    end

    img_idx(im_count) = i;
    im_count = im_count+1;
end


%% Plot plane checkerboard on image
K_rgb = [ 1.0661384277343750e+03, 0., 640.; 
          0., 1.0661384277343750e+03, 480.;
          0., 0., 1. ];
for i=1:N
    fx = K_rgb(1, 1);
    fy = K_rgb(2, 2);
    cx = K_rgb(1, 3);
    cy = K_rgb(2, 3);
    [Xw Yw Zw] = im_to_world(C(:, 1, i)', C(:, 2, i)', C(:, 3, i)', fx, fy, cx, cy);
    [Xw_cam Yw_cam Zw_cam] = im_to_world(Y(:, 1, i)', Y(:, 2, i)', Y(:, 3, i)', fx, fy, cx, cy);
    
    % First find mesh to draw on original image
    P = [Xw; Yw; Zw];
    [n rho Xp Yp Zp] = svd_find_plane(P');
    
    corners = [ Xw(1), Yw(1), Zw(1);
                Xw(4), Yw(4), Zw(4);
                Xw(9), Yw(9), Zw(9);
                Xw(12), Yw(12), Zw(12) ]';
    R = determine_plane_rotation(n);
    P_T = mean(corners, 2);
    P = R'*bsxfun(@minus, corners, P_T);
    [~, ~, V] = svd(P*P');
    P = V'*P;
    xmax = max(P(1, :));
    xmin = min(P(1, :));
    ymax = max(P(2, :));
    ymin = min(P(2, :));
    [Xp Yp] = meshgrid(linspace(xmin, xmax, 4), linspace(ymin, ymax, 3));
    Zp = zeros(size(Xp));
    % Now that we've found the mesh points, transform them back
    Xp = Xp(:); Yp = Yp(:); Zp = Zp(:);
    Pp = [Xp Yp Zp]';
    Pp = bsxfun(@plus, R*(V*Pp), P_T);
    Pp = K_rgb*Pp;
    Pp = bsxfun(@rdivide, Pp, Pp(3, :));
    Xp = reshape(Pp(1, :), [3 4]);
    Yp = reshape(Pp(2, :), [3 4]);
    Zp = reshape(Pp(3, :), [3 4]);
    hp = size(Xp, 1);
    wp = size(Xp, 2);
    
    close all;
    imshow(['/Users/bdol/Desktop/campostest/tv_rgb_' num2str(img_idx(i)) '.png']);
    hold on;
    for gx=1:wp
        if mod(gx, 2)==1
            clr = 1;
        else
            clr = 0;
        end
        for gy=1:hp
            Zp(gy, gx) = clr;
            clr = 1-clr;
        end
    end
    h = pcolor(Xp, Yp, Zp); colormap('gray'); caxis([0 1]);
    keyboard;
end

%% Determine avg. camera positions
close all;
P_cam_sum = zeros(3, 2);
c = 0;
fx = K_rgb(1, 1);
fy = K_rgb(2, 2);
cx = K_rgb(1, 3);
cy = K_rgb(2, 3);
for i=1:N
    [Xw Yw Zw] = im_to_world(C(:, 1, i)', C(:, 2, i)', C(:, 3, i)', fx, fy, cx, cy);
    [Xw_cam Yw_cam Zw_cam] = im_to_world(Y(:, 1, i)', Y(:, 2, i)', Y(:, 3, i)', fx, fy, cx, cy);
    
    % First find mesh to draw on original image
    P = [Xw; Yw; Zw];
    [n rho Xp Yp Zp] = svd_find_plane(P');
    
    corners = [ Xw(1), Yw(1), Zw(1);
                Xw(4), Yw(4), Zw(4);
                Xw(9), Yw(9), Zw(9);
                Xw(12), Yw(12), Zw(12) ]';
    R = determine_plane_rotation(n);
    P_T = mean(corners, 2);
    P = R'*bsxfun(@minus, corners, P_T);
    [~, ~, V] = svd(P*P');
    P = V'*P;
    
    P_cam = [Xw_cam; Yw_cam; Zw_cam];
    P_cam = V'*(R'*bsxfun(@minus, P_cam, P_T));
    
    if abs(P_cam(3, 1)) > 0.25 || abs(P_cam(3, 2)) > 0.25 || P_cam(1, 1) > 0.01
        continue;
    end
    P_cam_sum = P_cam_sum+P_cam;
    c = c+1;
    
    plot3(P(1, :), P(2, :), P(3, :), 'b*'); hold on;
    plot3(P_cam(1, :), P_cam(2, :), P_cam(3, :), 'g*');
end
P_cam_avg = P_cam_sum./c;
plot3(P_cam_avg(1, :), P_cam_avg(2, :), P_cam_avg(3, :), 'm*'); axis equal;

%% Test avg. camera positions
for i=1:N
    [Xw Yw Zw] = im_to_world(C(:, 1, i)', C(:, 2, i)', C(:, 3, i)', fx, fy, cx, cy);
    P = [Xw; Yw; Zw];
    [n rho Xp Yp Zp] = svd_find_plane(P');
    
    corners = [ Xw(1), Yw(1), Zw(1);
                Xw(4), Yw(4), Zw(4);
                Xw(9), Yw(9), Zw(9);
                Xw(12), Yw(12), Zw(12) ]';
    R = determine_plane_rotation(n);
    P_T = mean(corners, 2);
    P = R'*bsxfun(@minus, corners, P_T);
    [~, ~, V] = svd(P*P');
    P_cam = P_cam_avg;
    P_cam = K_rgb*bsxfun(@plus, R*(V*P_cam), P_T);
    P_cam = bsxfun(@rdivide, P_cam, P_cam(3, :));
    
    close all;
    imshow(['/Users/bdol/Desktop/campostest/tv_rgb_' num2str(img_idx(i)) '.png']);
    hold on;
    plot(P_cam(1, :), P_cam(2, :), 'm*');
    keyboard;
end