function rot_matrix = euler_to_rotation_matrix(theta_x, theta_y, theta_z)

A = cos(theta_x); B = sin(theta_x); CC = cos(theta_y);
D = sin(theta_y); E = cos(theta_z); F = sin(theta_z);
AD = A * -D; BD = B * -D;
rot_matrix = [CC*E, -CC*F, D;
    -BD * E + A * F, BD * F + A * E, -B * CC;
    AD * E + B * F, -AD * F + B * E, A * CC];