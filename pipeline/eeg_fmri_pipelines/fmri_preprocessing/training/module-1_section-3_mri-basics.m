%% Goal

% Step 1 - load and view a structure file 
% Step 2 - load and view a functional file 
% Step 3 - load and view various other files under the BIDS directory

%% useful functions to try 

% pwd - get current working directory
% clear all - clear all variables in the workspace
% clc - clear command window
% close all - close all open figures

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

        
%%       
%% step 1.0 - find and load structure scan t1
clear all; clc;

% path to the target file
t1wPath = '/Volumes/MS_osama/hadiBIDS/fingerBIDS/rawdata/sub-0665/ses-01/anat/sub-0665_ses-01_T1w.nii.gz';

% load the file with niftiread 
t1w = niftiread(t1wPath);
%% step 1.1 - Let's visualize the structure scan t1
close all;

% check the size of the file we just loaded
size(t1w)

% pick a slice along the x dimension
sliceX = 100; 

% get the data for this slice
vals1 = t1w(sliceX,:,:); 

% check the size
size(vals1) 

% we need a 2D matrix to visualize as an image, let't squeeze it to get to
% the correct dimension
vals2 = squeeze(vals1);

% check the size of vals2
size(vals2)

% Now let's plot it
% open figure one
figure(1); 
% visualize this slice of the brain as a 2D image using imagesc
imagesc(vals2)

% does it look strange?

%% step 1.2 Let's do it again (new and improved)

% pick the slice;
sliceX = 100;

% get the data properly:
% get data with vals = t1w(sliceX,:,:)
% get correct dimension through vals = squeeze(vals)
% flip x and y throught transpose vals = vals'
% flip upside down using vals = flip(vals)
% do it in one step

vals = flip(squeeze(t1w(sliceX,:,:))');
% verify size
size(vals)

% open figure 
figure(1);clf % use 'clf' to clear the current content if it has already been open

imagesc(vals) % visualize the image

title(['x slice ' num2str(sliceX)]) % display the current slice number as the title
colormap(gray) % set to gray scale as color doesn't provide useful information in this case
axis image % since voxel is cube, the pixels along each dimension has equal size

%% step 1.3 Repeat the same for the Y and Z dimension

% pick a slice from Y and Z dimension
sliceY = 100;
sliceZ = 100;

% visualize Y slice in figure two
figure(2);clf

imagesc(flip(squeeze(t1w(:,sliceY,:))'))

title(['y slice ' num2str(sliceY)])
colormap(gray)
axis image

% visualize Z slice in figure three
figure(3);clf

imagesc(flip(squeeze(t1w(:,:,sliceZ))'))

title(['z slice ' num2str(sliceZ)])
colormap(gray)
axis image

%% step 1.4 Loop through and draw every single slice along the X dimension

% open figure one
figure(1);clf

for sliceX = 1:size(t1w,1) % loop through every X slices
    
imagesc(flip(squeeze(t1w(sliceX,:,:))'))

title(['x slice ' num2str(sliceX)])
colormap(gray)
axis image
drawnow

end


%% step 1.5 Now try to do the same thing through the Y and Z dimension


figure(2);




figure(3);


%%
%% step 2.0  - find and load functional scan bold.nii.gz

% path to the target file
funcPath = '/Volumes/MS_osama/hadiBIDS/fingerBIDS/derivatives/fmriprep/sub-0665/ses-01/func/sub-0665_ses-01_task-fingertapping_dir-AP_run-01_space-T1w_desc-preproc_bold.nii.gz';

% load the file with niftiread 
func = niftiread(funcPath);

%% step 2.1 - check the data

% what is the size and dimension of my data?
size(func)

% what does each dimension mean?

%% step 2.2 - visualize a single slice at a single timepoint

% pick a slice in the Z dimension (meaning this is an x-y image)
sliceZ = 40;
% pick a time point 
sliceT = 1;

figure(1);clf

imagesc(flip(squeeze(func(:,:,sliceZ,sliceT))'))
title(['z slice ' num2str(sliceZ)])
colormap(gray)
axis image

%% step 2.3 - loop through a single slice across time

% pick a slice in the Z dimension (meaning this is an x-y image)
sliceZ = 38;


figure(1);clf

for sliceT = 1:size(func,4)
imagesc(flip(squeeze(func(:,:,sliceZ,sliceT))'))
title(['z slice ' num2str(sliceZ)])
colormap(gray)
axis image
drawnow
end

%% step 2.4 - plot data of a single voxel across time

% define the x,y,z of the chosen voxel
% keep in mind the range of these values - check with size(func)

sliceX = 62;
sliceY = 44;
sliceZ = 38;

% check how many time points do we have
nTime = size(func,4);
% get values to be plotted on the x and y axes
xVals = 1:nTime; % x-axis will be time
yVals = squeeze(func(sliceX,sliceY,sliceZ,:)); % y-axis will be raw image intensity

figure(1);clf
plot(xVals,yVals)

xlabel('Time (TR)')
ylabel('Raw Image Intensities (a.u.)')
title(['Raw timeseries data of voxel ' num2str([sliceX sliceY sliceZ])])

%% step 2.5 - try to load multiple voxels' data on top of each other

figure(1); clf; hold on;



%% step 3 - others

% when loading other file types make sure you have the correct path added 

% gifti (files end with .gii)
% ~/Documents/GitHub/gifti/@gifti/gifti.m
% gifti(filePath)

% mgz/mgh 
% /Applications/freesurfer/7.2.0/matlab/MRIread.m
% MRIread(filePath)

% annot/label 
% ~/Documents/GitHub/cvncode/cvnroimask.m
% see doc cvnroimask