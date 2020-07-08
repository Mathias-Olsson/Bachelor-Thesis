%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This script computes the EOG limits for a specific  %
%                     subject based on a training set. The EOG limits     %
%                     left and right are mulitplied by a subject specific %
%                     value to achieve the highest possible EOG accuracy  %
%                     for each test subject.                              %
%                                                                         %
% Additional used MATLAB packages / functions:                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

% Write subject identifier; in our case the final experiment .gdf files 
% were labeled as SUBJECTID_ForsogN_Layout2.gdf. Where SUBJECTID is the id 
% of the subject and N is the experiment number, as we did 4 experiments 
% per subject, N ran from 1:4

subject = '';
accuracies = zeros(1,2);
weightdistance = linspace(0.1,2,191);
weightaccuracy = zeros(length(weightdistance),2);

sample_rate = 512;

% Load all the data in

cd 'C:\Users\Mathi\Documents\DTU\Bachelor Project\MATLAB'

[left1,right1,~,~,beforeleft1,beforeright1] = GDFload(append(subject,'_Forsog1_Layout2.gdf'),sample_rate,subject,0);
[left2,right2,~,~,beforeleft2,beforeright2] = GDFload(append(subject,'_Forsog2_Layout2.gdf'),sample_rate,subject,0);

[unk1, before1] = GDFloadunk(append(subject,'_Test_set_Part1.mat'),sample_rate,subject,0);
[unk2, before2] = GDFloadunk(append(subject,'_Test_set_Part2.mat'),sample_rate,subject,0);

load(append(subject,'_Test_set_Part1'),'order');
order1 = order;

load(append(subject,'_Test_set_Part2'),'order');
order2 = order;

% Combines the seperated test sets

unk = cat(3,unk1,unk2);
before = cat(3,before1,before2);
order = cat(1,order1,order2);

% Sets all the EEG trial labels to one singular label as this is to train
% the EOG part of the classifier.

order(order == 3) = 0;
order(order == 4) = 0;

% Combines the seperated training sets

beforeleft = cat(3,beforeleft1,beforeleft2);
beforeright = cat(3,beforeright1,beforeright2);
left = cat(3,left1,left2);
right = cat(3,right1,right2);

% Construct empty matrices to reduce computing time

normalizingch1left = zeros(length(beforeleft(1,1,:)),1);
normalizingch2left = zeros(length(beforeleft(1,1,:)),1);

normalizingch1right = zeros(length(beforeleft(1,1,:)),1);
normalizingch2right = zeros(length(beforeleft(1,1,:)),1);

averagesleft = zeros(length(beforeleft(1,1,:)),1);
averagesright = zeros(length(beforeleft(1,1,:)),1);
guesses = zeros(length(beforeleft(1,1,:)),1);

correct = 0;
incorrect = 0;

% Calculates the difference between the normalized EOG channels based on
% the signal from before the trial began, where the subject stares straight
% into the monitor. This is done for all the left and right trials in the
% training set.

for i = 1:length(beforeleft(1,1,:))
    
    % Normalizing the trial signal based on the signal from before the
    % trial began
    
    normalizingch1left(i) = mean(beforeleft(:,1,i));
    normalizingch2left(i) = mean(beforeleft(:,2,i));

    normalizingch1right(i) = mean(beforeright(:,1,i));
    normalizingch2right(i) = mean(beforeright(:,2,i));

    normalizedch1left = left(sample_rate*1.5:sample_rate*2.5,1,i) - normalizingch1left(i);
    normalizedch2left = left(sample_rate*1.5:sample_rate*2.5,2,i) - normalizingch2left(i);

    normalizedch1right = right(sample_rate*1.5:sample_rate*2.5,1,i) - normalizingch1right(i);
    normalizedch2right = right(sample_rate*1.5:sample_rate*2.5,2,i) - normalizingch2right(i);
    
    % Calculates the difference between the two EOG channels 1 and 2 for
    % each trial
    
    differenceleft = normalizedch1left - normalizedch2left;

    differenceright = normalizedch1right - normalizedch2right;
    
    % Calculates the mean difference across the selected time period during
    % the trial
    
    averagesleft(i) = mean(differenceleft);
    averagesright(i) = mean(differenceright);
end

% The normalized values used for online classification

normalizech1 = mean(cat(1,normalizingch1left,normalizingch1right));
normalizech2 = mean(cat(1,normalizingch2left,normalizingch2right));

% Sets the EOG limits as the mean across all the different left and right
% trials

leftlimit = mean(averagesleft);
rightlimit = mean(averagesright);

count = 1;

% Computes the optimal multiplier by finding the accuracy in every 
% multiplier case from 0.1 to 2 with a step distance of 0.01

for j = weightdistance
    scale = j;
    delta = zeros(80,1);
    correct = 0;
    incorrect = 0;

    for i = 1:80
        
        % Normalize the signal
        
        normalizingch1 = mean(before(:,1,i));
        normalizingch2 = mean(before(:,2,i));

        normalizedch1 = unk(:,1,i) - normalizingch1;
        normalizedch2 = unk(:,2,i) - normalizingch2;
        
        % Calculate the difference between the normalized channels
        
        difference = normalizedch1 - normalizedch2;

        delta(i) = mean(difference);
        
        % EOG classifier
        
        if delta(i) > leftlimit*scale 
            guesses(i) = 1; % Classifies the EOG trial as left
        elseif delta(i) < rightlimit*scale 
            guesses(i) = 2; % Classifier the EOG trial as right
        else
            % If the trial isn't deemed as an EOG trial, it is simply given
            % the label 0 denoting it as an EEG trial
            guesses(i) = 0;
        end
        
        % Accuracy counter
        
        if guesses(i) == order(i)
            correct = correct + 1;
        else
            incorrect = incorrect + 1;
        end
    end

    accuracy = correct/(correct + incorrect)*100;

    weightaccuracy(count,1) = j;
    weightaccuracy(count,2) = accuracy;
    fprintf('%s\n',subject);
    fprintf(sprintf('Multiplier: %d\n',j));
    fprintf(sprintf('Correct guesses: %d\n',correct));
    fprintf(sprintf('Incorrect guesses: %d\n',incorrect));
    fprintf(sprintf('Accuracy: %.15g\n',accuracy));

    count = count + 1;
end

% Calculates the longest continious chain of highest accuracies if multiple
% multipliers give the same highest accuracy and sets the final multiplier
% as the mean of these multipliers having the same accuracy

maximum = weightaccuracy(:,2) == max(weightaccuracy(:,2));

dist = 0;
startpos = 0;
tempstart = 0;
temp = 0;
for i = 1:length(weightdistance)
    if (maximum(i) == 1) && (temp == 0)
        tempstart = i;
        temp = temp + 1;
    elseif (maximum(i) == 1) && (temp > 0)
        temp = temp + 1;
    elseif (maximum(i) == 0) && (temp > 0)
        if dist < temp
            dist = temp - 1;
            startpos = tempstart;
            temp = 0;
            tempstart = 0;
        end
    else
        temp = 0;
        tempstart = 0;
    end
end
    
optimalmultiplier = mean(weightdistance(startpos:startpos+dist));

% Save the personalizes EOG limits in a .mat file

save('optimalEOG','optimalmultiplier','leftlimit','rightlimit','normalizech1','normalizech2');
accuracies(2) = max(weightaccuracy(:,2));
accuracies(1) = optimalmultiplier;



