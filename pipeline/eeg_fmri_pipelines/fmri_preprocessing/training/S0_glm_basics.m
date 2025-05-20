%% Goal

% Step 1 - simulate neural activity
% Step 2 - simulate fMRI data - convolve with hrf
% Step 3 - add noise
% Step 4 - build a model 
% Step 5 - solve for beta

%% useful functions to try 

% pwd - get current working directory
% clear all - clear all variables in the workspace
% clc - clear command window
% close all - close all open figures
% others:
    %help/doc - type doc doc in command window to learn more
    %repmat
    %repelem
    %mod
    %conv
    %squeeze
    %flip
    %pinv
    %'
    %imagesc/imshow/plot/scatter/hist
    %randn
      
% given any variable 'val'
    % it is always good to check the following things:
        % size and dimension - size(vals)
            % size of the kth dimension - size(vals,k)
        % basic stats - min(vals), max(vals), mean(vals)
            % use vals(:) instead of vals to get the result across all the values in this variable regardless of dimensions
        % distribution - hist(vals)
    % always keep in mind:
        %  what each dimension of my variable means
        %  what does large and small number mean in my variable, what's the range
        
%% step 0 - come up with a fake design

%  let's say, 12 seconds onset with 12 seconds offset, repeat for 5 minutes.

%% step 1 - simulate neural activity
clear all; close all; clc;

expDuration = 288; % experiments lasts 1 minutes - 60 seconds
blockDuration = 12; % each block lasts 10 seconds 
myTime = 1:expDuration; % 1:300, every second of this duration


blockDesign  = repelem([1 0],1,blockDuration); % 10 1s and 10 0s
expDesign  = repmat(blockDesign,1,expDuration/blockDuration/2); % we repeat the blocks many times through out 1 minutes

% for now, this expDesign is as good of a guess to neural activity as we can 
% basically mean neuron spikes at onset of the stimulus
dataNeural = expDesign;

% let's visualize it
figure(1); clf;
plot(dataNeural,'LineWidth',2)
ylim([0,1.1])
ylabel('neural activity (a.u.)')
xlabel('time (secs)');
title('Eyes Open and Eyes Closed of neural activity')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2,'YTick',[0 0.5 1]);



    
%% step 2 -  simulate fMRI data - convolve with hrf

% Having the different conditions labeled as 1 and 0,
% having the different voxels, consider just one voxel
% this voxel has an HRF that can take a floating-number value, this value
% changes with time, it can become high at some point, or low at some
% point, we would like to study whether the changes in the HRF have a
% correlation with the conditions 0 and 1
% The idea is to compute a convolution between the condition function
% above, and the actual HRF from fMRI acquisition

% In this script, it is a dummy data, Putti is using the Gamma function
% 


% real fMRI data are sluggish and not like the sharp on/off shape for the expDesign
% this is because of the HRF (hemodynamic impulse response function)
% we can model it and add it to our neural activity

% there are fancy ways to generate, model, and estimate HRF
% for now,  we will use a budget version -  the gamma function

%% step 2.1 generate hrf 

% we have two knobs (parameters) to set:
tau = 2; % decides shape of the peak
delta =  5; % decides delay after stimulus onset


% make our budget HRF
timeHrf = 0:1:30; % we will get the hrf for 30 seconds
hrf = (max(timeHrf-delta,0)/tau).^2 .* exp(-max(timeHrf-delta,0)/tau) / (2*tau);

figure(2); clf;
plot(timeHrf,hrf,'LineWidth',2);
title('HRF')
ylabel('intensities (a.u.)')
xlabel('time (sec)')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2,'YTick',[0 0.5 1]);



%% step 2.2 generate fmri data 

% now let's transform our on/off neural activity to fmri data with the hrf

datafMRI =  conv(dataNeural,hrf);
% remind that the convolution operation basically computes the dot-product
% between the first function and the second one
datafMRI = datafMRI(1:length(dataNeural)); % chop off extra data generated from the function conv 

%

figure(3); clf;
plot(datafMRI,'LineWidth',2);
ylim([0,1.1])
title('fMRI signal')
ylabel('intensities (a.u.)')
xlabel('time (sec)')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2,'YTick',[0 0.5 1]);
 
%% step 2.3 add baseline and convert to percentage signal change

% some extra stuff: add a baseline for the fMRI signal and converting it to %signal change

datafMRI = 100 + conv(dataNeural,hrf); % 100 value added as a baseline
datafMRI = datafMRI(1:length(dataNeural)); % chop off extras
datafMRIpercent = 100 * ((datafMRI/(mean(datafMRI)) - 1)); % percentage signal change

figure(4); clf;
plot(datafMRIpercent,'Linewidth',2);

title('fMRI percentage signal change')
ylabel('signal change (%)')
xlabel('time (sec)')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2);
  
%% Step 3 - generate noise

% real data is quite noisy,  let's make some noise for our voxel

noise = 0.05 * randn(size(datafMRI)); % generate noise using randn
dataNoisy = datafMRI + noise; % add noise
dataNoisy = 100 * ((dataNoisy/(mean(dataNoisy)) - 1)); % convert to %signal change

% Plot it
figure(1); clf;
subplot(3,1,1)
plot(noise,'Linewidth',2)
title('noise')
ylabel('intensities (a.u.)')
xlabel('time (sec)')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2);

subplot(3,1,2)
plot(datafMRIpercent,'Linewidth',2);
ylim([-0.6 0.6])
title('fMRI data without noise')
ylabel('signal change (%)')
xlabel('time (sec)')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2);

subplot(3,1,3)
plot(dataNoisy,'Linewidth',2);
ylim([-0.6 0.6])
title('fMRI data with noise')
ylabel('signal change (%)')
xlabel('time (sec)')
set(gca,'FontSize',15,'TickDir','out','Linewidth',2);
% Note that each time you evaluate the above code, you get a somewhat
% different result because of the noise.

%% Step 4 - build a model 

% each column vector you put in the model serves as a regressor or predictor
% model has the size (time by number of regressors)

% first thing you put in should be your expDesign variable, 1s in onset and 0s in offset
% second one should be just 1s, if our experiment lasts 1 minute long, then we need 60 1s
% the third, fourth, and however many other columns can be anything you believe that contribute to the variance of your data
% most people include a linear drift as fMRI signals tends to get higher as time goes on, but you don't need to have it
% another common thing is the global signal and 6 motion regressors and their derivatives and squares, you get them from the fMRIPrep output in the confound file

model = [expDesign' ones(expDuration,1)];


%% Step 5 - solve for beta

% I advice you to look up that is happenning underneath the formula as the formula is very simple

b = pinv(model) * dataNoisy';

% b(1) is the beta weights for our design matrix :)

%% step 6 - try this

% simulate more voxels - can be hundreds, can be thousands
% try out different noise level 
% try to simulate a voxel that is inactive and doesn't care about the onset of the stimulus, what would their timecourse look like?
% try our different designs, try out event design
% ask me for more things to try
