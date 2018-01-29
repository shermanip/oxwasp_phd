classdef GlmGamma < Regressor
    %MEANVAR_GLM Class for modelling variance as gamma with known shape parameter given
    %mean greyvalue
    
    %MEMBER VARIABLES
    properties (SetAccess = protected)
        %shape parameter of the gamma distribution
        shape_parameter;
        %normalising constants for the response and feature
        y_scale;
        x_scale; %column vector, for each polynomial feature
        x_shift; %colun vector, for each polynomial feature
        polynomial_order; %column vector of polynomial order features
        n_order; %number of polynomial orders
        n_step; %n_step: number of IRLS steps
        initial_parameter; %the initial value of the parameter
        tol; %stopping conidition for the different in log likelihood * n_train
        link_function; %object LinkFunction which implemented the methods getLinkDiff and getMean
        fisher;
        scaled_deviance; %scaled deviance
        n; %sample size
    end
    
    %METHODS
    methods (Access = public)
        
        %CONSTRUCTOR
        %PARAMETERS:
            %shape_parameter: shape parameter of the gamma distribution
            %polynomial_order: column vector of polynomial order features
            %link_function: object LinkFunction
        function this = GlmGamma(polynomial_order,link_function)
            if nargin ~= 0
                %assign member variables
                this.polynomial_order = polynomial_order;
                this.n_order = numel(polynomial_order);
                this.n_step = 10;
                this.link_function = link_function;
                this.initial_parameter = zeros(this.n_order+1,1);
                this.initial_parameter(1) = this.link_function.initial_intercept;
                this.tol = 1E-1;
                this.shape_parameter = 1;
            end
        end
        
        %METHOD: SET SHAPE PARAMETER
        %Set the shape parameter of the gamma regression
        function setShapeParameter(this, alpha)
            this.shape_parameter = alpha;
        end
        
        %METHOD: TRAIN
        %PARAMETERS:
            %x: column vector of features
            %y: column vector of gamma responses
        function train(this,x,y)

            %save the sample size
            this.n = numel(x);
            
            %scale the response variables
            this.y_scale = std(y);
            y = y./this.y_scale;
            %get the sufficient statistics
            lny = log(y);
            
            %get the design matrix
            X = this.getDesignMatrix(x);
            %normalise the features to have mean 0 and std 1
            this.x_shift = mean(X(:,2:end),1);
            this.x_scale = std(X(:,2:end),true,1); %normalise by n
            %get the normalised design matrix
            X = this.normaliseDesignMatrix(X);

            %set inital parameter
            this.parameter = this.initial_parameter;
            %assign training set size
            this.n_train = numel(y);
            
            %IRLS SECTION
            
            %initalise variables
            %work out the log likelihhod up to a constant
            %w and z are variables for IRLS
            [mu, w, z] = this.getIRLSStatistics(X, y);
            d_old = this.getScaledDeviance(mu, y, lny);
            
            %for n_step times
            for i_step = 1:this.n_step
                
                %update the parameter
                this.updateParameter(w, X, z, y);
                
                %if the parameter is nan, break the for loop and end
                if(any(isnan(this.parameter)))
                    warning('nan parameter');
                    break;
                end

                %update variables
                %work out the new log likelihhod up to a constant
                [mu, w, z] = this.getIRLSStatistics(X, y);
                d_new = this.getScaledDeviance(mu, y, lny);
                
                %if the improvement in log likelihhod is less than tol*n_train
                if ( (d_new - d_old) > this.tol*this.n_train)
                    %break the loop
                    break;
                end
                
                %update the log likelihood
                d_old = d_new;
            end
            
            %saved the scaled deviance
            this.scaled_deviance = d_new;
            
            %%Fisher information matrix
            %Used to calculate the parameter covariance
            WX = zeros(this.n_train,this.n_order+1);
            for i = 1:(this.n_order+1)
              WX(:,i) = w(i)*X(:,i); 
            end
            this.fisher = inv(X'*WX);
            
        end
        
        %METHOD PREDICT VARIANCE GIVEN MEAN
        %PARAMETERS:
            %x: column vector of mean greyvalue
        %RETURN:
            %variance_prediction: predicted greyvalue variance (column vector)
            %up_error: 84% percentile
            %down_error: 16% percentile
        function [y_hat, up_error, down_error] = predict(this,x)
            %get design matrix
            X = this.getNormalisedDesignMatrix(x);
            %work out variables
            eta = X*this.parameter;
            %work out mean, to be used for the variance prediction
            y_hat = this.getMean(eta) * this.y_scale;
            %get rate parameter
            gamma_scale = y_hat./this.shape_parameter;
            
            %work out the [16%, 84%] percentile, to be used for error bars
            up_error = gaminv(normcdf(1),this.shape_parameter,gamma_scale);
            down_error = gaminv(normcdf(-1),this.shape_parameter,gamma_scale);
            
            %calculate mean estimation error
            %%NEEDS TO BE REWRITTEN, X*this.parameter_covariance*X' REQUIRES TOO MUCH MEMORY
            %mean_var = (1/this.y_scale^2) * (this.link_function.getLinkDiff(variance_prediction).^(-2)).* diag(X*this.parameter_covariance*X');
        end
        
        %IMPLEMENTED: HAS ERROR BAR
        %Return true to indicate this regression does have error bars for the predictions
        function has_errorbar = hasErrorbar(this)
            has_errorbar = true;
        end

        %METHOD SIMULATE
        %PARAMETERS:
            %x: column vector of greyvalue means
            %parameter: parameter for GLM
        %RETURN:
            %y: column vector of simulated greyvalue variance
        function y = simulate(this,x,parameter)
            
            %get design matrix
            X = this.getDesignMatrix(x);
            
            %work out systematic component
            eta = X*parameter;
            %get rate parameter
            gamma_scale = this.getMean(eta)./this.shape_parameter;

            %simulate gamma from the natural parameter
            y = gamrnd(this.shape_parameter,gamma_scale);
        end

        %PREDICTION MEAN SQUARED STANDARDIZED ERROR
        %Return the mean squared standardized and mean squared prediction error
        %PARAMETERS:
            %y: greyvalue variance (column vector)
            %x: greyvalue mean (column vector)
            %x and y are the same size
        %RETURN:
            %mse_vector: 2 column vector, [msse; mse]
        function [mse_vector] = getPredictionMSSE(this,x,y)
            %given greyvalue mean, predict greyvalue variance
            y_predict = this.predict(x);
            %work out the mean squared error
            residual_squared = (y-y_predict).^2;
            var = this.getVariance(x);
            msse = mean(residual_squared./var);
            mse = mean(residual_squared);
            mse_vector = [msse; mse];
        end
        
        %GET LINK FUNCTION DIFFERENTATED
        %PARAMETERS:
            %mu: column vector of means
        %RETURN:
            %g_dash: colum vector of g'(mu)
        function g_dash = getLinkDiff(this,mu)
            g_dash = this.link_function.getLinkDiff(mu);
        end
        
        %GET MEAN (LINK FUNCTION)
        %PARAMETERS:
            %eta: vector of systematic components
        %RETURN:
            %mu: vector of mean responses
        function mu = getMean(this,eta)
            mu = this.link_function.getMean(eta);
        end
        
        %GET NAME
        %Return name for this glm
        function name = getName(this)
            name = cell2mat({this.link_function.name,', order ',num2str(this.polynomial_order)});
        end
        
        %GET FILE NAME
        function name = getFileName(this)
            name = cell2mat({this.link_function.name,'_order_',num2str(this.polynomial_order)});
        end
        
        %METHOD: ESTIMATE SHAPE PARAMETER
        function estimateShapeParameter(this)
            this.shape_parameter = (this.n - 2)/this.scaled_deviance;
        end
        
        function [a,b] = getParameter(this)
            a = zeros(2,1);
            b = zeros(2,1);
            a(1) = (this.parameter(1)-this.parameter(2)*this.x_shift/this.x_scale)*this.y_scale;
            b(1) = this.parameter(2) * this.y_scale / this.x_scale;
            standard_error = sqrt(diag(this.fisher)/this.shape_parameter).*[this.y_scale;this.y_scale/this.x_scale];
            a(2) = standard_error(1);
            b(2) = standard_error(2);
        end
     
    end
    
    methods (Access = private)
        
        %UPDATE PARAMETER USING IRLS
        %PARAMETERS:
            %w: vector of weights
            %X: design matrix
            %z: response vector
        function updateParameter(this, w, X, z, ~)
            %get W^(1/2) * X %where W is diagonal square
            w_square_root = sqrt(w); %get the vector of square root w
            %declare matrix of size nx2 to represent W^(1/2) * X
            w_square_root_x = zeros(this.n_train, this.n_order+1);
            %without calculating the full W matrix, calculate W^(1/2) * X
            for i_p = 1:(this.n_order+1)
                w_square_root_x(:,i_p) = X(:,i_p).*w_square_root;
            end
            %work out the z vector (including the square root w term)
            z = w_square_root .* z;
            %update the parameter (with the use of QR)
            this.parameter = w_square_root_x \ z;
        end
        
        %GET IRLS STATISTICS
        %Return the log likelihood, vector of weights and response vector for IRLS
        %PARAMETERS:
            %X: design matrix
            %y: gamma response vector (column)
            %parameter: column parameter vector
        %RETURN:
            %lnL: log likelihood
            %w: vector of weights
            %z: response vector
        function [mu, w, z] = getIRLSStatistics(this, X, y)
            eta = X*this.parameter; %systematic component
            mu = this.getMean(eta); %mean vector
            %v = mu.^2 / this.shape_parameter; %variance vector
            v = mu.^2; %variance vector
            w = 1./(v.*(this.getLinkDiff(mu)).^2); %weights in IRLS
            %w = 1./(v.*this.getLinkDiff(mu)); %error in old code
            z = (eta + (y-mu).*this.getLinkDiff(mu));
        end
        
        %GET DEVIANCE
        %PARAMETERS:
            %mu: column vector of means
            %y: column vector of the response
            %lny: column vector of ln response
        %RETURN:
            %d: deviance
        function d = getDeviance(this, mu, y, lny)
            d = this.shape_parameter * this.getScaledDeviance(mu, y, lny);
        end
        
        %GET SCALED DEVIANCE
        %PARAMETERS:
            %mu: column vector of means
            %y: column vector of the response
            %lny: column vector of ln response
        %RETURN:
            %d: scaled deviance
        function d = getScaledDeviance(this, mu, y, lny)
            d = 2*sum((y-mu)./mu - lny + log(mu));
        end
        
        %METHOD: GET LOG LIKELIHOOD
        function lnL = getLogLikeLihood(this,mu,y)
            %work out the log likelihhod up to a constant
            lnL = -this.shape_parameter*(sum(log(mu)+y./mu));
        end
        
        %GET DESIGN MATRIX
        %Returns a design matrix with polynomial features given a column vector of explanatory variables
        %PARAMETERS:
            %x: column vector of greyvalues
        %RETURN:
            %X: n x this.n_order + 1 design matrix
        function X = getDesignMatrix(this,x)
            %declare design matrix
            X = zeros(numel(x),this.n_order + 1);
            %first column is a constant
            X(:,1) = 1;
            %for each order
            for i_order = 1:this.n_order
                %put the explantory variable ^ polynomial_order(i_order) in the design matrix
                X(:,1+i_order) = x.^(this.polynomial_order(i_order));
            end
        end
        
        %GET NORMALISED DESIGN MATRIX
        %Return a normalised design matrix given a vector of data (with polynomial features)
        %PARAMETERS:
            %x: column vector of greyvalues
        %RETURN:
            %X: normalised design matrix (nxp matrix, 1st column constants)
        function X = getNormalisedDesignMatrix(this,x)
            X = this.getDesignMatrix(x);
            X = this.normaliseDesignMatrix(X);
        end
        
        %NORMALISE DESIGN MATRIX
        %Normalise a given design matrix (1st column constants) to have
            %columns with mean 0
            %columns with var 1 (n divisor)
        %PARAMETERS
            %X: design matrix (nxp matrix, 1st column constant and ignored)
        %RETURN
            %X: normalised design matrix
        function X = normaliseDesignMatrix(this,X)
            n = numel(X(:,1));
            X(:,2:end) = ( X(:,2:end)- repmat(this.x_shift, n, 1 ) ) ./ repmat(this.x_scale, n, 1);
        end
        
        %GET VARIANCE
        %Return the variance of the response for a given grey value
        %PARAMETERS:
            %grey_values: column vector of greyvalues
        function variance = getVariance(this,grey_values)
            %get design matrix
            X = this.getNormalisedDesignMatrix(grey_values);
            %get systematic
            eta = X * this.parameter;
            %get mean
            mu = this.getMean(eta);
            %get variance
            variance = mu.^2 / this.shape_parameter;
            %scale the variance
            variance = variance * this.y_scale^2;
        end
        
    end

end
