clear;
corresp = importdata('fileCorresp.txt');
%%
w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;

outDir = 'cropped_eyes_transformed';
canon_corresp = gen_canon_corresp_points(w, h, 20, 10);
close all; figure;
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

    % Calculate raw correspondences relative to the eye centroids
    centroid_right = calculate_eye_centroid(corr(r_idx, :));
    centroid_left = calculate_eye_centroid(corr(l_idx, :));    
    corr_left = bsxfun(@minus, corr(l_idx, :), centroid_left);
    
    corr_right = bsxfun(@minus, corr(r_idx, :), centroid_right);
    
    % Calculate the homography
    H_left = findHomography(canon_corresp, corr_left);
    H_right = findHomography(canon_corresp, corr_right);
    
    cl = corr(l_idx, :);
    colors = {'bx', 'kx', 'gx', 'rx', 'mx', 'yx'};
    for j=1:size(corr(r_idx, :))
        p = cl(j, :)-centroid_left;
        p = inv(H_left)*[p 1]';
        p = floor(p./p(3));
        plot(p(1)+w/2, p(2)+h/2, colors{j}); hold on;
    end
    i
    
    % DEBUG
%     if i>750
%         imorig = flipdim(imread(imPath), 2);
%         cl = corr(l_idx, :);
%         cr = corr(r_idx, :);
%         [crop_xl crop_yl] = crop_eye(cl, w, h);
%         [crop_xr crop_yr] = crop_eye(cr, w, h);
%         
%         close all;
%     
%         % Show left transform
%         figure;
%         subplot(2, 2, 1);
%         imshow(imorig(crop_yl:crop_yl+h, crop_xl:crop_xl+w, :));  hold on;
%         for j=1:6
%             plot(cl(j, 1)-crop_xl, cl(j, 2)-crop_yl, 'yx'); hold on;
%         end
%         hold off;
%         T = transformEye(w, h, centroid_left, imorig, H_left);
%         subplot(2, 2, 2);
%         imshow(T/255); hold on;
%         for j=1:6
%             p = canon_corresp(j, :);
%             p = p+centroid_left-[crop_xl crop_yl];
%             plot(p(1), p(2), 'mo', 'MarkerSize', 10); hold on;
%         end
%         for j=1:6
%             p = cl(j, :)-centroid_left;
%             p = inv(H_left)*[p 1]';
%             p = floor(p./p(3));
%             plot(p(1)+w/2, p(2)+h/2, 'yx'); hold on;
%         end
%         hold off;
%         
%         % Show right transform
%         subplot(2, 2, 3);
%         imshow(imorig(crop_yr:crop_yr+h, crop_xr:crop_xr+w, :));  hold on;
%         for j=1:6
%             plot(cr(j, 1)-crop_xr, cr(j, 2)-crop_yr, 'yx'); hold on;
%         end
%         hold off;
%         T = transformEye(w, h, centroid_right, imorig, H_right);
%         subplot(2, 2, 4);
%         imshow(T/255); hold on;
%         for j=1:6
%             p = canon_corresp(j, :);
%             p = p+centroid_right-[crop_xr crop_yr];
%             plot(p(1), p(2), 'mo', 'MarkerSize', 10); hold on;
%         end
%         for j=1:6
%             p = cr(j, :)-centroid_right;
%             p = inv(H_right)*[p 1]';
%             p = floor(p./p(3));
%             plot(p(1)+w/2, p(2)+h/2, 'yx'); hold on;
%         end
%         hold off;
%         keyboard;
%     end
    
end
axis([0 w 0 h]);