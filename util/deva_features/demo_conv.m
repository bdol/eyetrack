img = imread('trees.jpg');

hogparam.interval = 10;
hogparam.maxsize = [5 5 32];
hogparam.sbin = 8;

% 17 random 5x5 filters
nfilts = 17;
for i=1:nfilts
    filters{i} = randn(hogparam.maxsize);
end

%% full hog pyramid generation
tic
pyra = featpyramid(img,hogparam);
toc

%% display 
figure(1)
imagesc(img), axis image
figure(2)
while 1
    for i=1:length(pyra.feat)
        HOGpicture(pyra.feat{i})
        drawnow
    end
end
%% convolve all 17 filters at all scales
tic
heatmaps = {};
for k=1:length(pyra.feat)
    % do all filters on this level using one fconv call..
    % there is a parallel and sequential version, look inside fconv.m
    responsek = fconv(pyra.feat{k},filters,1,nfilts);
    heatmaps{k} = cat(3,responsek{:});
end
toc

%%
% now, let's say you want to convert a particular point in a heatmap with
% it's point in the original pixel space. use this function!

%random pyramid level:
level = 9;
inds = find(heatmaps{level} > prctile(heatmaps{level}(:),99));
[y,x,z] = ind2sub(size(heatmaps{level}),inds);
heatmap_pts = [x(:)';y(:)'];

[img_pts,filter_boxes_in_img_coordinates] = heatmap2pixels(heatmap_pts,pyra.scale(level),pyra.padx,pyra.pady,hogparam.maxsize);

