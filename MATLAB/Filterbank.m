%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This script Constructs a filterbank based on a      %
%                     given filter range for experiments conducted with   %
%                     the specifications outlined in the associated       %
%                     bachelors thesis.                                   %
%                                                                         %
% Additional used MATLAB packages / functions: BIOSIG toolbox             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

% Select desired type of dimensionality reduction - NONE, PCA or ICA.
% Write subject identifier; in our case the final experiment .gdf files 
% were labeled as SUBJECTID_ForsogN_Layout2.gdf. Where SUBJECTID is the id 
% of the subject and N is the experiment number, as we did 4 experiments 
% per subject, N ran from 1:4
% BCICOMP is in case it is desired to run the BCI Competition IV IIa
% data set. Then the sample rate trials and channel count needs to be 
% changed. The subject is then labeled as A0NT.gdf and A0NE.gdf where N is
% the subject ID from 1 to 9 and T means training set and E means 
% evalution set

DimReduct = '';
subject = '';
BCICOMP = 0;
sample_rate = 512;
duration = 4;
trials = 20;
testtrials = 80;
DR = 12;

% Construct empty matrices to reduce computing time if dimensionality
% reduction has been selected

if strcmpi(DimReduct,'PCA') || strcmpi(DimReduct,'ICA')
    DR = 6;
    
    DR_d = zeros(sample_rate*duration,DR,trials);
    DR_u = zeros(sample_rate*duration,DR,trials);
    DR_unk = zeros(sample_rate*duration,DR,trials);
end

cd 'C:\Users\Mathi\Documents\DTU\Bachelor Project\MATLAB\biosig'
biosig_installer

% Extract all test subject data and evaluation subject data for down and up
% cases
if BCICOMP == 0
    [~,~,temp11, temp12,~,~] = GDFload(append(subject,'_Forsog1_Layout2.gdf'),sample_rate,subject,0);
    [~,~,temp21, temp22,~,~] = GDFload(append(subject,'_Forsog2_Layout2.gdf'),sample_rate,subject,0);

    d = cat(3,temp11,temp21);
    u = cat(3,temp12,temp22);

    clear temp11 temp12 temp21 temp22

    [temp11, temp12, temp13] ...
        = GDFloadunk(append(subject,'_Test_set_Part1.mat'),sample_rate,subject,0);

    [temp21, temp22, temp23] ...
        = GDFloadunk(append(subject,'_Test_set_Part2.mat'),sample_rate,subject,0);

    unk = cat(3,temp11,temp21);
    before = cat(3,temp12,temp22);
    order = cat(1,temp13,temp23);

    clear temp11 temp12 temp13 temp21 temp22 temp23
else
    [l(:,:,:), r(:,:,:), d(:,:,:), u(:,:,:),~,~] ...
    = GDFload(append(subject,'T.gdf'),sample_rate,subject,1);

    [unk(:,:,:),~,order] = GDFloadunk(append(subject,'E.gdf'),sample_rate,subject,1);
end

clc

fprintf('All data extracted\n');

% Set all NaN data to 0 to allow for filtering

temp = d;
temp(isnan(temp)) = 0;
d = temp;

temp = u;
temp(isnan(temp)) = 0;
u = temp;

temp = unk;
temp(isnan(temp)) = 0;
unk = temp;

if BCICOMP == 0
    temp = before;
    temp(isnan(temp)) = 0;
    before = temp;
end

fprintf('All NaN data set to 0\n');

% PCA

if strcmpi(DimReduct,'PCA')
    sprintf('Doing PCA\n');
    for trial = 1:trials
        [~,new,~,~,~,~] = pca(d(:,:,trial));
        DR_d(:,:,trial) = new(:,1:6);

        [~,new,~,~,~,~] = pca(u(:,:,trial));
        DR_u(:,:,trial) = new(:,1:6);
    end
    for trial = 1:testtrials
        if BCICOMP == 0
            [~,new,~,~,~,~] = pca(unk(:,3:14,trial));
        else
            [~,new,~,~,~,~] = pca(unk(:,:,trial));
        end
        DR_unk(:,:,trial) = new(:,1:6);
    end
    fprintf('PCA completed\n');

% ICA

elseif strcmpi(DimReduct,'ICA')
    sprintf('Doing ICA\n');
    for trial = 1:trials
        DR_Mdl = rica(d(:,:,trial),6);
        DR_d(:,:,trial) = transform(DR_Mdl,d(:,:,trial));

        DR_Mdl = rica(u(:,:,trial),6);
        DR_u(:,:,trial) = transform(DR_Mdl,u(:,:,trial));
    end
    for trial = 1:testtrials
        if BCICOMP == 0
            DR_Mdl = rica(unk(:,3:14,trial),6);
        else
            DR_Mdl = rica(unk(:,:,trial),6);
        end
        DR_unk(:,:,trial) = transform(DR_Mdl,unk(:,:,trial));
    end
    fprintf('ICA completed\n');
end

% Construct Filterbank and empty matrices for the filtered data for faster
% computing

Filterbankfilter = [8 35];

dfilt = zeros(sample_rate*duration,DR,trials);
ufilt = zeros(sample_rate*duration,DR,trials);
if BCICOMP == 0
    unkfilt = zeros(sample_rate*duration,DR+2,testtrials);
else
    unkfilt = zeros(sample_rate*duration,DR,testtrials);
end
    
% Insert the first two channels in the test experiments directly into the
% filtered matrix as these channels contain EOG data which shouldn't be
% filtered or reduced via dimensionality reduction

if BCICOMP == 0
    for channel = 1:2
        for unktrial = 1:trials
            unkfilt(:,channel,unktrial) = unk(:,channel,unktrial);
        end
    end
end

% Construct Butterworth filter

[z,p,k] = butter(2,Filterbankfilter/(sample_rate/2));
[sos,g] = zp2sos(z,p,k);

% Apply the Butterworth filter to the data

for channel = 1:DR
    for trial = 1:trials
        if strcmpi(DimReduct,'NONE')
            dfilt(:,channel,trial) = filtfilt(sos,g,d(:,channel,trial));
            ufilt(:,channel,trial) = filtfilt(sos,g,u(:,channel,trial));
        else
            dfilt(:,channel,trial) = filtfilt(sos,g,DR_d(:,channel,trial));
            ufilt(:,channel,trial) = filtfilt(sos,g,DR_u(:,channel,trial));
        end
        
    end
    for unktrial = 1:testtrials
        if BCICOMP == 0
            if strcmpi(DimReduct,'NONE')
                unkfilt(:,channel+2,unktrial) = filtfilt(sos,g,unk(:,channel+2,unktrial));
            else
                unkfilt(:,channel+2,unktrial) = filtfilt(sos,g,DR_unk(:,channel,unktrial));
            end
        else
            if strcmpi(DimReduct,'NONE')
                unkfilt(:,channel,unktrial) = filtfilt(sos,g,unk(:,channel,unktrial));
            else
                unkfilt(:,channel,unktrial) = filtfilt(sos,g,DR_unk(:,channel,unktrial));
            end
        end
    end
end

fprintf('Finished filterbank\n');

% Saves the filterbank and other important information in a .mat format

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))
    save('filterbankdata_butter.mat','dfilt','ufilt','unkfilt','before','order','-v7.3');
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
    save(append('filterbankdata_butter_',subject,'.mat'),'dfilt','ufilt','unkfilt','order','-v7.3');
end

fprintf('Filterbank has been saved\n');
