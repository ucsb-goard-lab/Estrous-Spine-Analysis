classdef getDendriteInfoClass < handle
    %GETDENDRITEINFO methods to obtain features of dendrite spines,
    %including branch points, end points, and perimeter
    
    properties (Access = public)
        image_skeleton;
        image_perimeter;
        x_end;
        y_end;
        x_perim;
        y_perim;
        x_branch;
        y_branch;
    end
    
    methods
        function obj = getDendriteInfoClass(BW)
           %% CONSTRUCTOR: Skeletonization: Skeletonization of dendrite and trimming of "extra" spines
            obj.image_skeleton = bwmorph(BW,'thin',inf);
            obj.image_perimeter = bwmorph(BW,'remove');
            obj.getEndPoints();
            obj.getPerimeter();
            obj.getBranchPoints();
            %figure,imshow(image_skeleton) %uncomment to show image skeleton
        end

        function getBranchPoints(obj)
            % GETBRANCHPOINTS takes in branchpoints taken from a skeleton with
            % morphological operations, separates them into x and y components, and
            % cleans the data
            
            [x_branchval, y_branchval] = find((bwmorph(obj.image_skeleton, 'branchpoints'))');
            xy_branch = zeros(length(obj.x_end),2);
            
            for i = 1:length(obj.x_end)
                
                distance_endpoints = bwdistgeodesic(obj.image_skeleton, obj.x_end(i), obj.y_end(i), 'quasi-euclidean');
                vector_distance = zeros(length(x_branchval),1);
              
                for j = 1:length(x_branchval) %for every branch point to this end point
                    vector_distance(j) = distance_endpoints(y_branchval(j),x_branchval(j));
                end
                
                if isempty(vector_distance) || vector_distance(1,1) == Inf
                    continue 
                else 
                    % find which branch has the smallest distance to endpoint
                    [~,val] = min(vector_distance); 
                    xy_branch(i,:) = [x_branchval(val(1)),y_branchval(val(1))];
                end
            end
            
            obj.x_branch = xy_branch(:,1); 
            obj.y_branch = xy_branch(:,2);
            
        end

        function getEndPoints(obj)
            [x_endval, y_endval] = find((bwmorph(obj.image_skeleton, 'endpoints'))');
            obj.x_end = x_endval;
            obj.y_end = y_endval;
        end
        
        function getPerimeter(obj)
            [x_perval, y_perval] = find(obj.image_perimeter');
            obj.x_perim = x_perval;
            obj.y_perim = y_perval;
        end
    end
end

