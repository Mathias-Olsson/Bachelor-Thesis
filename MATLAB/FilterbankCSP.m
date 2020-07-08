%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This script computes the CSP based on the filtered  %
%                     data from the Filterbank.m script.                  %
%                                                                         %
% Additional used MATLAB packages / functions: computeCSP by Ana Palma    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

% Select desired type of dimensionality reduction - NONE, PCA or ICA.
% Write subject identifier; in our case the final experiment .gdf files 
% were labeled as SUBJECTID_ForsogN_Layout2.gdf. Where SUBJECTID is the id 
% of the subject and N is the experiment number, as we did 4 experiments 
% per subject, N ran from 1:4
% BCICOMP is in case it is desired to run the BCI Competition IV IIa
% data set. Then the trials needs to be changed and the subject is then
% labeled as A0NT.gdf and A0NE.gdf where N is the subject ID from 1 to 9
% and T means training set and E means evalution set.

DimReduct = '';
subject = '';
BCICOMP = 0;
trials = 20;

% Set the labels for down and up

labels = [zeros(trials,1) + 3 ; zeros(trials,1) + 4];

% Loading the filterbank data

fprintf('Loading filterbank data...\n');

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))
    load('filterbankdata_butter.mat','dfilt','ufilt');    
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
    load(append('filterbankdata_butter_',subject,'.mat'),'dfilt','ufilt');
end
    
fprintf('Loaded\n');

fprintf('Performing CSP...\n');

% Constructing the structure used in the computeCSP function

CSP_du.x = cat(3,dfilt,ufilt);
CSP_du.y = labels;

cd 'C:\Users\Mathi\Documents\DTU\Bachelor Project\MATLAB'

[du(:,:),~] = computeCSP(CSP_du,[3 4]);

% Saving the CSP data in the desired folder as a .mat file

fprintf('Saving CSP data for subject...\n');

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))
    save('csp_data.mat','du');
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
    save(append('csp_data_',subject,'.mat'),'du');
end

fprintf('Saved\n');