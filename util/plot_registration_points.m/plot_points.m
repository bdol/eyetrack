clear;
corresp = importdata('~/code/eyetrack/util/crop_eyes/fileCorresp.txt');
%%
close all;
figure;

w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;

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
    
    [cxl, cyl] = crop_eye(corr(r_idx, :), w, h);
    [cxr, cyr] = crop_eye(corr(l_idx, :), w, h);
    
    c = corr(r_idx, :);
    colors = {'bx', 'kx', 'gx', 'rx', 'mx', 'yx'};
    for j=1:size(corr(r_idx, :))
        plot(c(j, 1)-cxr, c(j, 2)-cyr, colors{j}); hold on;
    end
    
    
end