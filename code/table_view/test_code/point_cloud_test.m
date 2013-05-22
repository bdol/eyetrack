clear;
D = imread('~/Desktop/plane_test/depth_0.png');
D_m = raw_depth_to_meters2(D);
D_m(D_m==2047) = 0;

%%
[xx yy] = meshgrid(1:size(D, 2), 1:size(D, 1));
X = xx(:); Y = yy(:);
Z = D_m(:);

%%
% Depth intrinsics:
fx = 5.6009202708545865e+02;
fy = 5.5885814292051782e+02;
cx = 3.0015891816197120e+02;
cy = 2.5149932242225375e+02;
[Xw Yw Zw] = im_to_world(X, Y, Z, fx, fy, cx, cy);
% Remove bad depth points
Xw(Z==0) = [];
Yw(Z==0) = [];
Zw(Z==0) = [];
% Remove far depth points (more than 2m)
Xw(Zw>2) = [];
Yw(Zw>2) = [];
Zw(Zw>2) = [];
%scatter3(Xw(1:100:end), Yw(1:100:end), Zw(1:100:end))

%% LSE example
[n_est ro_est Xp Yp Zp] = LSE([Xw Yw Zw]);
hp = size(Xp, 1); wp = size(Xp, 2);
close all;
plot3(Xw(1:100:end), Yw(1:100:end), Zw(1:100:end),'ok'); hold on;
mesh(Xp,Yp,Zp);colormap([.8 .8 .8])
axis('off');

%% Now plot plane on image
Xp = Xp(:);
Yp = Yp(:);
Zp = Zp(:);
% Apply extrinsreics
R = [9.9993189761892909e-01, -3.2729355538435750e-03, 1.1202143414009318e-02;
     3.3304519065922894e-03, 9.9998134867689581e-01, -5.1196082305675792e-03;
     -1.1185178331413474e-02, 5.1565677729480267e-03, 9.9992414792047979e-01];
T = [2.8788567238524864e-02; 6.3401893265889063e-04; 1.3891577580578355e-03];
Pd = [Xp Yp Zp]';
Pd_r = inv(R)*Pd;
P_rgb = bsxfun(@minus, Pd_r, T);
Xp = P_rgb(1, :)';
Yp = P_rgb(2, :)';
Zp = P_rgb(3, :)';

% Calculate transform to (RGB) image plane
fx = 4.9726263121508453e+02;
fy = 4.9691535190126677e+02;
cx = 3.1785221776747596e+02;
cy = 2.7311575302513319e+02;
K = [fx 0 cx 0; 0 fy cy 0; 0 0 1 0];
P = [Xp Yp Zp ones(numel(Xp), 1)]';
pi = K*P;
pi = bsxfun(@rdivide, pi, pi(3, :));

% Convert these points back to a mesh format
Xpi = pi(1, :);
Ypi = pi(2, :);
Xpi = reshape(Xpi, hp, wp);
Ypi = reshape(Ypi, hp, wp);
Zpi = zeros(hp, wp);
for gx=1:wp
    if mod(gx, 2)==0
        clr = 0;
    else
        clr = 1;
    end
    for gy=1:hp
        Zpi(gy, gx) = clr;
        clr = 1-clr;
    end
end

im = imread('images/rgb_0.png');
close all; imshow(im); hold on;
h = pcolor(Xpi, Ypi, Zpi); colormap('gray'); caxis([0 1]);
alpha(h, 0.2);
hold on;

p1 = [0.6043265746400953; -0.1671251859661403; 1.072848029108164];
p1 = [R'*p1 - T; 1];
p1 = K*p1;
p1 = p1./p1(3)
plot(p1(1), p1(2), 'rx')

