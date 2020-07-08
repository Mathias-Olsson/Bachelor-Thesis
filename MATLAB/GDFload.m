%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This function load in all the trials and the signal %
%                     before the left trials and before the right trials  %
%                     from a .gdf file                                    %
%                                                                         %
% Additional used MATLAB packages / functions: BIOSIG toolbox             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [left,right,down,up,beforeleft,beforeright] = GDFload(filename,sample_rate,subject,BCICOMP)

% BCICOMP is in case it is desired to run the BCI Competition IV IIa
% data set.

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
end

% Loads the .gdf file in using the BIOSIG toolbox function sload.m

[s, h] = sload(filename,'SampleRate',sample_rate);

if BCICOMP == 0
    ids = [769,770,774,780]; % OpenViBE stimulation IDs 
                             % 1#: Left 2#: Right 3#: Down 4#: Up
else
    ids = [769,770,771,772];
end

% Duration of the motor imagery task in captured data points based on the 
% 512 hz capture rate (4 seconds = 2048 measurements at 512 hz)
duration = sample_rate*4; 

% The offset from the Cue until the motor imagery task began 
% (1.5 second = 768 measurements at 512 hz)
offset = sample_rate*1.5; 

% Delete the data from channel 6 and 12 as the electrodes on these channels
% weren't connected

% For our experiments
if BCICOMP == 0
    s(:,6:6:12) = []; 

    % Create empty output matrices to reduce computing time

    outputEEG = zeros(duration,12,sum(h.EVENT.TYP == ids(3)),2);
    outputEOG = zeros(duration,2,sum(h.EVENT.TYP == ids(1)),2);
    outputBefore = zeros(duration,2,sum(h.EVENT.TYP == ids(1)),2);

    % Save the EOG and EEG trial data from the data file (s) based on the 
    % information given in the header (h)

    for i = 1:2
        typeEEG = ids(i+2);
        typeEOG = ids(i);
        indexEEG = find(h.EVENT.TYP == typeEEG);
        indexEOG = find(h.EVENT.TYP == typeEOG);
        positionEEG = h.EVENT.POS(indexEEG) + offset;
        positionEOG = h.EVENT.POS(indexEOG) + offset;
        positionBefore = h.EVENT.POS(indexEOG) - sample_rate*2;

        for j = 1:length(indexEOG)
            outputEEG(:,:,1*j,i) = s(positionEEG(1*j):(positionEEG(1*j) + duration - 1), 3:14);
            outputEOG(:,:,1*j,i) = s(positionEOG(1*j):(positionEOG(1*j) + duration - 1), 1:2);
            outputBefore(:,:,1*j,i) = s(positionBefore(1*j):(positionBefore(1*j) + duration - 1), 1:2);
        end
    end

    % Construct the final matrices that the function returns

    left = outputEOG(:,:,:,1);
    right = outputEOG(:,:,:,2);
    down = outputEEG(:,:,:,1);
    up = outputEEG(:,:,:,2);

    beforeleft = outputBefore(:,:,:,1);
    beforeright = outputBefore(:,:,:,2);
else
    output(duration,1:22,72,1:4) = zeros;

    for i = 1:4
        type = ids(i);
        index = find(h.EVENT.TYP == type);
        position = h.EVENT.POS(index) + offset;

        for j = 1:length(index)
            output(:,:,1*j,i) = s(position(1*j):(position(1*j) + duration - 1), 1:22);
        end
    end

    left = output(:,:,:,1);
    right = output(:,:,:,2);
    down = output(:,:,:,3);
    up = output(:,:,:,4);
    beforeleft = 0;
    beforeright = 0;
end

end