function[CSPMatrix,covMatrices] = computeCSP(EEGdata,labels)
% computeCSP computes Common Spatial Patterns for EEG signals
%      This version handles 2 class data only!
%      Note: The normalized covariance is used i.e. the correlation
%
% INPUT:
%       EEGdata:    structure where:
%                   - EEGdata.x is [Ns x Nchann x nT] array where n_chann is the number of 
%                    channels of the EEG data, Ns is the number of samples 
%                    per trials and nT is the number of trials
%                   - EEGdata.y is a [nT x 1] array with labels of each
%                   trial (+1 for positive class and -1 for negative class,
%                   or however labels have been defined)
%                   - EEGdata.s is the sampling rate
%       labels:     [-1,1], or however the class labels have been defined
%
% OUTPUT:
%       CSPMatrix:  [n_chann x n_chann] array where the CSP weights are 
%                   row vectors
%       covMatrices: cell(2,1) where each entry is the normalized covariance
%                    matrix (correlation) of the respective class
%
% REFERENCES:
% [1] Ramoser, 1998
% [2] Blakertz, 2008
% [3] Lotte, 2010
%
% Last edited by Ana Palma 24/03/2017
% ----------------------------------------------------------------------------

% Initialize
data=EEGdata.x;
labs=EEGdata.y;
n_chann = size(data,2);
nT = size(data,3);
n_classes = length(labels);
covMatrices = cell(n_classes ,1); %the covariance matrices for each class

% Compute normalized covariance matrices for each trial
trialCov = zeros(n_chann,n_chann,nT);
for t = 1 : nT
    trial = data(:,:,t)';
    trialCov(:,:,t) =  trial * trial' ./trace( trial * trial');
end
clear trial

% Computing covariance matrix for each class
for c = 1 : n_classes
    covMatrices{c} = mean(trialCov(:,:,labs == labels(c)),3);
end

% Compute total covariance matrix
covTotal = covMatrices{1} + covMatrices{2};

% Do whitening transform of total covariance matrix
[Ut,Dt] = eig(covTotal);
eigvals = diag(Dt);
% The eigenvalues are initially in creasing order so we need to invert
% them:
[eigvals,egIndex] = sort(eigvals,'descend');
Ut = Ut(:,egIndex);
P = diag(sqrt(1./eigvals)) * Ut';

% Transforme covariance matrix of first class using P
transformedCov1 =  P * covMatrices{1} * P';

% Eigenvalue Decomposition (EVD) of the transformed covariance matrix
[U1,D1] = eig(transformedCov1);
eigvals = diag(D1);
[~,egIndex] = sort(eigvals,'descend');
U1 = U1(:, egIndex);
CSPMatrix = U1' * P;
end