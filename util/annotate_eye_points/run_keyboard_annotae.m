clear;
dataLocs = importdata('~/code/eyetrack/util/crop_eyes/vidDataLocList.txt');
addpath('../crop_eyes/');

%%
w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;

outName = '~/code/eyetrack/util/crop_eyes/vidDataLocListCorrected.txt';
if ~exist(outName, 'file');
    fid = fopen(outName, 'w');
    fclose(fid);
end

for i=1:numel(dataLocs)
    line = dataLocs{i};
    [imPath dataPath] = strtok(line, ' ');
    
    % Check to see if we've already done this file
    if find_in_file(outName, imPath)
        continue;
    end
    fprintf('Processing %s, %d of %d\n', imPath, i, numel(dataLocs));
    
    fid = fopen(outName, 'a+');
    
    % Remove space from front
    dataPath = dataPath(2:end);
    
    try
        data = importdata(dataPath);
    catch e
        fprintf('Error: no data file exists for %s\n', imPath);
        continue;
    end
    
    im = flipdim(imread(imPath), 2);
    
    [l_corr r_corr] = keyboard_annotate(im, data(l_idx, :), data(r_idx, :), w, h);
    
    fprintf(fid, '%s', imPath);
    l_data = l_corr(:);
    r_data = r_corr(:);
    for j=1:numel(l_data)
        fprintf(fid, ' %d', l_data(j));
    end
    for j=1:numel(r_data)
        fprintf(fid, ' %d', r_data(j));
    end
    fprintf(fid, '\n');    
    fclose(fid);
end