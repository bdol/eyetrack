function draw_field_of_view(table_plane, head_center, field_of_view_directions, plot_point_type)
% table_plane - 3xn point cloud of points on table plane
% head_center - 3x1 vector 3d position of head center
% field_of_view_directions - 3x4 - 4 column vectors of fov directions

fov_intersection_k1 = zeros(3,4);
fov_intersection_k1(:,1) = vector_plane_intersection(table_plane, ...
    head_center(:), field_of_view_directions(:,1));
fov_intersection_k1(:,2) = vector_plane_intersection(table_plane, ...
    head_center(:), field_of_view_directions(:,2));
fov_intersection_k1(:,3) = vector_plane_intersection(table_plane, ...
    head_center(:), field_of_view_directions(:,3));
fov_intersection_k1(:,4) = vector_plane_intersection(table_plane, ...
    head_center(:), field_of_view_directions(:,4));
idx1 = (table_plane(1,:)>min(fov_intersection_k1(1,:)));
idx2 = (table_plane(1,:)<max(fov_intersection_k1(1,:)));
idx3 = (table_plane(2,:)>min(fov_intersection_k1(2,:)));
idx4 = (table_plane(2,:)<max(fov_intersection_k1(2,:)));
idx = idx1&idx2&idx3&idx4;
hold on;
plot3(table_plane(1,idx), table_plane(2,idx), table_plane(3,idx), plot_point_type);