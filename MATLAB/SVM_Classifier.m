%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Mathias Dizon Olsson and Simon Dahl Thorsager Olesen            %
% Final revision date: 08/07/2020                                         %
%                                                                         %
% Script information: This script classifies the test experiments by SVM  %
%                     classifier, utilizing the filterbank data from the  %
%                     Filterbank.m script, csp data from the              %
%                     FilterbankCSP.m script and EOG data from the        %
%                     EOGAccuracy.m script                                %
%                                                                         %
% Additional used MATLAB packages / functions: CSPFeatures by             %
%                                                 Mathias Sabroe Simonsen %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

% Select desired type of dimensionality reduction - NONE, PCA or ICA.
% Write subject identifier; in our case the final experiment .gdf files were
% labeled as SUBJECTID_ForsogN_Layout2.gdf. Where SUBJECTID is the id of
% the subject and N is the experiment number, as we did 4 experiments per
% subject, N ran from 1:4
% Choose kernel - linear, rbf, gaussian, polynomial
% BCICOMP is in case it is desired to run the BCI Competition IV IIa
% data set. Then the sample rate trials and channel count needs to be 
% changed. The subject is then labeled as A0NT.gdf and A0NE.gdf where N is
% the subject ID from 1 to 9 and T means training set and E means 
% evalution set

DimReduct = '';
subject = '';
kernel = '';
BCICOMP = 0;
trials = 20;
testtrials = 80;

% Amount of features depending on if Dimensionality Reduction is enabled or
% not

if strcmpi(DimReduct,'NONE')
    if BCICOMP == 0
        mDR = 12;
    else
        mDR = 22;
    end
else
    mDR = 6;
end
     
% Construct empty matrices to reduce computing time

accuracy = zeros(mDR/2,1);
cohens = zeros(mDR/2,1);

% Loading data

fprintf('Loading data\n');

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject))

    load('csp_data','du');
    load('filterbankdata_butter.mat','dfilt','ufilt','unkfilt','before','order');
    load('optimalEOG','optimalmultiplier','leftlimit','rightlimit');
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
    
    load(append('csp_data_',subject,'.mat'),'du');
    load(append('filterbankdata_butter_',subject,'.mat'),'dfilt','ufilt','unkfilt','order');
end

cd 'C:\Users\Mathi\Documents\DTU\Bachelor Project\MATLAB'

dfilt = permute(dfilt,[2 1 3 4]);
ufilt = permute(ufilt,[2 1 3 4]);

unkEval = permute(unkfilt,[2 1 3 4]);
        
for m = 1:(mDR/2)
    
    % set the feature range
    
    m_range = [1:m ((mDR+1)-m):mDR];
    
    % Feature extract for each trial
    
    for trial = 1:trials
                    
        X_down = dfilt(:,:,trial);
        X_up = ufilt(:,:,trial);
  
        fextract_utrain_du(trial,(1:m*2)+((m-m)*2)) = CSPFeatures(du(:,:),X_up,m_range);
        fextract_dtrain_du(trial,(1:m*2)+((m-m)*2)) = CSPFeatures(du(:,:),X_down,m_range);

    end
    
    features_du = [fextract_dtrain_du;fextract_utrain_du];

    % Construct labels
    
    Y_down = zeros(trials,1) + 3; 
    Y_up = zeros(trials,1) + 4;

    Y_du = [Y_down; Y_up];

    prediction = zeros(testtrials,1);
    
    % Train SVM model on features from training set
    
    SVM_du = fitcsvm(features_du,Y_du,'KernelFunction',kernel,'Standardize',false,'KernelScale','auto');
    ProbSVM_du = fitPosterior(SVM_du, features_du, Y_du);

    correct = 0;
    incorrect = 0;
    
    % Classify each test trial individually
    
    for trial = 1:testtrials
        
        % Normalize channel 1 and 2 to check for EOG
        if BCICOMP == 0
            normalizingch1 = mean(before(:,1,trial));
            normalizingch2 = mean(before(:,2,trial));

            normalizedch1 = unkEval(1,:,trial) - normalizingch1;
            normalizedch2 = unkEval(2,:,trial) - normalizingch2;

            difference = normalizedch1 - normalizedch2;
        
        % Classify as EOG or EEG depending on if the difference between the
        % normalized channels exceed the subject specific limits
        
            if mean(difference) > leftlimit*optimalmultiplier
                prediction(trial) = 1; 
            elseif mean(difference) < rightlimit*optimalmultiplier
                prediction(trial) = 2;
            else % Classify by the trained SVM model if the trial is regarded as EEG
                fextract_test_du = CSPFeatures(du(:,:),unkEval(3:mDR+2,:,trial),m_range);

                [label_du, score_du] = predict(ProbSVM_du,fextract_test_du);

                downProb = score_du(1);
                upProb = score_du(2);

                [~,prediction(trial)] = max([downProb, upProb]);
                prediction(trial) = prediction(trial) + 2;
            end
        else
            fextract_test_du = CSPFeatures(du(:,:),unkEval(1:mDR,:,trial),m_range);

            [label_du, score_du] = predict(ProbSVM_du,fextract_test_du);

            downProb = score_du(1);
            upProb = score_du(2);

            [~,prediction(trial)] = max([downProb, upProb]);
            prediction(trial) = prediction(trial) + 2;
        end
        
        % Check the predictions against the actual order of the test set
        
        if prediction(trial) == order(trial)
            correct = correct + 1;
        else
            incorrect = incorrect + 1;
        end
    end
    
    % Compute the accuracy of the EEG / EOG classifier
    
    accuracy(m) = correct/(correct + incorrect);
    
    % Compute the Cohen's Kappa coefficient
    if BCICOMP == 0
        chanceagree1 = sum(order == 1)/(length(order)) * sum(prediction == 1)/(length(order));
        chanceagree2 = sum(order == 2)/(length(order)) * sum(prediction == 2)/(length(order));
        chanceagree3 = sum(order == 3)/(length(order)) * sum(prediction == 3)/(length(order));
        chanceagree4 = sum(order == 4)/(length(order)) * sum(prediction == 4)/(length(order));

        chanceagree = chanceagree1 + chanceagree2 + chanceagree3 + chanceagree4;
    else
        chanceagree3 = sum(order == 3)/(length(order)) * sum(prediction == 3)/(length(order));
        chanceagree4 = sum(order == 4)/(length(order)) * sum(prediction == 4)/(length(order));
        
        chanceagree = chanceagree3 + chanceagree4;
    end
    cohens(m) = (accuracy(m) - chanceagree) / (1 - chanceagree);
    
    fprintf('Done\n');
end

% Saving the accuracies and Cohen's Kappa coefficients

fprintf('Saving accuracies...\n');

if BCICOMP == 0
    cd(append('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\',subject,'\SVM'))
    save(sprintf('AccuracyandCohens.mat'),'accuracy','cohens');
else
    cd('C:\Users\Mathi\Documents\DTU\Bachelor Project\Experiments\BCICOMP')
    save(append('AccuracyandCohens_',subject,'.mat'),'accuracy','cohens');
end

fprintf('Finished saving\n');