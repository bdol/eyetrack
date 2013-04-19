clear;
corresp = importdata('fileCorresp.txt');
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
    
    % TODO: do this right...
    posLabel = imPath(42);
    imName = outPath(43:end);
    imName(end-3:end) = '';
    outPath(42:end) = '';
    %
    
    outPath = [outPath '/' posLabel '/'];
    
    if ~exist(outPath, 'dir')
        mkdir(outPath);
    end

    eye_r = crop_eye(im, corr(r_idx, :), w, h);
    eye_l = crop_eye(im, corr(l_idx, :), w, h);
    
    imwrite(eye_l, [outPath imName '_left.png'], 'png');
    imwrite(eye_r, [outPath imName '_right.png'], 'png');
end