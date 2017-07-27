%FIT GLM SCRIPT
%Model the mean and variance relationship, using the top half of the stack image The response variance is gamma
%distributed with known shape parameter from the chi squared distribution.
%The feature is the mean grey value to some power. A frequency
%density graph is plotted along with the fit

clc;
clearvars;
close all;

%number of bins for the frequency density plot
nbin = 100;

%instantise an object pointing to the dataset
block_data = AbsBlock_Mar16();

%get variance mean data of the top half of the scans (images 1 to 100)
[sample_mean,sample_var] = block_data.getSampleMeanVar_topHalf();

%segment the mean variance data to only include the 3d printed sample
threshold = reshape(AbsBlock_Mar16.getThreshold_topHalf(),[],1);
sample_mean(threshold) = [];
sample_var(threshold) = [];

%shape parameter is number of (images - 1)/2, this comes from the chi
%squared distribution
shape_parameter = (block_data.n_sample-1)/2;

%name of each link function
link_name = {'identity','log','canonical_1','canonical_2'};

%for each polynomial order
for i = 1:4
    
    %model the mean and variance using gamma glm using different link
    %functions and polynomial features
    switch i
        case 1
            model = MeanVar_GLM_identity(shape_parameter,1);
        case 2
            model = MeanVar_GLM_log(shape_parameter,-1);
        case 3
            model = MeanVar_GLM_canonical(shape_parameter,-1);
        case 4
            model = MeanVar_GLM_canonical(shape_parameter,-2);
    end
    
    %train the classifier
    model.train(sample_mean,sample_var);

    %plot the frequency density
    figure;
    ax = plotHistogramHeatmap(sample_mean,sample_var,nbin);
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
    
    saveas(gca,strcat('reports/figures/meanVar/meanVar_',link_name{i},'.png'),'png');
end