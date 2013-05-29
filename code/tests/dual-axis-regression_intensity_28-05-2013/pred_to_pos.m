function P = pred_to_pos(Apos, Bpos, Ypos, Y)
% Computes a position on the board given a vector of locations on both
% axes.

P = zeros(size(Apos, 1), 1);

Adir = [33 27]-[6.5 5];
Adir = Adir./norm(Adir);

Bdir = [6.5 27]-[33 5];
Bdir = Bdir./norm(Bdir);

P_A = bsxfun(@times, Adir, Apos);
P_B = bsxfun(@times, Bdir, Bpos);

P = bsxfun(@plus, P_A+P_B, [20.5 16]);


end