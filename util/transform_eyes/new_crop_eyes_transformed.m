clear;
fid = fopen('~/code/eyetrack/util/face_tracker/bin/new_eye_points.txt');

line = fgets(fid);
i = 1;
data = {};
while ischar(line)
    C = regexp(line, ' ', 'split');
    fname = C{1};
    fname = strrep(fname, '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/jpg_data/', ...
                    '/Users/bdol/Desktop/png_data/');
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

outDir = '/Users/bdol/Desktop/cropped_eyes_transformed_new/';
canon_corresp = gen_canon_corresp_points(w, h, 20, 10);
for i=1:numel(data)
    fname = data{i}.fname;
    corr_left = data{i}.corr_left;
    corr_right = data{i}.corr_right;
    subjnum = regexp(fname, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
    outPath = strcat(outDir, subjnum{1}, '/');
    outPath = outPath{1};
    image_num = regexp(fname, '.*(IM_\d_\d).*', 'tokens');
    inum = image_num{1}{1};
    classNum = inum(4);
    
    if ~exist([outPath '/' classNum '/'], 'dir')
        mkdir([outPath '/' classNum '/'])
    end

    im = flipdim(imread(fname), 2);

    % Calculate raw correspondences relative to the eye centroids
    centroid_right = calculate_eye_centroid(corr_right);
    centroid_left = calculate_eye_centroid(corr_left);    
    corr_left = bsxfun(@minus, corr_left, centroid_left);
    corr_right = bsxfun(@minus, corr_right, centroid_right);
    
    % Calculate the homography
%     H_left = findHomography(canon_corresp, corr_left);
%     H_right = findHomography(canon_corresp, corr_right);
    tleft = cp2tform(corr_left, canon_corresp, 'piecewise linear');
    tright = cp2tform(corr_right, canon_corresp, 'piecewise linear');

%     crop_left = transformEye(w, h, centroid_left, im, H_left);
%     crop_right = transformEye(w, h, centroid_right, im, H_right);
    crop_left = transformEyeIPT(w, h, centroid_left, im, tleft);
    crop_right = transformEyeIPT(w, h, centroid_right, im, tright);
    left_fname = strcat(outPath, classNum, '/', image_num{1}, '_left.png');
    right_fname = strcat(outPath, classNum, '/', image_num{1}, '_right.png');
    imwrite(crop_left/255, left_fname{1}, 'png');
    imwrite(crop_right/255, right_fname{1}, 'png');
end