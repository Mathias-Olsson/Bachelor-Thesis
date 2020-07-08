%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function is called once when pressing stop in  %
%                     the Classifier_Online.xml OpenViBE scenario         %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function box_out = selector_Uninitialize(box_in)

    disp('EOG / EEG selector uninitialize function has been called.')
    
    box_out = box_in;
    
end