%% Load data
dataPath = '~/code/eyetrack_data/cropped_eyes/';
[X_left Y_left X_right Y_right] = ...
    load_cropped_eyes_intensity(dataPath);