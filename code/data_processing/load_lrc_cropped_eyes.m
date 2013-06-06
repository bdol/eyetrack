function [left_eye_dataset right_eye_dataset] = load_lrc_cropped_eyes(root_path, varargin)
% Loads the dataset of cropped eyes from root_path into three sets of
% 'looking left', 'looking right' and 'looking at the center'. Looking left
% consists of images where subjects looking at board #1. Looking right
% consists of images in 'Looking left', but mirrored about the vertical
% axis. Looking at the center consists of images where subjects looking at
% board #2
% Usages:
% To load the corrected dataset use the 1st one shown below:
%  [l r c] = load_lrc_cropped_eyes(root_path);
% To make changes to the dataset and load selectively after making those 
% changes, use the ones shown below:
%  [l r c] = load_lrc_cropped_eyes(root_path, 'IdentifyBadImages',1);
%  [l r c] = load_lrc_cropped_eyes(root_path, 'IdentifyBadImages',1, 'CenterBadImagesFile','faulty_1.txt');
%  [l r c] = load_lrc_cropped_eyes(root_path, 'IdentifyBadImages',1, 'CenterBadImagesFile','center_bad_ims.txt', 'LRBadImagesFile', 'lr_bad_ims.txt');

identify_bad_images = 0;
center_bad_ims_filename = 'center_bad_ims.txt';
lr_bad_ims_filename = 'lr_bad_ims.txt';
for i=1:2:nargin-1
    if(strcmp(varargin{i},'IdentifyBadImages'))
        identify_bad_images = varargin{i+1};
    elseif(strcmp(varargin{i},'CenterBadImagesFile'))
        center_bad_ims_filename = varargin{i+1};
    elseif(strcmp(varargin{i},'RightBadImagesFile'))
        lr_bad_ims_filename = varargin{i+1};
    elseif(strcmp(varargin{i},'LeftBadImagesFile'))
        lr_bad_ims_filename = varargin{i+1};
    elseif(strcmp(varargin{i},'LRBadImagesFile'))
        lr_bad_ims_filename = varargin{i+1};
    end
end

center_bad_ims = [];
file = fopen(center_bad_ims_filename,'r');
if(file~=-1)
    data = textscan(file,'%s %s','HeaderLines',0,'Delimiter',' ','CollectOutput',1);
    center_bad_ims = data{1};
    fclose(file);
end
lr_bad_ims = [];
file = fopen(lr_bad_ims_filename,'r');
if(file~=-1)
    data = textscan(file,'%s %s','HeaderLines',0,'Delimiter',' ','CollectOutput',1);
    lr_bad_ims = data{1};
    fclose(file);
end
D = rdir([root_path '**/*.png']);

left_eye_dataset = struct('name', {}, 'label', {}, 'img',{}, 'subject_index', {});
right_eye_dataset = struct('name', {}, 'label', {}, 'img',{}, 'subject_index', {});
left_count = 1;
right_count = 1;
subjects_so_far = [];

for i = 1:length(D)
   num = regexp(D(i).name,'.*_(\d)_(\d)_.*', 'tokens');
   if(~isempty(num))
       temp = num{1};
       cur_board_num = str2num(temp{1});
       cur_frame_num = str2num(temp{2});
       temp =  regexp(D(i).name, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
       subject_num = temp{1}{1};
       temp = regexp(D(i).name, '.*(IM_\d_\d.*)', 'tokens');
       image_num = temp{1}{1};
       % if this subject has been seen before, subject count
       % remains unchanged
       subject_num_int = str2num(subject_num(1:4));
       subject_index = find(subjects_so_far == subject_num_int);
       if(isempty(subject_index))
            subjects_so_far = [subjects_so_far; subject_num_int];
            subject_index = size(subjects_so_far,1);
       end
       if(cur_board_num==1)
           % check to see if this image is on the left-right bad images list
           is_bad_image = ismember(lr_bad_ims,{subject_num image_num});
           if(~any(is_bad_image(:,1)&is_bad_image(:,2)))
               left_eye_image = regexp(D(i).name, '.*left.*');
               im = imread(D(i).name);
               im = double(im);
               im = im./max(im(:));
               % Label = 1 when subject is looking at left corner i.e.
               % board number 1
               if(~isempty(left_eye_image)) % image of the subject's left eye
                   left_eye_dataset(left_count).name = D(i).name;
                   left_eye_dataset(left_count).img = im;
                   left_eye_dataset(left_count).label = 1;
                   left_eye_dataset(left_count).subject_index = subject_index;
                   left_count = left_count + 1;
               else
                   right_eye_dataset(right_count).name = D(i).name;
                   right_eye_dataset(right_count).img = im;
                   right_eye_dataset(right_count).label = 1;
                   right_eye_dataset(right_count).subject_index = subject_index;
                   right_count = right_count + 1;
               end
               % Label = 2 with label=1 images mirrored about vertical axis
               % mirror the image and copy it over
               im_mirror = zeros(size(im));
               im_mirror(:,:,1) = im(:,end:-1:1,1);
               im_mirror(:,:,2) = im(:,end:-1:1,2);
               im_mirror(:,:,3) = im(:,end:-1:1,3);
               if(~isempty(left_eye_image)) % image of the subject's left eye
                   left_eye_dataset(left_count).name = D(i).name;
                   left_eye_dataset(left_count).img = im_mirror;
                   left_eye_dataset(left_count).label = 2;
                   left_eye_dataset(left_count).subject_index = subject_index;
                   left_count = left_count + 1;
               else
                   right_eye_dataset(right_count).name = D(i).name;
                   right_eye_dataset(right_count).img = im_mirror;
                   right_eye_dataset(right_count).label = 2;
                   right_eye_dataset(right_count).subject_index = subject_index;
                   right_count = right_count + 1;
               end
           end
       elseif(cur_board_num==2)
           % check to see if this image is on the bad images list
           is_bad_image = ismember(center_bad_ims,{subject_num image_num});
           if(~any(is_bad_image(:,1)&is_bad_image(:,2)))
               left_eye_image = regexp(D(i).name, '.*left.*');
               im = imread(D(i).name);
               im = double(im);
               im = im./max(im(:));
               % Label = 3 when subject is looking straight ahead i.e.
               % board number 2
               if(~isempty(left_eye_image)) % image of the subject's left eye
                   left_eye_dataset(left_count).name = D(i).name;
                   left_eye_dataset(left_count).img = im;
                   left_eye_dataset(left_count).subject_index = subject_index;
                   left_eye_dataset(left_count).label = 3;
                   left_count = left_count + 1;
               else
                   right_eye_dataset(right_count).name = D(i).name;
                   right_eye_dataset(right_count).img = im;
                   right_eye_dataset(right_count).label = 3;
                   right_eye_dataset(right_count).subject_index = subject_index;
                   right_count = right_count + 1;
               end
           end
       end
   end
end

%% DISCARD INCORRECT EYE CROPS
if(identify_bad_images)
    output_file = fopen(center_bad_ims_filename,'a'); % write the bad images to file
    indices_left = find([left_eye_dataset(:).label]==3);
    indices_right = find([right_eye_dataset(:).label]==3);
    center_images = [left_eye_dataset(indices_left) right_eye_dataset(indices_right)];
    fprintf('Center images - irises should be in the center of the eyes\n');
    for i = 1:length(center_images)
        imshow(center_images(i).img);
        center_images(i).name
        k=waitforbuttonpress;
        if strcmp(get(gcf,'CurrentCharacter'),'1'); % Enter key to indicate a bad image
            fprintf('Bad image\n');
            subject_num =  regexp(center_images(i).name, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
            image_num = regexp(center_images(i).name, '.*(IM_\d_\d.*)', 'tokens');
            fprintf(output_file,'%s %s\n', subject_num{1}{1}, image_num{1}{1});
        else
            fprintf('fine\n');
        end
    end
    fclose(output_file);
    
    % Label = 1 and 2 will have the same incorrect images since label=2
    % images are derived from label=1 images
    output_file = fopen(lr_bad_ims_filename,'a'); % write the bad images to file
    indices_left = find([left_eye_dataset(:).label]==2);
    indices_right = find([right_eye_dataset(:).label]==2);
    right_images = [left_eye_dataset(indices_left) right_eye_dataset(indices_right)];
    fprintf('Right images - irises should be in the right corner of the eyes\n');
    for i = 1:length(right_images)
        imshow(right_images(i).img);
        right_images(i).name
        k=waitforbuttonpress;
        if strcmp(get(gcf,'CurrentCharacter'),'1'); % Enter key to indicate a bad image
            fprintf('Bad image\n');
            subject_num =  regexp(right_images(i).name, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
            image_num = regexp(right_images(i).name, '.*(IM_\d_\d.*)', 'tokens');
            fprintf(output_file,'%s %s\n', subject_num{1}{1}, image_num{1}{1});
        end
    end
    fclose(output_file);
    
end