%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function is called once when pressing start in %
%                     the Classifier_Online.xml OpenViBE scenario         %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function box_out = classoutput_Initialize(box_in)
    
    disp('Class output initialize function has been called.')
    
    % Create a custom data field to store the classified class
    
    box_in.user_data.class_type = 0;
    
    box_out = box_in;
    
end