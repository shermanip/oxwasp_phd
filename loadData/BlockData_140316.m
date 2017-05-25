classdef BlockData_140316 < handle
    %BLOCKDATA
    %Class for obtaining images for the 140316 data
    
    %MEMBER VARIABLES
    properties
        width; %width of the image
        height; %height of the image
        area; %area of the image
        n_black; %number of black images
        n_white; %number of white images
        n_grey; %number of grey images
        n_sample; %number of sample images
        black_name; %'/' + name of black image file excluding number at the end
        white_name; %... name of white image ...
        grey_name; %... name of grey image ...
        sample_name; %... name of sample image
        folder_location; %location of the dataset
        
        panel_counter%
        
        want_shading_correction; %boolean, true to do shading correction, default false, automatically turns to true if a shading corrector is added
        shading_corrector; %shading corrector object
        
        want_remove_dead_pixels; %boolean, true to remove dead pixels, default false
        
        min_greyvalue; %minimum possible greyvalue
    end
    
    %METHODS
    methods
        
        %CONSTRUCTOR
        function this = BlockData_140316(folder_location)
            %assign member variables
            this.width = 1996;
            this.height = 1996;
            this.area = 1996^2;
            this.n_black = 20;
            this.n_white = 20;
            this.n_grey = 20;
            this.n_sample = 100;
            this.black_name = '/black_140316_';
            this.white_name = '/white_140316_';
            this.grey_name = '/grey_140316_';
            this.sample_name = '/block_';
            this.folder_location = folder_location;
            this.want_shading_correction = false;
            this.want_remove_dead_pixels = false;
            this.min_greyvalue = 5.7588E3;
            this.panel_counter = PanelCounter_Brass();
        end
        
        %LOAD BLACK IMAGE
        %Return a black image
        %PARAMETERS
            %index: index of image
        function slice = loadBlack(this,index)
            slice = imread(strcat(this.folder_location,'/black',this.black_name,num2str(index),'.tif'));
            slice = this.shadingCorrection(double(slice));
        end
        
        %LOAD GREY IMAGE
        %Return a grey image
        %PARAMETERS
            %index: index of image
        function slice = loadGrey(this,index)
            slice = imread(strcat(this.folder_location,'/grey',this.grey_name,num2str(index),'.tif'));
            slice = this.shadingCorrection(double(slice));
        end
        
        %LOAD WHITE IMAGE
        %Return a white image
        %PARAMETERS
            %index: index of image
        function slice = loadWhite(this,index)
            slice = imread(strcat(this.folder_location,'/white',this.white_name,num2str(index),'.tif'));
            slice = this.shadingCorrection(double(slice));
        end
        
        %LOAD SAMPLE IMAGE
        %Return a sample image
        %PARAMETERS
            %index: index of image
        function slice = loadSample(this,index)
            slice = imread(strcat(this.folder_location,'/sample',this.sample_name,num2str(index),'.tif'));
            slice = this.shadingCorrection(double(slice));
        end
        
        %LOAD BLACK IMAGE STACK
        %Return stack of black images
        %PARAMETERS:
            %range (optional): vector of indices of images requested, if
            %empty return the full range
        function stack = loadBlackStack(this,range)
            %if range not provided, provide the full range
            if nargin == 1
                range = 1:this.n_black;
            end
            %declare stack of images
            stack = zeros(this.height,this.width,numel(range));
            %for each image, put it in the stack
            for index = 1:numel(range)
                stack(:,:,index) = this.loadBlack(range(index));
            end
        end
        
        %LOAD GREY IMAGE STACK
        %Return stack of grey images
        %PARAMETERS:
            %range (optional): vector of indices of images requested, if
            %empty return the full range
        function stack = loadGreyStack(this,range)
            %if range not provided, provide the full range
            if nargin == 1
                range = 1:this.n_grey;
            end
            %declare stack of images
            stack = zeros(this.height,this.width,numel(range));
            %for each image, put it in the stack
            for index = 1:numel(range)
                stack(:,:,index) = this.loadGrey(range(index));
            end
        end
        
        %LOAD WHITE IMAGE STACK
        %Return stack of white images
        %PARAMETERS:
            %range (optional): vector of indices of images requested, if
            %empty return the full range
        function stack = loadWhiteStack(this,range)
            %if range not provided, provide the full range
            if nargin == 1
                range = 1:this.n_white;
            end
            %declare stack of images
            stack = zeros(this.height,this.width,numel(range));
            %for each image, put it in the stack
            for index = 1:numel(range)
                stack(:,:,index) = this.loadWhite(range(index));
            end
        end
        
        %LOAD SAMPLE IMAGE STACK
        %Return stack of sample images
        %PARAMETERS:
            %range (optional): vector of indices of images requested, if
            %empty return the full range
        function stack = loadSampleStack(this,range)
            %if range not provided, provide the full range
            if nargin == 1
                range = 1:this.n_sample;
            end
            %declare stack of images
            stack = zeros(this.height,this.width,numel(range));
            %for each image, put it in the stack
            for index = 1:numel(range)
                stack(:,:,index) = this.loadSample(range(index));
            end
        end
        
        %GET SAMPLE MEAN VARIANCE DATA (using top half of the images)
        %PARAMETERS:
            %index (optional): vector of indices of images requested to be
            %used in mean and variance estimation, if not provided all
            %images shall be considered
        function [sample_mean,sample_var] = getSampleMeanVar_topHalf(this,index)

            %if index not provided, index points to all images
            if nargin == 1
                index = 1:this.n_sample;
            end
            
            %load the stack of images, indicated by the vector index
            stack = this.loadSampleStack(index);
            %crop the stack, keeping the top half
            stack = stack(1:(this.height/2),:,:);
            %work out the sample mean and convert it to a vector
            sample_mean = reshape(mean(stack,3),[],1);
            %work out the sample variance and convert it to a vector
            sample_var = reshape(var(stack,[],3),[],1);

        end
        
        %TURN ON SHADING CORRECTION
        %Set the member variable want_shading_correction to be true
        function turnOnShadingCorrection(this)
            this.want_shading_correction = true;
        end
        
        %TURN OFF SHADING CORRECTION
        %Set the memebr variable want_shading_correction to be false
        function turnOffShadingCorrection(this)
            this.want_shading_correction = false;
        end
        
        %TURN ON REMOVE DEAD PIXELS
        function turnOnRemoveDeadPixels(this)
            this.want_remove_dead_pixels = true;
        end
        
        %TURN OFF REMOVE DEAD PIXELS
        function turnOffRemoveDeadPixels(this)
            this.want_remove_dead_pixels = false;
        end
        
        %SHADING CORRECTION
        %if want_shading_correction, does shading correction on the
        %provided image and returns it
        %if want_remove_dead_pixels, remove dead pixels
        function slice = shadingCorrection(this,slice)
            if this.want_shading_correction
                slice = this.shading_corrector.shadeCorrect(slice);
            end
            if this.want_remove_dead_pixels
                slice = removeDeadPixels(slice);
            end
        end
        
        %ADD SHADING CORRECTOR
        %Instantise a new shading corrector to the member variable and calibrate it
        %for shading correction
        %PARAMETERS:
            %shading_corrector_class: function name or function handle of
            %a ShadingCorrector class
            %want_grey: boolean, true if want to consider grey images
            %parameters (optional): a vector of parameters for panel fitting (one for each reference image)
        function addShadingCorrector(this,shading_corrector_class,want_grey,parameters)
            
            %turn off shading correction to obtain the reference images
            this.turnOffShadingCorrection();
            
            %declare an array reference_stack which stores the mean black and mean
            %white image
            reference_stack = zeros(this.height,this.width,2+want_grey);
            %load and save the mean black image
            reference_stack(:,:,1) = mean(this.loadBlackStack(),3);
            %load and save the mean white image
            reference_stack(:,:,2) = mean(this.loadWhiteStack(),3);
            %if want_grey, load and save the mean grey image
            if want_grey
                reference_stack(:,:,3) = mean(this.loadGreyStack(),3);
            end

            %instantise a shading corrector and set it up using reference images
            if nargin == 3
                shading_corrector_temp = feval(shading_corrector_class,reference_stack);
            elseif nargin == 4
                shading_corrector_temp = feval(shading_corrector_class,reference_stack, this.panel_counter, parameters);
            end
            
            this.addManualShadingCorrector(shading_corrector_temp);
            
        end
        
        %ADD MANUAL SHADING CORRECTOR
        %Assign a provided shading corrector to the member variable and calibrate it
        %for shading correction
        %PARAMETERS:
            %shading_corrector: shading_corrector object
        function addManualShadingCorrector(this,shading_corrector)
            %assign the provided shading corrector to the member variable
            this.shading_corrector = shading_corrector;

            %get the minimum possible greyvalue to the shading corrector
            this.shading_corrector.min_greyvalue = this.min_greyvalue;
            
            %calibrate the shading corrector to do shading correction
            this.shading_corrector.calibrate();
            %set shading correction to be on
            this.turnOnShadingCorrection();
        end
        
        %TURN ON SET EXTREME TO NAN
        %Set the shading corrector to set extreme greyvalues to be NaN
        function turnOnSetExtremeToNan(this)
            this.shading_corrector.turnOnSetExtremeToNan();
        end
        
        %TURN OFF SET EXTREME TO NAN
        %Set the shading corrector to keep extreme greyvalues
        function turnOffSetExtremeToNan(this)
            this.shading_corrector.turnOffSetExtremeToNan();
        end
        
    end
    
    methods (Static)
        
        %GET THRESHOLD TOP HALF
        %Return a logical matrix which segments the sample from the
        %background of the top half of the scans. 1 indicate the
        %background, 0 for the sample.
        %
        %Method: does shading correction with median filter applied to the
        %reference images, take the mean of the shading corrected images
        %and then threshold at 4.7E4
        function threshold = getThreshold_topHalf()
            
            %load the data
            block_data = BlockData_140316('data/140316');

            %add shading correction
            block_data.addShadingCorrector(@ShadingCorrector_median,1,[3,3,3]);

            %load the images
            slice = block_data.loadSampleStack();
            %crop the images to keep the top half
            slice = slice(1:(round(block_data.height/2)),:,:);
            %take the mean over all images
            slice = mean(slice,3);
            %remove dead pixels
            slice = removeDeadPixels(slice);

            %indicate pixels with greyvalues more than 4.7E4
            threshold = slice>4.7E4;
        end
    end
    
end
