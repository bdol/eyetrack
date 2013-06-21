close all
addpath(genpath('../../MyNiViewer/Matlab'));

%% Load Calibration params
params = load_calibration_params;

%% subject images
subjects = {'images/1006.2.E','images/1201.2.E', 'images/1203.2.E', 'images/1043.2.E', 'images/1037.2.E', 'images/1146.2.E', 'images/1135.2.E', 'images/1282.2.E'};
%% Load image
for image_ind = 1:length(subjects)
%     % Uncomment to run on grasp video
%     depth_name = sprintf('%s%d.raw','Captured_frames_2/Captured.onidepth_',image_ind);
%     rgb_name = sprintf('%s%d.raw','Captured_frames_2/Captured.onirgb_',image_ind);
%     [rgb temp raw_depth] = load_raw_images(depth_name, rgb_name);
%     raw_depth = fliplr(imrotate(raw_depth, -180));

    % Uncomment to run on subject images
    [rgb temp temp2 raw_depth] = display_images(2, 2, subjects{image_ind});
    raw_depth = fliplr(imrotate(raw_depth, -180));
    
    raw_depth(:,1:8) = [];
    % convert to meters
    depth = raw_depth./1000;
    
    rgb_sz = size(rgb);
    depth_sz = size(depth);
    
    % project depth pixels to 3d
    % [x_d y_d] = meshgrid(1:depth_sz(1), 1:depth_sz(2));
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
    h = imshow(depth_color);
    hold on; plot(yy,xx,'g.','MarkerSize',4); hold off;
%     hold off;alpha_mat = 0.5*ones(depth_sz);set(h, 'AlphaData', alpha_mat);
    
    print(gcf,'-dpng',sprintf('calibration_result_%02d',image_ind));
    pause(0.3);
%     pause;
end
