%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This script creates a .mat file for the test set    %
%                     containing all the test data and the order of the   %
%                     trials to compare to the predicted order after the  %
%                     classifier has run on the test set.                 %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;

% Write subject identifier; in our case the final experiment .gdf files 
% were labeled as SUBJECTID_ForsogN_Layout2.gdf. Where SUBJECTID is the id 
% of the subject and N is the experiment number, as we did 4 experiments 
% per subject, N ran from 1:4

subject = '';
sample_rate = 512;
ids = [769,770,774,780]; % OpenViBE stimulation IDs 
                         % 1#: Left 2#: Right 3#: Down 4#: Up

cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))

% Because we did multiple experiments, we loop through all the desired test
% sets

for i = 1:2
    filename = append(subject,'_Forsog',int2str(i+2),'_Layout2.gdf');

    [s, h] = sload(filename,'SampleRate',sample_rate);
    positions = zeros(1);
    
    % Find all the trials in the correct order
    
    for j = 1:4
        positions = positions + (h.EVENT.TYP == ids(j));
    end

    order = h.EVENT.TYP(logical(positions));

    for j = 1:4
        order(order == ids(j)) = j;
    end
    
    % Set all the trials in the experiment information to have identifier 
    % 783 (Unknown) as we have now extracted the trial order into a 
    % seperate vector
    
    h.EVENT.TYP(logical(positions)) = 783;

    save(append(subject,'_Test_set_Part',int2str(i)),'s','h','order');
    fprintf(sprintf('Saved %s part %d\n',subject,i));
end