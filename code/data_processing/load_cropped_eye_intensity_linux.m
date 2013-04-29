function [left_images right_images] = load_cropped_eye_intensity_linux(root)

D = rdir([root '**/*.png']);
left_images = struct('name', {}, 'img',{}, 'board_num', {}, 'frame_num', {});
right_images = struct('name', {}, 'img',{}, 'board_num', {}, 'frame_num', {});
left_count = 1;
right_count = 1;

for i = 1:length(D)
   im = imread(D(i).name);
   im = double(im);
   im = im./max(im(:));
   num = regexp(D(i).name,'.*_(\d)_(\d)_.*', 'tokens');
   if(~isempty(num))
       temp = num{1};
       cur_board_num = str2num(temp{1});
       cur_frame_num = str2num(temp{2});
       if(cur_frame_num>1)

           left = regexp(D(i).name, '.*left.*');
           if(~isempty(left))
               left_images(left_count).name = D(i).name;
               left_images(left_count).board_num = cur_board_num;
               left_images(left_count).frame_num = cur_frame_num;
               left_images(left_count).img = im;
               left_count = left_count + 1;
           else
               right_images(right_count).name = D(i).name;
               right_images(right_count).board_num = cur_board_num;
               right_images(right_count).frame_num = cur_frame_num;
               right_images(right_count).img = im;
               right_count = right_count + 1;
           end
       end
   end
end