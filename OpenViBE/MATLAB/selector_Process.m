%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function is called every time a new chunk is   %
%                     recieved from either the acquisition server or the  %
%                     gdf file reader in the Classifier_Online.xml        %
%                     OpenViBE scenario                                   %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function box_out = selector_Process(box_in)
    
    % Iterate through all the pending input chunks

    for i = 1:OV_getNbPendingInputChunk(box_in,1)
        
        % Pop the input buffer
        
        [box_in, start_time, end_time, matrix_data] = OV_popInputBuffer(box_in,1);
        
        % EEG output header
        box_in.outputs{1}.header = box_in.inputs{1}.header;
        box_in.outputs{1}.header.nb_channels = 12;
        box_in.outputs{1}.header.channel_names = {'Channel 3','Channel 4',...
        'Channel 5','Channel 7','Channel 8','Channel 9','Channel 10',...
        'Channel 11','Channel 13','Channel 14','Channel 15','Channel 16'};

        % EOG output header
        box_in.outputs{2}.header = box_in.inputs{1}.header;
        box_in.outputs{2}.header.nb_channels = 1;
        box_in.outputs{2}.header.channel_names = {'Class'};
        
        % Find the mean value of Channel 1 and 2 for the chunk
        
        meanch1 = mean(matrix_data(1,:));
        meanch2 = mean(matrix_data(2,:));
        
        % Determine the difference between the two channels
        
        normalizedch1 = meanch1 - box_in.user_data.normalizech1;
        normalizedch2 = meanch2 - box_in.user_data.normalizech2;
        
        difference = normalizedch1 - normalizedch2;
        
        if (difference > box_in.user_data.leftlimit*box_in.user_data.optimalmultiplier)
            
            % Classifies the chunk as looking left
            
            matrix_EOG = matrix_data(1,:);
            matrix_EOG(1:end) = 1;
            
            % Output from the MATLAB script box on output 2
            
            box_in = OV_addOutputBuffer(box_in,2,start_time,end_time,matrix_EOG);
            
        elseif (difference < box_in.user_data.rightlimit*box_in.user_data.optimalmultiplier) 
            
            % Classifies the chunk as looking right
           
            matrix_EOG = matrix_data(1,:);
            matrix_EOG(1:end) = 2;
           
            % Output from the MATLAB script box on output 2
            
            box_in = OV_addOutputBuffer(box_in,2,start_time,end_time,matrix_EOG);
           
        else
            
            % Feed the 12 EEG channels into the classifier if data is
            % regarded as EEG
            
            matrix_EEG = matrix_data([3:5,7:11,13:16],:);
            
            % Output from the MATLAB script box on output 1
            
            box_in = OV_addOutputBuffer(box_in,1,start_time,end_time,matrix_EEG);
        end

    end
    
    box_out = box_in;
    
end