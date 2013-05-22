function [train_indices test_indices] = train_test_setup(N, train_perc, varargin)
% Returns a train_perc percentage indices that will be part of a training
% set and the remaining which will be part of the testing indices
% INPUTS: 
%       N: # of elements
%       train_perc: percentage of N to be used as training
%       subjectwise_split: (optional) 1 to split data that necessarily keeps all data
%           from a given subject within a fold instead of treating all of the
%           data as a single chunk
%       num_per_subj: number of frames captured for each subject
% OUTPUT:
%       train_indices = indices to train on
%       test_indices = indices to test on

if(nargin>2)&&(nargin==4)
    subjectwise_split = varargin{1};
    num_per_subj = varargin{2};
else
    subjectwise_split = 0;
end

xval = struct('train_indices', {}, 'test_indices', {});
    
if(~subjectwise_split)
    train_size = round((train_perc/100)*N);
    test_size = N - train_size;
    arr = [ones(train_size,1); zeros(test_size,1)];
    mixed_up_arr = arr(randperm(length(arr)));
    train_indices = find(mixed_up_arr);
    test_indices = find(~mixed_up_arr);
else
    M = floor(N./num_per_subj);
    new_N = M*num_per_subj;     % in case we dont have num_per_subj images for each subject
    train_size = round((train_perc/100)*M);
    test_size = M - train_size;
    arr = [ones(train_size,1); zeros(test_size,1)];
    mixed_up_arr = arr(randperm(length(arr)));
    mixed_up_arr = repmat(mixed_up_arr,1,num_per_subj);
    b = reshape(mixed_up_arr',new_N,1);
    train_indices = find(b);
    test_indices = find(~b);
end