raw_dir = '~/Desktop/raw_data';
out_dir = '~/Desktop/png_data';
dir_list = dir(raw_dir);
dir_idx = [dir_list(:).isdir];
dirs = {dir_list(dir_idx).name}';
dirs(ismember(dirs,{'.', '..'})) = [];

for d = 1:numel(dirs)
    im_dir = [raw_dir '/' dirs{d}];
    images = dir([im_dir '/*.raw']);
    fprintf('Processing images in %s ...\n', im_dir);
    for i=1:numel(images)
        I = convert_image([im_dir '/' images(i).name]);
        [~, im_name] = fileparts(images(i).name);
        
        num_out_dir = [out_dir '/' dirs{d}];
        if ~exist(num_out_dir, 'dir')
            mkdir(num_out_dir);
        end
        imwrite(I, [num_out_dir '/' im_name '.png'], 'png');
    end
end

fprintf('Done!\n');