clear;
corresp = importdata('fileCorresp.txt');

%% Set up poses
posesMap = containers.Map;

fid = fopen('poses_dataset.txt');
tline = fgets(fid);
while ischar(tline);
    [fname pose] = strtok(tline, ' ');
    posesMap(fname) = str2num(pose(2:end));
    
    tline = fgets(fid);
end
fclose(fid);


%%
w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;
outDir = 'cropped_eyes_lrc_with_pose';
for i=1:numel(corresp)
    line = corresp{i};
    if line(1)=='!' || line(1)=='~'
        continue
    end
    
    [imPath corrPath] = strtok(line, ' ');
    corrPath = corrPath(2:end);
    try
        corr = importdata(corrPath);
    catch
        fprintf('Error: no corresp. exists for %s\n', imPath);
        continue;
    end
    
    im = flipdim(imread(imPath), 2);
    
    outPath = strrep(imPath, 'png_data', outDir);
    imNameStartPos = regexp(outPath, 'IM_');
    imName = outPath(imNameStartPos:imNameStartPos+5);
    posLabel = imName(4);
    
    subjDirStartPos = regexp(outPath, '\d\d\d\d');
    subjName = outPath(subjDirStartPos:subjDirStartPos+7);
    
    outPath = outPath(1:subjDirStartPos-2);
    % NOTE!!!: L/R is flipped because we mirrored the image
    
    if ~isKey(posesMap, imPath)
        continue;
    end
    
    pose = posesMap(imPath);
    switch pose
        case 0
            outPath = [outPath '/right'];
        case 1
            outPath = [outPath '/left'];
        case 2
            outPath = [outPath '/center'];
        otherwise
    end
    outPath = [outPath '/' subjName '/' posLabel '/'];
    
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
    
    eye_r = crop_eye(im, corr(r_idx, :), w, h);
    eye_l = crop_eye(im, corr(l_idx, :), w, h);
    
    if (isempty(eye_r) || isempty(eye_l))
        fprintf('Error cropping eyes.\n');
    else
        imwrite(eye_l, [outPath imName '_left.png'], 'png');
        imwrite(eye_r, [outPath imName '_right.png'], 'png');
    end
end