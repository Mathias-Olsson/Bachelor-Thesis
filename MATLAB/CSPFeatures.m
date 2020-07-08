function f = CSPFeatures(P,data,m_range)
% CSPFeatures.m
% ------------------------------------
% Author: Mathias Sabroe Simonsen
% 10/06-2019

% This function feature extracts from an EEG signal with the CSP method

% The functions input loads the CSP matrix, EEG signal and the which filter
% columns to use.
% The functions output is the feature vector from the feature extraction

P = P';
f = (log10(diag((transpose(P(:,m_range)) * data) * (transpose(data) * P(:,m_range)))/...
    trace((transpose(P(:,m_range)) * data) * (transpose(data) * P(:,m_range)))))';
end