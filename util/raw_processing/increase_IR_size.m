% Takes all 480x640 IR images and upscales them to 1024x1280
clear;
ir_dir = '~/Desktop/calibration3_png';
d = dir(ir_dir);
im_list = {d.name}';
im_list(ismember(im_list,{'.', '..'})) = [];

for i = 1:numel(im_list)
    im_full_name = [ir_dir '/' im_list{i}];
    im_name = im_list{i};
    if ~strcmp(im_name(1:2), 'IR')
        continue;
    end
    
    fprintf('Processing images in %s ...\n', im_full_name);
    
    I = imread(im_full_name);    
    I_up = imresize(I, [1024 1280]);
    
    imwrite(I_up, im_full_name, 'png');
end

fprintf('Done!\n');