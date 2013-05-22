function convert_raw_data_jpg(input_dir,output_dir)
% Converts raw rgb images in input_dir to jpg images and saves them in
% output_dir

% input_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/raw_data/';
% output_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/jpg_data/';

addpath(genpath('../../MyNiViewer/Matlab/'));
D = rdir([input_dir '**/*.raw']);

for i = 1:length(D)
    num = regexp(D(i).name,'.*IM_(\d)_(\d).*', 'tokens');
    subject_num =  regexp(D(i).name, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
    if(~isempty(num) & ~isempty(subject_num))
       temp = num{1};
       cur_board_num = str2num(temp{1});
       cur_frame_num = str2num(temp{2});
       if(cur_frame_num>1)
            rgb_path = regexp(D(i).name,'^(.*\/)', 'tokens');
            rgb = display_images(cur_board_num,cur_frame_num,rgb_path{1}{1});
            mkdir(sprintf('%s/%s',output_dir,subject_num{1}{1}));
            image_filename = sprintf('%s/%s/IM_%d_%d.jpg',output_dir,subject_num{1}{1}, cur_board_num, cur_frame_num);
            imwrite(rgb, image_filename, 'jpg');
       end
    end
end