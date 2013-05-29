from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
import numpy as np
import pylab

data = np.loadtxt('/Users/bdol/code/eyetrack/code/tests/dual-axis-regression_intensity_28-05-2013/axis_a_preds')
data_1 = data[np.nonzero(data[:, 1]==1), 0]
data_3 = data[np.nonzero(data[:, 1]==3), 0]
data_5 = data[np.nonzero(data[:, 1]==5), 0]
data_6 = data[np.nonzero(data[:, 1]==6), 0]
data_8 = data[np.nonzero(data[:, 1]==8), 0]

n_bins = 25;
hist_range = [-5, 40]

data_hist_1 = np.histogram(data_1, bins=n_bins, range=hist_range)
data_hist_3 = np.histogram(data_3, bins=n_bins, range=hist_range)
data_hist_5 = np.histogram(data_5, bins=n_bins, range=hist_range)
data_hist_6 = np.histogram(data_6, bins=n_bins, range=hist_range)
data_hist_8 = np.histogram(data_8, bins=n_bins, range=hist_range)

fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
c = ['r', 'g', 'b', 'y', 'c']

xs = data_hist_1[1][0:-1]

ax.bar(xs, data_hist_1[0], zs=0, zdir='y', color=c[0], alpha=0.8, width=xs[1]-xs[0])
ax.bar(xs, data_hist_6[0], zs=1, zdir='y', color=c[3], alpha=0.8, width=xs[1]-xs[0])
ax.bar(xs, data_hist_5[0], zs=2, zdir='y', color=c[2], alpha=0.8, width=xs[1]-xs[0])
ax.bar(xs, data_hist_8[0], zs=3, zdir='y', color=c[4], alpha=0.8, width=xs[1]-xs[0])
ax.bar(xs, data_hist_3[0], zs=4, zdir='y', color=c[1], alpha=0.8, width=xs[1]-xs[0])

ax.set_xlabel('position (inches)')
ax.set_ylabel('class')

ax.set_yticks([0, 1, 2, 3, 4])
ax.set_yticklabels(['1', '6', '5', '8', '3'])

plt.show()
