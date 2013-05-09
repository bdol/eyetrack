clear;
corresp = importdata('~/code/eyetrack/util/crop_eyes/fileCorresp.txt');
%%
w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;
outDir = 'cropped_eyes';

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
    
    im = flipdim(imread(imPath), 2);
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

    eye_r = crop_eye(im, corr(r_idx, :), w, h);
    eye_l = crop_eye(im, corr(l_idx, :), w, h);
    
    imwrite(eye_l, [outPath imName '_left.png'], 'png');
    imwrite(eye_r, [outPath imName '_right.png'], 'png');
end