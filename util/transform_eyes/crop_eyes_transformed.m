clear;
corresp = importdata('~/code/eyetrack/util/crop_eyes/fileCorresp.txt');
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
    
    % Calculate the homography
    H_left = findHomography(canon_corresp, corr_left);
    H_right = findHomography(canon_corresp, corr_right);
    
    crop_left = transformEye(w, h, centroid_left, im, H_left);
    crop_right = transformEye(w, h, centroid_right, im, H_right);
    imwrite(crop_left/255, [outPath imName '_left.png'], 'png');
    imwrite(crop_right/255, [outPath imName '_right.png'], 'png');
end
axis([0 w 0 h]);