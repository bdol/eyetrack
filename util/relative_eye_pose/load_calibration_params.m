function params = load_calibration_params

    %% RGB camera params
    params.cx_rgb=6.29640747e+002; params.cy_rgb=5.17733276e+002;
    params.fx_rgb=1.05771448e+003; params.fy_rgb=1.06197778e+003;

    %% Depth camera params
    params.cx_d=3.20674194e+002; params.cy_d=2.38202423e+002;
    params.fx_d=5.93567322e+002; params.fy_d=5.96097961e+002;

    %% Stereo calibration params
    % In mts
    params.T = [0.019985242312092553 -0.00074423738761617583 -0.010916736334336222];
    params.R = [ 9.9984628826577793e-01, -1.4779096108364480e-03, 1.7470421412464927e-02,
                1.2635359098409581e-03, 9.9992385683542895e-01,  1.2275341476520762e-02,
            -1.7487233004436643e-02, -1.2251380107679535e-02, 9.9977202419716948e-01 ];
