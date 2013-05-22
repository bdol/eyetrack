%% ADD PATHS
clear
clc
addpath(genpath('../../../../eyetrack/'));
subj_names = {'../../../all_images/'};
addpath(genpath('../../../third_party_libs/violajones/'));
% subj_names = {'../../../all_images/cropped_eyes_transformed/1027.2.E/'};

%% ORGANISE DATA
tot_board_nums = 9;
N_folds = 3;

[l_ims r_ims] = load_cropped_eye_intensity_linux(subj_names{1});
N = length(l_ims);
subjectwise_split = 1;
frames_per_subject = tot_board_nums * 2;
percent = 85;
% xval = xval_setup(N, N_folds, subjectwise_split, frames_per_subject);
[train_ind test_ind] = train_test_setup(N, percent, subjectwise_split, frames_per_subject);
% save('xval.mat','xval');

%% PREPARE LEFT EYE TRAINING DATA FILE AND TESTING DATA FILE
for board_num = 1:tot_board_nums
    % TRAINING
        arr = [l_ims(train_ind)];
        pos_ind = find([arr.board_num]==board_num);
        neg_ind = find([arr.board_num]~=board_num);
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(pos_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('train_left_positives/pos_%d.dat',board_num),b,'newline','unix','delimiter','');
        a = arrayfun(@(ims) sprintf('%s',ims.name), arr(neg_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('train_left_negatives/neg_%d.dat',board_num),b,'newline','unix','delimiter','');
        
        % TESTING
        arr = [l_ims(test_ind)];
        pos_ind = find([arr.board_num]==1);
        neg_ind = find([arr.board_num]~=1);
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(pos_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('test_left_positives/test_info_%d.dat',board_num),b,'newline','unix','delimiter','');
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(neg_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('test_left_negatives/test_info_%d.dat',board_num),b,'newline','unix','delimiter','');
end

%% PREPARE RIGHT EYE TRAINING DATA FILE AND TESTING DATA FILE
for board_num = 1:tot_board_nums
    % TRAINING
        arr = [r_ims(train_ind)];
        pos_ind = find([arr.board_num]==board_num);
        neg_ind = find([arr.board_num]~=board_num);
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(pos_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('train_right_positives/pos_%d.dat',board_num),b,'newline','unix','delimiter','');
        a = arrayfun(@(ims) sprintf('%s',ims.name), arr(neg_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('train_right_negatives/neg_%d.dat',board_num),b,'newline','unix','delimiter','');
        
        % TESTING
        arr = [r_ims(test_ind)];
        pos_ind = find([arr.board_num]==1);
        neg_ind = find([arr.board_num]~=1);
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(pos_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('test_right_positives/test_info_%d.dat',board_num),b,'newline','unix','delimiter','');
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(neg_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('test_right_negatives/test_info_%d.dat',board_num),b,'newline','unix','delimiter','');
end

%% RUN commands in commands.txt
% ./train_haar_cascades.pl

%% CHECK PERFORMANCE
% cp test_positives/test_info_1_2.dat test_info.dat; /home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_performance -data haarcascade_1_2.xml -info test_info.dat
% cp test_negatives/test_info_1_2.dat test_info.dat; /home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_performance -data haarcascade_1_2.xml -info test_info.dat
