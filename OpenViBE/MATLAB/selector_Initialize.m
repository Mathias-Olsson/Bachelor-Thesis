%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function is called once when pressing start in %
%                     the Classifier_Online.xml OpenViBE scenario         %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function box_out = selector_Initialize(box_in)

    disp('EOG / EEG selector initialize function has been called.')
    
    % Load in the subject specific EOG data from the EOGAccuracy.m script 
    
    load('optimalEOG','optimalmultiplier','leftlimit','rightlimit','normalizech1','normalizech2');
    
    box_in.user_data.optimalmultiplier = optimalmultiplier;
    box_in.user_data.leftlimit = leftlimit;
    box_in.user_data.rightlimit = rightlimit;
    box_in.user_data.normalizech1 = normalizech1;
    box_in.user_data.normalizech2 = normalizech2;
    
    box_out = box_in;
    
end