%CLASS: EMPERICAL NULL CONVOLUTION
%Estimates the emperical null for a sample of pixels, given an image of z statistics
%The blanks are then filled in using linear interpolation
%The z statistics are then corrected for the emperical null
%
%HOW TO USE:
%Pass the image of z statistics through the constructor.
%The constructor also wants the number of rows and columns to perform a convolution and the size (kernel size) of the window
%Call the method estimateNull(n_linspace) to work out the emperical null
%The parameters of the null hypothesis are stored in the member variables mean_null and var_null
%Call the method setMask(segmentation) to set a mask for the member variables mean_null and var_null
%Call the method doTest() to do hypothesis testing, the resulting p values and significant pixels are stored in the member variables p_image and sig_image
classdef EmpericalConvolution < handle
    
    %MEMBER VARIABLES
    properties (SetAccess = private)
        n_col; %number of columns to sample
        n_row; %number of rows to sample
        kernel_size; %2 column vector [height, width] of the size of the moving window
        z_image; %image of z statistics
        test_size; %size of the test (if 0, use default value)
        
        mean_null; %image of emperical null mean parameter
        var_null; %image of emperical null var parameter
        p_image; %image of p values
        sig_image; %boolean image of significant pixels
    end
    
    %METHODS
    methods (Access = public)
        
        %CONSTRUCTOR
        %PARAMETERS:
            %z_image: image of z statistics
            %n_row: number of rows to sample
            %n_col: number of columns to sample
            %kernel_soze: 2 column vector [height, width] of the size of the moving window
        function this = EmpericalConvolution(z_image, n_row, n_col, kernel_size)
            %assign member variables
            this.z_image = z_image;
            this.n_row = n_row;
            this.n_col = n_col;
            this.kernel_size = kernel_size;
            this.test_size = 0;
        end
        
        %METHOD: ESTIMATE NULL
            %Does a convolution of a sample of pixels
            %Estimates the parameters of the emperical null for each of these pixels
            %The blanks are then filled in using linear interpolation
            %The parameters of the null hypothesis are stored in the member variables mean_null and var_null
        %PARAMETERS:
            %n_linspace: number of points to search for the mode
        function estimateNull(this, n_linspace)
            
            %get the size of the z image
            [height, width] = size(this.z_image);
            
            %get array of x and y (or column and row index)
            %they are equally spaced out points within the image
            x_array = round(linspace(1,width,this.n_col));
            y_array = round(linspace(1,height,this.n_row));
            
            %declare variables which are of size n_row x n_col
            this.mean_null = zeros(this.n_row, this.n_col);
            this.var_null = zeros(this.n_row, this.n_col);
            
            %do a meshgrid
            [x_grid, y_grid] = meshgrid(x_array,y_array);
            
            kernel_half_size = round(this.kernel_size / 2);
            
            %for each column
            for i_col = 1:this.n_col
                
                %get the x coordinate
                x_center = x_array(i_col);
                
                %get the x_index of the window
                x_window = (x_center - kernel_half_size(2)) : (x_center + kernel_half_size(2));
                %check the bounary of the window
                x_window(x_window<1) = [];
                x_window(x_window>width) = [];
                
                %for each row
                for i_row = 1:this.n_row
                    
                    %get the y_coordinate
                    y_center = y_array(i_row);
                    
                    %get the y_index of the window
                    y_window = (y_center - kernel_half_size(1)) : (y_center + kernel_half_size(1));
                    %check the bounary of the window
                    y_window(y_window<1) = [];
                    y_window(y_window>height) = [];
                    
                    %instantise a z tester
                    z_tester = ZTester(this.z_image(y_window,x_window));
                    %get the emperical null
                    z_tester.estimateNull(n_linspace);
                    
                    %get the p value in the middle of the window
                    this.mean_null(i_row, i_col) = z_tester.mean_null;
                    this.var_null(i_row, i_col) = (z_tester.std_null)^2;
                    
                end
            end
            
            %meshgrid for 2d interpolation
            [x_full, y_full] = meshgrid(1:width, 1:height);
            %interpolate the image
            this.mean_null = interp2(x_grid,y_grid,this.mean_null,x_full,y_full);
            this.var_null = interp2(x_grid,y_grid,this.var_null,x_full,y_full);
        end
        
        %METHOD: SET MASK
        %Set a mask for the member variables mean_null and var_null
        %Pixels not representing ROI will be set to NaN
        %PARAMETES:
            %segmentation: boolean image, true for pixel representing ROI
        function setMask(this, segmentation)
            this.mean_null(~segmentation) = nan;
            this.var_null(~segmentation) = nan;
        end
        
        %METHOD: DO TEST
        %Does hypothesis testing, corrected for emperical null
        %p values and signficant pixels are stored in the member variables p_image and sig_image
        function doTest(this)
            %correct the z statistics for the emperical null
            z_null = (this.z_image - this.mean_null) ./ sqrt(this.var_null);
            %instantise a ZTester
            z_tester = ZTester(z_null);
            %set the size of the test if a specific size is specified
            if this.test_size ~= 0
                z_tester.setSize(this.test_size);
            end
            %do the hypothesis test
            z_tester.doTest();
            %extract the p values and significant pixels
            this.p_image = z_tester.p_image;
            this.sig_image = z_tester.sig_image;
            
        end
        
        %METHOD: SET SIZE
        %Set the size of the test
        function setSize(this, test_size)
            this.test_size = test_size;
        end
        
    end
    
end
