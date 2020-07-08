%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function is called every time a chunk has been %
%                     classified, either through EEG or EOG in the        %
%                     Classifier_Online.xml OpenViBE scenario             %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function box_out = classoutput_Process(box_in)
    
    % Iterate through all the pending input chunks on input 2
    
    for i = 1:OV_getNbPendingInputChunk(box_in,2)
        
        % Pop the input buffer on input 2
        
        [box_in, start_time, end_time, class] = OV_popInputBuffer(box_in,2);
        
        % Return the EOG class if the chunk is classified as EOG
        
        if mean(class) ~= 0
            
            class_output = class;
            
            % Output from the MATLAB script box on output 1
            
            box_in = OV_addOutputBuffer(box_in,1,start_time,end_time,class_output);
            
        end
        
    end

    % Iterate through all the pending input chunks on input 3

    for i = 1:OV_getNbPendingInputChunk(box_in,3)
        
        % Pop the input buffer on input 3
        
        [box_in, ~, ~, stim_set] = OV_popInputBuffer(box_in,3);
        
        % Check if the EEG classifier returns a stimulation ID equal to
        % down
        
        if stim_set(1) == 774
            
            % Set the custom datafield to the class corresponding to down 
            
            box_in.user_data.class_type = 3;
        
        % Check if the EEG classifier returns a stimulation ID equal to up    
            
        elseif stim_set(1) == 780
            
            % Set the custom datafield to the class corresponding to up
            
            box_in.user_data.class_type = 4;

        end
        
    end
    
    % Iterate through all the pending input chunks on input 1
    
    for i = 1:OV_getNbPendingInputChunk(box_in,1)
        
        % Pop the input buffer on input 1
        
        [box_in, start_time, end_time, prob_matrix] = OV_popInputBuffer(box_in,1);
        
        % Set the output header to be similar to the header from the EOG
        % input
        
        box_in.outputs{1}.header = box_in.inputs{2}.header;
        
        % Determine the probability of the class that the classifier found
        
        probability = mean(prob_matrix);
        
        % Threshold the EEG classifier
        
        if probability > classifier_threshold && (box_in.user_data.class_type == 3 || box_in.user_data.class_type == 4)
            
            % Return the classified EEG classifier if above the threshold
            
            class_output = zeros(1,8) + box_in.user_data.class_type;
            
            % Output from the MATLAB script box on output 1
            
            box_in = OV_addOutputBuffer(box_in,1,start_time,end_time,class_output);
        
        else
            
            box_in.user_data.class_type = 0;
            
        end
        
    end
    
    box_out = box_in;
    
end