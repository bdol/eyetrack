clear;
fid = fopen('~/code/eyetrack/util/face_tracker/bin/new_eye_points_corrected.txt');

line = fgets(fid);
i = 1;
data = {};
while ischar(line)
    C = regexp(line, ' ', 'split');
    fname = C{1};
    fname = strrep(fname, '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data/', ...
                    '/Users/bdol/code/eyetrack_data/png_data/');
    fname = strrep(fname, '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data2/', ...
                    '/Users/bdol/code/eyetrack_data/png_data/');
    fname = strrep(fname, 'jpg', 'png');
        
    
    corr_left = str2double(C(2:13));
    corr_left = reshape(corr_left, [2, 6])';
    corr_right = str2double(C(14:25));
    corr_right = reshape(corr_right, [2, 6])';
    
    data{i}.fname = fname;
    data{i}.corr_left = corr_left;
    data{i}.corr_right = corr_right;
    i = i+1;
    line = fgets(fid);
end

fclose(fid);

%%
w = 100;
h = 50;

imw = size(flipdim(imread(fname), 2), 2);

outDir = '/Users/bdol/code/eyetrack_data/cropped_eyes_transformed_tps_corrected/';
canon_corresp = gen_canon_corresp_points(w, h, 20, 10);
for i=1:numel(data)
    fname = data{i}.fname;
    
    try
        corr_left = data{i}.corr_left;
        corr_right = data{i}.corr_right;
        % Fix the coorindates because they were recorded on mirrored images
        corr_left(:, 1) = imw-corr_left(:, 1);
        corr_right(:, 1) = imw-corr_right(:, 1);

        subjnum = regexp(fname, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
        outPath = strcat(outDir, subjnum{1}, '/');
        outPath = outPath{1};
        image_num = regexp(fname, '.*(IM_\d_\d).*', 'tokens');
        inum = image_num{1}{1};
        classNum = inum(4);

        left_fname = strcat(outPath, classNum, '/', image_num{1}, '_left.png');
        right_fname = strcat(outPath, classNum, '/', image_num{1}, '_right.png');
        
        if ~exist([outPath '/' classNum '/'], 'dir')
            mkdir([outPath '/' classNum '/'])
            fprintf('Processing %s.\n', fname);
        elseif exist(left_fname{1}, 'file') && ...
                exist(right_fname{1}, 'file')
            fprintf('Skipping %s.\n', fname);
            continue;
        end

        im = flipdim(imread(fname), 2);
        
        % Calculate raw correspondences relative to the eye centroids
        centroid_right = calculate_eye_centroid(corr_right);
        centroid_left = calculate_eye_centroid(corr_left);    
        corr_left = bsxfun(@minus, corr_left, centroid_left);
        corr_right = bsxfun(@minus, corr_right, centroid_right);

        st_l = tpaps(canon_corresp', corr_left', 1);
        im_warp_l = tps_warp(st_l, im, centroid_left, w, h);
        st = tpaps(canon_corresp', corr_right', 1);
        im_warp_r = tps_warp(st, im, centroid_right, w, h);

        left_fname = strcat(outPath, classNum, '/', image_num{1}, '_left.png');
        right_fname = strcat(outPath, classNum, '/', image_num{1}, '_right.png');
        imwrite(im_warp_l/255, left_fname{1}, 'png');
        imwrite(im_warp_r/255, right_fname{1}, 'png');
    catch e
        disp(e);
    end
    
%     % DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     close all; figure;
%     subplot(2, 3, 1);
%     % Show left eye untransformed with correspondence
%     [cx cy] = crop_eye(data{i}.corr_left, w, h);
%     imshow(im(cy:cy+h-1, cx:cx+w-1, :)); hold on;
%     plot(corr_left(:, 1)+w/2, corr_left(:, 2)+h/2, 'mx');
%     
%     
%     st = tpaps(canon_corresp', corr_left', 1);
%     subplot(2, 3, 2);
%     fnplt(st);
%     
%     im_warp = tps_warp(st, im, centroid_left, w, h);
%     subplot(2, 3, 3);
%     imshow(im_warp/255); hold on;
%     plot(canon_corresp(:, 1)+w/2, canon_corresp(:, 2)+h/2, 'go', 'MarkerSize', 10);
%     stinv = tpaps(corr_left', canon_corresp', 1);
%     pts = fnval(stinv, corr_left');
%     pts = pts';
%     plot(pts(:, 1)+w/2, pts(:, 2)+h/2, 'mx');
%     
%     % Show right eye untransformed with correspondence
%     subplot(2, 3, 4);
%     [cx cy] = crop_eye(data{i}.corr_right, w, h);
%     imshow(im(cy:cy+h-1, cx:cx+w-1, :)); hold on;
%     plot(corr_right(:, 1)+w/2, corr_right(:, 2)+h/2, 'mx');
%     
%     st = tpaps(canon_corresp', corr_right', 1);
%     subplot(2, 3, 5);
%     fnplt(st);
%     
%     im_warp = tps_warp(st, im, centroid_right, w, h);    
%     subplot(2, 3, 6); imshow(im_warp/255); hold on;
%     plot(canon_corresp(:, 1)+w/2, canon_corresp(:, 2)+h/2, 'go', 'MarkerSize', 10);
%     stinv = tpaps(corr_right', canon_corresp', 1);
%     pts = fnval(stinv, corr_right');
%     pts = pts';
%     plot(pts(:, 1)+w/2, pts(:, 2)+h/2, 'mx');
%     keyboard;
%     % DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%     % Calculate the homography
% %     H_left = findHomography(canon_corresp, corr_left);
% %     H_right = findHomography(canon_corresp, corr_right);
%     tleft = cp2tform(corr_left, canon_corresp, 'piecewise linear');
%     tright = cp2tform(corr_right, canon_corresp, 'piecewise linear');
% 
% %     crop_left = transformEye(w, h, centroid_left, im, H_left);
% %     crop_right = transformEye(w, h, centroid_right, im, H_right);
%     crop_left = transformEyeIPT(w, h, centroid_left, im, tleft);
%     crop_right = transformEyeIPT(w, h, centroid_right, im, tright);
end

fprintf('Done!\n');