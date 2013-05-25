clear
% addpath(genpath('../../../../eyetrack/'));
% 
% %%
% 
% Options.Resize = false;
% Options.ScaleUpdate = 0.95;
% Options.Verbose = true;
% 
% img = rgb2gray(l_ims(3).img);
% IntegralImages= GetIntergralImages(img,Options);
% [Objects conf_intervals] = HaarCasadeObjectDetection(IntergralImages,HaarCasade,Options);
% ShowDetectionResult(img,Objects);
% imshow(l_ims(3).img)

%% SET VARIABLES
tot_board_nums = 9;
subj_names = {'../../../all_images/'};
crop_width = 100;
crop_height = 50;

% %% CONVERT ALL CASCADES TO MAT
% for board_num = 1:tot_board_nums
%     ConvertHaarcasadeXMLOpenCV(sprintf('haarcascade_left_%d.xml',board_num));
%     ConvertHaarcasadeXMLOpenCV(sprintf('haarcascade_right_%d.xml',board_num));
% end

%% SET OPTIONS
Options.Resize = false;             % dont resize the original image
Options.ScaleUpdate = 0.95;         % this gets multiplied by the scale for each iteration of detection
                            % initial scale value is image_size/cascade_window_size
Options.Verbose = false;
% first row - thresholds for left eye
% second row - thresholds for right eye
resp_threshold = [0.0036 0 0 0 0 0 0 0 0;
                1.8689e-04 0 0 0 0 0 0 0 0];
min_detection_scale = 0.65;


%% TEST

for board_num = 2:2
    fprintf('Testing board number %d\n',board_num);
    
    %% LEFT EYE
    % load haar cascade for this board number - left eye
    HaarCasade=GetHaarCasade(sprintf('haarcascade_left_%d.mat',board_num));
    % POSITIVE - LEFT eye
    testdata = importdata(sprintf('test_left_positives/test_info_2.dat',board_num));
    objects_detected_ind = cell(length(testdata.rowheaders),1);
%     max_conf_intervals = zeros(length(testdata.rowheaders),1);
    max_haar_responses_left_pos = zeros(length(testdata.rowheaders),1);
    simple_progress_bar(length(testdata.rowheaders));
    for i = 1:length(testdata.rowheaders)
       test_image = rgb2gray(imread(testdata.rowheaders{i}));
       IntegralImages= GetIntergralImages(test_image,Options);
       [Objects conf_intervals haar_resp] = HaarCasadeObjectDetection(IntegralImages,HaarCasade,Options);
       objects_detected_ind{i} = find(Objects(:,3)>crop_width*min_detection_scale);
       if(~isempty(objects_detected_ind{i}))
           max_haar_responses_left_pos(i) = max(haar_resp(objects_detected_ind{i}));
       end
       simple_progress_bar;
    end
    
    % NEGATIVE - LEFT eye
    testdata = importdata(sprintf('test_left_negatives/test_info_%d.dat',board_num));
    objects_detected_ind = cell(length(testdata.rowheaders),1);
    max_conf_intervals = zeros(length(testdata.rowheaders),1);
    max_haar_responses_left_neg = zeros(length(testdata.rowheaders),1);
    simple_progress_bar(length(testdata.rowheaders));
    for i = 1:length(testdata.rowheaders)
       test_image = rgb2gray(imread(testdata.rowheaders{i}));
       IntegralImages= GetIntergralImages(test_image,Options);
       [Objects conf_intervals haar_resp] = HaarCasadeObjectDetection(IntegralImages,HaarCasade,Options);
       objects_detected_ind{i} = find(Objects(:,3)>crop_width*min_detection_scale);
       if(~isempty(objects_detected_ind{i}))
%            max_conf_intervals(i) = max(conf_intervals(objects_detected_ind{i}));
           max_haar_responses_left_neg(i) = max(haar_resp(objects_detected_ind{i}));
       end
%        hist(max_haar_responses,100);
%        print('-djpeg',sprintf('histogram_left_neg_%d',board_num));
       simple_progress_bar;
    end
        
    %% RIGHT EYE
    % load haar cascade for this board number - right eye
    HaarCasade=GetHaarCasade(sprintf('haarcascade_right_%d.mat',board_num));
    % POSITIVE - RIGHT eye
    testdata = importdata(sprintf('test_right_positives/test_info_%d.dat',board_num));
    objects_detected_ind = cell(length(testdata.rowheaders),1);
    max_conf_intervals = zeros(length(testdata.rowheaders),1);
    max_haar_responses_right_pos = zeros(length(testdata.rowheaders),1);
    simple_progress_bar(length(testdata.rowheaders));
    for i = 1:length(testdata.rowheaders)
       test_image = rgb2gray(imread(testdata.rowheaders{i}));
       IntegralImages= GetIntergralImages(test_image,Options);
       [Objects conf_intervals] = HaarCasadeObjectDetection(IntegralImages,HaarCasade,Options);
       objects_detected_ind{i} = find(Objects(:,3)>crop_width*min_detection_scale);
       if(~isempty(objects_detected_ind{i}))
%            max_conf_intervals(i) = max(conf_intervals(objects_detected_ind{i}));
           max_haar_responses_right_pos(i) = max(haar_resp(objects_detected_ind{i}));
       end
%        hist(max_haar_responses,100);
%        print('-djpeg',sprintf('histogram_right_pos_%d',board_num));
       simple_progress_bar;
    end
   % NEGATIVE - RIGHT eye
    testdata = importdata(sprintf('test_right_negatives/test_info_%d.dat',board_num));
    objects_detected_ind = cell(length(testdata.rowheaders),1);
    max_conf_intervals = zeros(length(testdata.rowheaders),1);
    max_haar_responses_right_neg = zeros(length(testdata.rowheaders),1);
    simple_progress_bar(length(testdata.rowheaders));
    for i = 1:length(testdata.rowheaders)
       test_image = rgb2gray(imread(testdata.rowheaders{i}));
       IntegralImages= GetIntergralImages(test_image,Options);
       [Objects conf_intervals] = HaarCasadeObjectDetection(IntegralImages,HaarCasade,Options);
       objects_detected_ind{i} = find(Objects(:,3)>crop_width*min_detection_scale);
       if(~isempty(objects_detected_ind{i}))
%            max_conf_intervals(i) = max(conf_intervals(objects_detected_ind{i}));
           max_haar_responses_right_neg(i) = max(haar_resp(objects_detected_ind{i}));
       end
%        hist(max_haar_responses,100);
%        print('-djpeg',sprintf('histogram_right_neg_%d',board_num));
       simple_progress_bar;
    end
end

%%
mean(max_haar_responses_left_neg)+2*std(max_haar_responses_left_neg)
mean(max_haar_responses_left_pos)+2*std(max_haar_responses_left_pos)
mean(max_haar_responses_right_neg)+2*std(max_haar_responses_right_neg)
mean(max_haar_responses_right_pos)+2*std(max_haar_responses_right_pos)