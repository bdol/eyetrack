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
xval = xval_setup(N, N_folds, subjectwise_split, frames_per_subject);
save('xval.mat','xval');

%% PREPARE TRAINING DATA FILE AND TESTING DATA FILE
for board_num = 1:tot_board_nums
    for fold = 1:N_folds
        % TRAINING
        arr = [l_ims(xval(fold).train_indices) r_ims(xval(fold).train_indices)];
        pos_ind = find([arr.board_num]==board_num);
        neg_ind = find([arr.board_num]~=board_num);
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(pos_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('train_positives/pos_%d_%d.dat',board_num,fold),b,'newline','unix','delimiter','');
        a = arrayfun(@(ims) sprintf('%s',ims.name), arr(neg_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('train_negatives/neg_%d_%d.dat',board_num,fold),b,'newline','unix','delimiter','');
        
        % TESTING
        arr = [l_ims(xval(fold).test_indices) r_ims(xval(fold).test_indices)];
        pos_ind = find([arr.board_num]==1);
        neg_ind = find([arr.board_num]~=1);
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(pos_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('test_positives/test_info_%d_%d.dat',board_num,fold),b,'newline','unix','delimiter','');
        a = arrayfun(@(ims) sprintf('%s 1 0 0 100 50',ims.name), arr(neg_ind), 'UniformOutput',false);
        xchar = cellfun(@(str) sprintf('%s',str), a,'UniformOutput',false);
        b = strvcat(xchar{:});
        dlmwrite(sprintf('test_negatives/test_info_%d_%d.dat',board_num,fold),b,'newline','unix','delimiter','');
    end
end

%% RUN commands in commands.txt
% ./train_haar_cascades.pl

%% CHECK PERFORMANCE
% cp test_positives/test_info_1_2.dat test_info.dat; /home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_performance -data haarcascade_1_2.xml -info test_info.dat
% cp test_negatives/test_info_1_2.dat test_info.dat; /home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_performance -data haarcascade_1_2.xml -info test_info.dat
