function generate_file_list(input_dir, file_ext, output_filename)
% generate a list of filenames in input_dir with extension given by
% file_ext. The list is written to a file given by output_filename

% input_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/jpg_data/';
% file_ext = 'jpg';
% output_filename = 'image_file_list.txt';

D = rdir([input_dir sprintf('**/*.%s',file_ext)]);
output_file = fopen(sprintf('%s/%s',input_dir,output_filename),'w');
if(output_file~=-1)
    for i = 1:length(D)
        fprintf(output_file,'%s\n',D(i).name);
    end
    fclose(output_file);
end