classdef Experiment_GLMVarMean_July16_30deg_linear < Experiment_GLMVarMean_July16_30deg
    
    properties
    end
    
    methods
        
        %CONSTRUCTOR
        function this = Experiment_GLMVarMean_July16_30deg_linear()
            %call superclass with experiment name
            this@Experiment_GLMVarMean_July16_30deg(Experiment_GLMVarMean_July16_30deg_linear.getExperimentName());
        end
        
        %OVERRIDE: SET UP EXPERIMENT
        function setUpExperiment(this)
            %call superclass with 100 repeats and a random seed
            this.setUpExperiment@Experiment_GLMVarMean_July16_30deg(uint32(3708634680));
        end
        
        function [shading_corrector, reference_index] = getShadingCorrector(this, index)
            scan = this.getScan();
            shading_corrector = ShadingCorrector();
            reference_index = 1:scan.getNReference();
        end
    end
    
    methods (Static)
        
        function experiment_name = getExperimentName()
            experiment_name = 'GLMVarMean_July16_30deg_linear';
        end
        
    end
    
end
