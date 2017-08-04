classdef Experiment_GLMMeanVarTrainingTest < Experiment
    %EXPERIMENT_GLM_MEANVAR_TRAININGTEST Assess the performance of GLM fit on mean var data
    %   The images are spilt into 2 parts, training and test. GLM iss used
    %   to model the variance and mean relationship, with variance as the
    %   response. The response is gamma randomlly distributed with known
    %   shape parameter.   
    %
    %   Only the top half of the images were used, this is to avoid the
    %   form. In addition, the images were thresholded to only consider
    %   pixels from the 3d printed sample.
    %
    %   The training set is used to train the glm, which is then used to
    %   predict the variance of the test set. The training and mean
    %   standarised residuals are plotted, that is the residual divided by
    %   the std of gamma.
    %
    %   Different shading corrections, polynomial orders and link functions
    %   were considered. The experiment was repeated by reassigning the
    %   training and test set.
    
    %MEMBER VARIABLES
    properties
        
        i_repeat; %number of iterations done
        n_repeat; %number of itereations to complete the experiment
        n_glm;
        n_sample;
        %number of images in the training set
        n_train;
        %array of training and test mse
            %dim 1: for each repeat
            %dim 2: for each glm
        training_mse_array;
        test_mse_array;
        
        %segmentation boolean image
        segmentation;
        %random stream
        rand_stream;
        
        shape_parameter;
        
    end
    
    %METHODS
    methods
        
        %CONSTRUCTOR
        function this = Experiment_GLMMeanVarTrainingTest()
            %call superclass
            this@Experiment('GLMMeanVarTrainingTest');
        end

        %DECLARE RESULT ARRAY
        %PARAMETERS:
        function setUpExperiment(this)
            
            this.i_repeat = 1;
            this.n_repeat = 100;
            %assign member variables
            this.rand_stream = RandStream('mt19937ar','Seed',uint32(176048084));
            
            scan = this.getScan();
            this.n_sample = scan.n_sample;
            this.n_train = round(this.n_sample/2);
            this.shape_parameter = (this.n_train-1)/2;
            this.segmentation = scan.getSegmentation();
            this.segmentation = this.segmentation(1:(scan.height/2),:);
            this.segmentation = reshape(this.segmentation,[],1);
            
            %see member variables
            this.training_mse_array = zeros(this.n_repeat,this.getNGlm());
            this.test_mse_array = zeros(this.n_repeat,this.getNGlm());
        end
        
        
        %DO EXPERIMENT
        function doExperiment(this)
            
            %do n_repeat times
            while (this.i_repeat <= this.n_repeat)
            
                %use its random stream
                RandStream.setGlobalStream(this.rand_stream);
                %for each glm
                for i_glm = 1:this.getNGlm()
                    %get the training and test mse
                    [mse_training, mse_test] = this.trainingTestMeanVar(this.getGlm(this.shape_parameter, i_glm));
                    %save the training and test mse in the array
                    this.training_mse_array(this.i_repeat,i_glm) = mse_training;
                    this.test_mse_array(this.i_repeat,i_glm) = mse_test;
                end
                
                %print the progress
                this.printProgress(this.i_repeat / this.n_repeat);
                %increment i_repeat
                this.i_repeat = this.i_repeat + 1;
                %save the state of this experiment
                this.saveState();
                
            end
        end
        
        
        %TRAINING/TEST MEAN VAR Gets the training and test MSE when fitting and predicting the mean and variance relationship
        %PARAMETERS:
            %model: variance model object
        %RETURN:
            %mse_training
            %mse_test
        function [mse_training, mse_test] = trainingTestMeanVar(this, model)

                %get random index of the training and test data
                index_suffle = randperm(this.n_sample);
                training_index = index_suffle(1:this.n_train);
                test_index = index_suffle((this.n_train+1):end);

                %get variance mean data of the training set
                [sample_mean,sample_var] = this.getMeanVar(training_index);
                %segment the mean var data
                sample_mean = sample_mean(this.segmentation);
                sample_var = sample_var(this.segmentation);

                %train the classifier
                model.train(sample_mean,sample_var);
                %get the training mse
                mse_training = model.getPredictionMSSE(sample_mean,sample_var);

                %get the variance mean data of the test set
                [sample_mean,sample_var] = this.getMeanVar(test_index);
                
                %get the test mse
                mse_test = model.getPredictionMSSE(sample_mean,sample_var);

        end
        
        %PRINT RESULTS
        %Save the training and test MSE into a latex table
        function printResults(this)
            
            figure;
            boxplot(this.training_mse_array,'boxstyle','filled','medianstyle','target','outliersize',4,'symbol','o');
            
            figure;
            boxplot(this.test_mse_array,'boxstyle','filled','medianstyle','target','outliersize',4,'symbol','o');
            
        end
        
        function plotFullFit(this)

            n_bin = 100;
            scan = this.getScan();

            [sample_mean,sample_var] = this.getMeanVar(1:this.n_sample);
            
            mean_not_outlier = removeOutliers_iqr(sample_mean);
            var_not_outlier = removeOutliers_iqr(sample_var);
            not_outlier = mean_not_outlier & var_not_outlier;
            sample_mean = sample_mean(not_outlier);
            sample_var = sample_var(not_outlier);

            %shape parameter is number of (images - 1)/2, this comes from the chi
            %squared distribution
            full_shape_parameter = (scan.n_sample-1)/2;

            %for each polynomial order
            for i_glm = 1:this.getNGlm()

                model = this.getGlm(full_shape_parameter, i_glm);

                %train the classifier
                model.train(sample_mean,sample_var);

                %plot the frequency density
                figure;
                ax = hist3Heatmap(sample_mean,sample_var,[n_bin,n_bin],false);
                hold on;

                %get a range of greyvalues to plot the fit
                x_plot = linspace(ax.XLim(1),ax.XLim(2),100);
                %get the variance prediction along with the error bars
                [variance_prediction, up_error, down_error] = model.predict(x_plot');

                %plot the fit/prediction
                plot(x_plot,variance_prediction,'r');
                %plot the error bars
                plot(x_plot,up_error,'r--');
                plot(x_plot,down_error,'r--');
            end
        end
        
        function [sample_mean,sample_var] = getMeanVar(this, data_index)
            scan = this.getScan();
            [sample_mean,sample_var] = scan.getSampleMeanVar_topHalf(data_index);
            %segment the mean var data
            sample_mean = sample_mean(this.segmentation);
            sample_var = sample_var(this.segmentation);
        end
        
        function scan = getScan(this)
            scan = AbsBlock_Mar16();
        end
        
        function n_glm = getNGlm(this)
            n_glm = 9;
        end
        
        function model = getGlm(this, shape_parameter, index)
            switch index
                case 1
                    model = MeanVar_GLM_identity(shape_parameter,1);
                case 2
                    model = MeanVar_GLM_canonical(shape_parameter,-1);
                case 3
                    model = MeanVar_GLM_canonical(shape_parameter,-2);
                case 4
                    model = MeanVar_GLM_canonical(shape_parameter,-3);
                case 5
                    model = MeanVar_GLM_canonical(shape_parameter,-4);
                case 6
                    model = MeanVar_GLM_log(shape_parameter,-1);
                case 7
                    model = MeanVar_GLM_log(shape_parameter,-2);
                case 8
                    model = MeanVar_GLM_log(shape_parameter,-3);
                case 9
                    model = MeanVar_GLM_log(shape_parameter,-4);
            end
        end
        
    end
    
    
    
end

