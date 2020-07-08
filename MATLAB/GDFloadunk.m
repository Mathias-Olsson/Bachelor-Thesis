%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function load in all the trials and the signal %
%                     before the unknown trials from either a .gdf file   %
%                     or a .mat file                                      %
%                                                                         %
% Additional used MATLAB packages / functions: BIOSIG toolbox             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [unk, before, order] = GDFloadunk(filename,sample_rate,subject,BCICOMP)

% BCICOMP is in case it is desired to run the BCI Competition IV IIa
% data set.

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
end

% Loads differently depending on if the unknown file is a .gdf file or a
% .mat file utilizing the BIOSIG toolbox function sload.m if the file is a 
% .gdf file

if strcmpi(filename(end-2:end),'gdf')
    [s, h] = sload(filename,'SampleRate',sample_rate);
elseif strcmpi(filename(end-2:end),'mat')
    load(filename,'s','h','order');
end

unk_id = 783; % OpenViBE stimulation IDs 
                         % 783: Unknown
                         
% Duration of the motor imagery task in captured data points based on the 
% 512 hz capture rate (4 seconds = 2048 measurements at 512 hz)
duration = sample_rate*4; 

% The offset from the Cue until the motor imagery task began 
% (1.5 second = 768 measurements at 512 hz)
offset = sample_rate*1.5; 

% Delete the data from channel 6 and 12 as the electrodes on these channels
% weren't connected
if BCICOMP == 0
    s(:,6:6:12) = [];

    % Create empty output matrices to reduce computing time

    output = zeros(duration,14,sum(h.EVENT.TYP == 783));
    outputbefore = zeros(offset,2,sum(h.EVENT.TYP == 783));

    % Save the trial data from the data file (s) based on the information
    % given in the header (h)

    index = find(h.EVENT.TYP == unk_id);
    position = h.EVENT.POS(index) + offset;
    beforeposition = h.EVENT.POS(index) - offset;

    for i = 1:length(index)
        output(:,:,i) = s(position(i):(position(i) + duration - 1), 1:14);
        outputbefore(:,:,i) = s(beforeposition(i):(beforeposition(i) + offset - 1), 1:2);
    end

    % Construct the final matrices that the function returns

    unk = output(:,:,:);
    before = outputbefore(:,:,:);
else
    output(duration,1:22,72) = zeros;

    index = find(h.EVENT.TYP == unk_id);
    position = h.EVENT.POS(index) + offset;

    for j = 1:length(index)
        output(:,:,1*j) = s(position(1*j):(position(1*j) + duration - 1), 1:22);
    end

    load(append(subject,'E.mat'),'classlabel');
    order = classlabel;
    
    unk = output(:,:,:);
    unk(:,:,(order == 1 | order == 2)) = [];
    order(order == 1 | order == 2) = [];
    before = 0;
    
    
    
    
end
end