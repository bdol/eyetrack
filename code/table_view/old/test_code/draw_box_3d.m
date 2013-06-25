function draw_box_3d(B, color)

p1 = B(1, :);
p2 = B(2, :);
p3 = B(3, :);
p4 = B(4, :);
p5 = B(5, :);
p6 = B(6, :);
p7 = B(7, :);
p8 = B(8, :);

% Bottom square
plot3([p1(1) p2(1)],[p1(2) p2(2)],[p1(3) p2(3)], color); hold on;
plot3([p2(1) p3(1)],[p2(2) p3(2)],[p2(3) p3(3)], color); hold on;
plot3([p3(1) p4(1)],[p3(2) p4(2)],[p3(3) p4(3)], color); hold on;
plot3([p4(1) p1(1)],[p4(2) p1(2)],[p4(3) p1(3)], color); hold on;
% Sides
plot3([p1(1) p5(1)],[p1(2) p5(2)],[p1(3) p5(3)], color); hold on;
plot3([p2(1) p6(1)],[p2(2) p6(2)],[p2(3) p6(3)], color); hold on;
plot3([p3(1) p7(1)],[p3(2) p7(2)],[p3(3) p7(3)], color); hold on;
plot3([p4(1) p8(1)],[p4(2) p8(2)],[p4(3) p8(3)], color); hold on;
% Top square
plot3([p6(1) p5(1)],[p6(2) p5(2)],[p6(3) p5(3)], color); hold on;
plot3([p7(1) p6(1)],[p7(2) p6(2)],[p7(3) p6(3)], color); hold on;
plot3([p8(1) p7(1)],[p8(2) p7(2)],[p8(3) p7(3)], color); hold on;
plot3([p5(1) p8(1)],[p5(2) p8(2)],[p5(3) p8(3)], color); hold on;

end