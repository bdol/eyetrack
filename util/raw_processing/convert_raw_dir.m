raw_dir = '~/code/eyetrack_data/raw_data';
out_dir = '~/code/eyetrack_data/png_data';
dir_list = dir(raw_dir);
dir_idx = [dir_list(:).isdir];
dirs = {dir_list(dir_idx).name}';
dirs(ismember(dirs,{'.', '..'})) = [];

for d = 1:numel(dirs)
    im_dir = [raw_dir '/' dirs{d}];
    images = dir([im_dir '/*.raw']);
    
    num_out_dir = [out_dir '/' dirs{d}];
    if ~exist(num_out_dir, 'dir')
        mkdir(num_out_dir);
    end
    
    if exist([num_out_dir '/IM_9_3.png'], 'file') > 0
        fprintf('Files in %s already exist, skipping.\n', im_dir);
    else
        fprintf('Processing images in %s ...\n', im_dir);
        for i=1:numel(images)

            I = convert_image([im_dir '/' images(i).name], 1);
            [~, im_name] = fileparts(images(i).name);

            imwrite(I, [num_out_dir '/' im_name '.png'], 'png');
        end
    end
end

fprintf('Done!\n');