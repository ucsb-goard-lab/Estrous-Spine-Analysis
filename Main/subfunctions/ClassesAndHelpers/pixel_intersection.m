function intersection = pixel_intersection(input_1,input_2)

    curve1 = logical(input_1);
    curve2 = logical(input_2);
    LL = zeros(size(curve1));
    LL(curve1) = 1;
    LL(curve2) = 2;

    curve1 = (LL == 1);
    curve2 = (LL == 2);
    curve1_thickened = imdilate(curve1,ones(3,3));

    curve2_thickened   = imdilate(curve2,ones(3,3));
    curve_intersection = curve1_thickened & curve2_thickened;
    ultimate_erosion   = bwulterode(curve_intersection);

    s = regionprops(ultimate_erosion,'Centroid');

    intersection = [round(s(1).Centroid(1)),round(s(1).Centroid(2))];
    
end

