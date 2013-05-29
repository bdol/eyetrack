function [P P_norm] = get_positions()
% Returns a 9x2 vector, with each row k indicating the [x, y] position of
% class k in inches (from the top-left corner of the board). Also returns
% P_norm which treats the top-left corner of the board as [0 0] and the
% bottom-right corner as [1 1].

P = [6.5 5;
     33 5;
     33 27;
     6.5 27;
     20.5 16;
     13 11;
     27 11;
     27 22;
     13 22];


P_norm = bsxfun(@rdivide, P, [40 32]);