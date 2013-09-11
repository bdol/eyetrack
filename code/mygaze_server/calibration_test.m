clear;
load xdata.txt; load ydata.txt;
numCalibPoints = size(xdata, 2);
numRecPoints = size(xdata, 1)-1;

% Get x calib parameters
X = []; Y = [];
for i=1:numCalibPoints
    for j=2:numRecPoints+1
        X = [X; xdata(j, i)];
        Y = [Y; xdata(1, i)];
    end
end
Sx = inv(X'*X)*X'*Y;

% Get y calib parameters
X = []; Y = [];
for i=1:numCalibPoints
    for j=2:numRecPoints+1
        X = [X; ydata(j, i)];
        Y = [Y; ydata(1, i)];
    end
end
Sy = inv(X'*X)*X'*Y;

close all;
for i=1:numCalibPoints
    plot(xdata(1, i), 900-ydata(1, i), 'rx', 'MarkerSize', 10); hold on;
end
for i=1:numCalibPoints
    for j=2:numRecPoints+1
        plot(xdata(j, i), 900-ydata(j, i), 'bx');
        plot(xdata(j, i)*Sx(1), 900-ydata(j, i)*Sy(1), 'gx');
    end
end

axis([-100 1400 -100 900])

%% 2D
X = []; Y = [];
for i=1:numCalibPoints
    for j=2:numRecPoints+1
        X = [X; xdata(j, i) ydata(j, i), 1];
        Y = [Y; xdata(1, i) ydata(1, i)];
    end
end
S = inv(X'*X)*X'*Y;
X_calib = X*S;

close all;
for i=1:numCalibPoints
    plot(xdata(1, i), 900-ydata(1, i), 'rx', 'MarkerSize', 10); hold on;
end
for i=1:size(X_calib, 1)
    plot(X_calib(i, 1), 900-X_calib(i, 2), 'gx');
end
for i=1:numCalibPoints
    for j=2:numRecPoints+1
        plot(xdata(j, i), 900-ydata(j, i), 'bx');
    end
end

sum(sqrt(sum((X*S - Y).^2, 2)))/size(X, 1)

axis([-100 1400 -100 900])