%SCAN Class for handling x-ray images
classdef Scan < handle

    %MEMBER VARIABLES
    properties
        width; %width of the image
        height; %height of the image
        area; %area of the image
        n_sample; %number of images
        file_name; %... name of sample image
        folder_location; %location of the dataset
        aRTist_file; %location of the aRTist simulation
        reference_scan_array; %array of reference scan objects (in ascending powers)
        
        panel_counter %panel counter object
        shading_corrector; %shading corrector object
        want_shading_correction; %boolean, true to do shading correction, default false, automatically turns to true if a shading corrector is added
        want_remove_dead_pixels; %boolean, true to remove dead pixels, default false
        
        min_greyvalue; %minimum possible greyvalue
    end
    
    methods
        
        %CONSTRUCTOR
        %PARAMETERS:
            %folder_location: location of the images
            %file_name: name of the image files
            %width: width of the image
            %height: height of the image
            %n_sample: number of images
        function this = Scan(folder_location, file_name, width, height, n_sample)
            %assign member variable if parameters are provided
            if nargin > 0
                this.folder_location = folder_location;
                this.file_name = file_name;
                this.width = width;
                this.height = height;
                this.area = width * height;
                this.n_sample = n_sample;
                this.want_shading_correction = false;
                this.want_remove_dead_pixels = false;
                this.min_greyvalue = 0;
            end
        end
        
        %LOAD IMAGE
        %Return a sample image
        %PARAMETERS
            %index: index of image (scalar)
        function slice = loadImage(this,index)
            slice = imread(strcat(this.folder_location,this.file_name,num2str(index),'.tif'));
            slice = this.shadingCorrect(double(slice));
        end
        
        %LOAD IMAGE STACK
        %Return stack of sample images
        %PARAMETERS:
            %range (optional): vector of indices of images requested
                %if empty return the full range
        function stack = loadImageStack(this,range)
            %if range not provided, provide the full range
            if nargin == 1
                range = 1:this.n_sample;
            end
            %declare stack of images
            stack = zeros(this.height,this.width,numel(range));
            %for each image, put it in the stack
            for index = 1:numel(range)
                stack(:,:,index) = this.loadImage(range(index));
            end
        end
        
        %SHADING CORRECTION
        %if want_shading_correction, does shading correction on the
        %provided image and returns it
        %if want_remove_dead_pixels, remove dead pixels
        function slice = shadingCorrect(this,slice)
            if this.want_shading_correction
                slice = this.shading_corrector.shadingCorrect(slice);
            end
            if this.want_remove_dead_pixels
                slice = removeDeadPixels(slice);
            end
        end
        
        function addDefaultShadingCorrector(this)
            this.addShadingCorrector(ShadingCorrector(),[1,numel(this.reference_scan_array)]);
        end
        
        %ADD SHADING CORRECTOR
        %Assign a shading corrector to the member variable and calibrate it for shading correction
        %The reference images used are determined by the parameter reference_index
        %PARAMETERS:
            %shading_corrector: ShadingCorrector object
            %reference_index: matrix of integers, representing image index (optional), zeros are ignored
                %dim 1: #
                %dim 2: for each reference_scan_array
                %for each column, (eg 1st column for black images)
                %the mean of black images specified by dim 1 are used for shading corrector
                %
                %if not provided, use the mean of all images, black, grey and white
        function addShadingCorrector(this,shading_corrector,reference_index,image_index)
            
            %turn off shading correction to obtain the reference images
            this.turnOffShadingCorrection();
            
            %count the number of reference scans
            n_reference = numel(reference_index);
            
            shading_corrector.initalise(n_reference, this.height, this.width);
            
            %for each reference scan
            for i = 1:n_reference
                %if reference_index is not provided, take the mean of all images
                if nargin == 3
                    shading_corrector.addScan(this.reference_scan_array(reference_index(i)));
                %else take the mean of all images specified in the ith column of reference_index
                else
                    shading_corrector.addScan(this.reference_scan_array(reference_index(i),image_index(:,i)));
                end
            end
            
            %add the shading corrector to the member variable
            this.addManualShadingCorrector(shading_corrector);
            
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
            
            %if the shading corrector can smooth the reference images panel by panel
                %add the panel counter
            if this.shading_corrector.can_smooth
                this.shading_corrector.addPanelCounter(this.panel_counter);
            end
            
            %calibrate the shading corrector to do shading correction
            this.shading_corrector.calibrate();
            %set shading correction to be on
            this.turnOnShadingCorrection();
            
            %add the shading corrector to each reference scan in reference_scan_array
            for i = 1:numel(this.reference_scan_array)
                this.reference_scan_array(i).addManualShadingCorrector(this.shading_corrector);
            end
        end
        
        %TURN ON SHADING CORRECTION
        %Set the member variable want_shading_correction to be true
        function turnOnShadingCorrection(this)
            this.want_shading_correction = true;
            for i = 1:numel(this.reference_scan_array)
                this.reference_scan_array(i).turnOnShadingCorrection();
            end
        end
        
        %TURN OFF SHADING CORRECTION
        %Set the memebr variable want_shading_correction to be false
        function turnOffShadingCorrection(this)
            this.want_shading_correction = false;
            for i = 1:numel(this.reference_scan_array)
                this.reference_scan_array(i).turnOffShadingCorrection();
            end
        end
        
        %TURN ON REMOVE DEAD PIXELS
        function turnOnRemoveDeadPixels(this)
            this.want_remove_dead_pixels = true;
            for i = 1:numel(this.reference_scan_array)
                this.reference_scan_array(i).turnOnRemoveDeadPixels();
            end
        end
        
        %TURN OFF REMOVE DEAD PIXELS
        function turnOffRemoveDeadPixels(this)
            this.want_remove_dead_pixels = false;
            for i = 1:numel(this.reference_scan_array)
                this.reference_scan_array(i).turnOffRemoveDeadPixels();
            end
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
        
        %ADD ARTIST FILE
        function addARTistFile(this,aRTist_file)
            this.aRTist_file = aRTist_file;
        end
        
        %GET ARTIST IMAGE
        function slice = getARTistImage(this)
            slice = double(imread(this.aRTist_file));
        end
        
    end
    
end
