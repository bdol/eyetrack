clear;
corresp = importdata('~/code/eyetrack/util/crop_eyes/fileCorresp.txt');
%%
w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;

outDir = 'cropped_eyes_transformed_tps';
canon_corresp = gen_canon_corresp_points(w, h, 10, 10);
for i=1:numel(corresp)
    line = corresp{i};
    if line(1)=='!' || line(1)=='~'
        continue
    end
    
    [imPath corrPath] = strtok(line, ' ');
    if isempty(strfind(imPath, '.2.E'))
        continue;
    end
    % Remove space from front
    corrPath = corrPath(2:end);
    try
        corr = importdata(corrPath);
    catch
        fprintf('Error: no corresp. exists for %s\n', imPath);
        continue;
    end
    
    outPath = strrep(imPath, 'png_data', outDir);
    imNameStartPos = regexp(outPath, 'IM_');
    imName = outPath(imNameStartPos:imNameStartPos+5);
    posLabel = imName(4);
    outPath = outPath(1:imNameStartPos-2);    
    outPath = [outPath '/' posLabel '/'];
    if ~exist(outPath, 'dir')
        mkdir(outPath);
    else
        if exist([outPath imName '_left.png'], 'file') && ...
           exist([outPath imName '_right.png'], 'file')
            fprintf('Skipping %s.\n', [outPath imName '*.png']);
            continue;
        end
    end
    fprintf('Processing %s. File %d out of %d.\n', [outPath imName '*.png'], i, numel(corresp));
    im = flipdim(imread(imPath), 2);

    % Calculate raw correspondences relative to the eye centroids
    centroid_right = calculate_eye_centroid(corr(r_idx, :));
    centroid_left = calculate_eye_centroid(corr(l_idx, :));    
    corr_left = bsxfun(@minus, corr(l_idx, :), centroid_left);
    corr_right = bsxfun(@minus, corr(r_idx, :), centroid_right);
    
    st_l = tpaps(canon_corresp', corr_left', 1);
    im_warp_l = tps_warp(st_l, im, centroid_left, w, h);
    st = tpaps(canon_corresp', corr_right', 1);
    im_warp_r = tps_warp(st, im, centroid_right, w, h);
    imwrite(im_warp_l/255, [outPath imName '_left.png'], 'png');
    imwrite(im_warp_r/255, [outPath imName '_right.png'], 'png');

    
%     % DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     close all; figure;
%     subplot(2, 3, 1);
%     % Show left eye untransformed with correspondence
%     [cx cy] = crop_eye(corr(l_idx, :), w, h);
%     imshow(im(cy:cy+h-1, cx:cx+w-1, :)); hold on;
%     plot(corr_left(:, 1)+w/2, corr_left(:, 2)+h/2, 'mx');
%     
%     st = tpaps(canon_corresp', corr_left', 1);
%     subplot(2, 3, 2);
%     fnplt(st);
%     
%     im_warp_l = tps_warp(st, im, centroid_left, w, h);
%     subplot(2, 3, 3);
%     imshow(im_warp_l/255); hold on;
%     plot(canon_corresp(:, 1)+w/2, canon_corresp(:, 2)+h/2, 'go', 'MarkerSize', 10);
%     stinv = tpaps(corr_left', canon_corresp', 1);
%     pts = fnval(stinv, corr_left');
%     pts = pts';
%     plot(pts(:, 1)+w/2, pts(:, 2)+h/2, 'mx');
%     
%     % Show right eye untransformed with correspondence
%     subplot(2, 3, 4);
%     [cx cy] = crop_eye(corr(r_idx, :), w, h);
%     imshow(im(cy:cy+h-1, cx:cx+w-1, :)); hold on;
%     plot(corr_right(:, 1)+w/2, corr_right(:, 2)+h/2, 'mx');
%     
%     st = tpaps(canon_corresp', corr_right', 1);
%     subplot(2, 3, 5);
%     fnplt(st);
%     
%     im_warp_r = tps_warp(st, im, centroid_right, w, h);    
%     subplot(2, 3, 6); imshow(im_warp_r/255); hold on;
%     plot(canon_corresp(:, 1)+w/2, canon_corresp(:, 2)+h/2, 'go', 'MarkerSize', 10);
%     stinv = tpaps(corr_right', canon_corresp', 1);
%     pts = fnval(stinv, corr_right');
%     pts = pts';
%     plot(pts(:, 1)+w/2, pts(:, 2)+h/2, 'mx');
%     % DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end
