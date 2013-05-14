function convert_png_data_jpg(root, output_dir, imagelist_filename)
% Converts png images in all subfolders of root into jpegs and writes the
% names of the jpg images to a file given by imagelist_filename
% root = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data/';
% output_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/jpg_data/';
% imagelist_filename = 'jpegs.txt';

D = rdir([root '**/*.png']);
output_file = fopen(sprintf('%s/%s',output_dir,imagelist_filename),'w');

for i = 1:length(D)
   im = imread(D(i).name);
   im = double(im);
   im = im./max(im(:));
   num = regexp(D(i).name,'.*IM_(\d)_(\d).*', 'tokens');
   subject_num =  regexp(D(i).name, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
   if(~isempty(num) & ~isempty(subject_num))
       temp = num{1};
       cur_board_num = str2num(temp{1});
       cur_frame_num = str2num(temp{2});
       if(cur_frame_num>1)

           im = imread(D(i).name);
           mkdir(sprintf('%s/%s',output_dir,subject_num{1}{1}));
           image_filename = sprintf('%s/%s/IM_%d_%d.jpg',output_dir,subject_num{1}{1}, cur_board_num, cur_frame_num);
           imwrite(im, image_filename, 'jpg');
           if(output_file~=-1)
                fprintf(output_file,'%s\n',image_filename);
           end
       end
   end
end
fclose(output_file);