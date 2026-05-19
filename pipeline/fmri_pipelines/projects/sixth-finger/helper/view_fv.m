function freeview_cmd = view_fv(whichSub, bidsDir, varargin)

% view overlay ontop of inflated surface in freeview

% whichSub - e.g. 'sub-0248' or '0248' or 'wlsubj124' - subject ID
% bidsDir - e.g. '/Volumes/Vision/MRI/recon-bank' - BIDS directory
% (hemi) - e.g. - 'l' - optional, if not defined then we will plot both hemisphere
% varargin - e.g. 'maps/motion:rainbow' - 'subfolderName/mgzFileName:colorMapName' - look for matching files only in the defined subfolder within derivatives
%          - e.g. 'motion:rainbow' - 'mgzFileName:colorMapName' - look for matching files across all subfolders in the derivatives directory
%          - e.g. 'motion' - no colormap
%          - e.g. 'prfvista_mov/ses-03/eccen' - 'subfolderName/session/mgzFileName'
%          The only non-optional input is the mgz name, i.e. eccen
%          The subfolder, session folder, and colormap are optional.

% example usage:
% whichSub = 'sub-0248'
% bidsDir = '/Volumes/Vision/MRI/recon-bank';
% view_fv(subject, bidsDir, 'lh', 'mt+2', 'motion_base/cw:rainbow','prfvista_mov/ses-03/eccen');

derivDir = [bidsDir '/derivatives'];
subject = [];
%% check if BIDS derivatives directory exsits
if ~exist(derivDir,'dir')
    error(['BIDS derivatives directory does not exist <' derivDir '>'])
end
if contains(derivDir,'~') 
    derivDir = strrep(derivDir, '~', getenv('HOME')); % somehow colormaps cannot be find when using ~
end
%% check if subject directory exsits

if ismember(whichSub,{'fsaverage','fsaverage6'}) % if it's fsaverage space no need to find subject folder
    subfolderName = whichSub;
    subject{1} = whichSub;
    subject{2} = 'NA';
else % if it's native use subject ID as folder
    if ~contains(whichSub, 'sub-')
    else
        tmp = strsplit(whichSub, '-');
        whichSub = tmp{2};
    end
    % if subject has more than one ID, define here so we will find overlays under any of the names.
    if ismember(whichSub,{'0392','wlsubj123'})
        subject = {'sub-0392','sub-wlsubj123'};
    elseif ismember(whichSub,{'0248','wlsubj124'})
        subject = {'sub-0248','sub-wlsubj124'};
    else
        subject{1} = ['sub-' whichSub];
        subject{2} = 'NA';
    end
    subfolder = dir(sprintf('%s/freesurfer/*%s*',derivDir,subject{1})); % in freesurfer folder check for any subject folder matches our subject ID
    if isempty(subfolder)
            subfolder = dir(sprintf('%s/freesurfer/*%s*',derivDir,subject{2})); % check the second name if we can't find a subject folder under first name   
    end
    subfolderName = subfolder([subfolder.isdir]).name; % get the folder name
end

subjectDir = sprintf('%s/freesurfer/%s',derivDir,subfolderName); % build the path for subject directory
if ~exist(subjectDir,'dir') % check if this subject directory exists
    error(['subject freesurfer directory for <' subject '> does not exist: <' subjectDir '>'])
end

%% check if freeview exsits
tmpDir = dir(fullfile('/Applications/freesurfer/*'));
fsPattern = '^\d+\.\d+\.\d+$'; % e.g. 6.2.0
for ii = 1:length(tmpDir)
    if  ~isempty(regexp(tmpDir(ii).name, fsPattern, 'once'))
        fvDir = [tmpDir(ii).folder '/' tmpDir(ii).name];
        setenv('FREESURFER_HOME', fvDir); 
        fvCmd = [fvDir '/bin/freeview'];
    end
end
setenv('SUBJECTS_DIR', [derivDir '/freesurfer']);

%% check which hemisphere to plot
if ismember(lower(varargin{1}), {'l','lh','left'})
    hemi = {'l'};
    varargin = varargin(2:end);
elseif ismember(lower(varargin{1}), {'r','rh','right'})
    hemi = {'r'};
    varargin = varargin(2:end);
else
    hemi = {'l','r'};
end
%% loop through each hemisphere
cmd = [];
for whichHemi = 1:numel(hemi)

    % find the inflated surface
    inflated = sprintf('%s/surf/%sh.inflated',subjectDir,hemi{whichHemi});
    %inflated = sprintf('%s/surf/%sh.sphere',subjectDir,hemi{whichHemi});
    %inflated = sprintf('%s/surf/%sh.white',subjectDir,hemi{whichHemi});
    %inflated = sprintf('%s/surf/%sh.midthickness',subjectDir,hemi{whichHemi});
    %inflated = sprintf('%s/surf/%sh.pial',subjectDir,hemi{whichHemi});

    % check if the inflated surf file exists
    if ~exist(inflated,'file')
        error(['<' hemi{whichHemi} 'h.inflate> not found in <' subjectDir '/surf>']);
    end

    % loop through each overlay name provided in varargin
    overlayCmd = ''; % prepare the command for overlay
    for whichOverlay = 1:length(varargin)
        % parse the input to get the folder, overlay, and colormap name
        [folder, fileParts] = parse_input(varargin{whichOverlay},derivDir,subject,hemi{whichHemi});
        overlayName = fileParts{3};
        colormapName = fileParts{4}; % rename it so we don't forget what this fileParts variable is
        for whichFolder = 1:numel(folder)
            whereOverlay = sprintf('%s/%sh.%s.mgz', folder{whichFolder}, hemi{whichHemi}, overlayName);
            %overlayCmd = [overlayCmd, sprintf(':overlay=%s', whereOverlay)];
            overlayCmd = [overlayCmd, sprintf(':overlay=%s:overlay_color=colorwheel,inverse:overlay_threshold=95,99,percentile:overlay_smooth=5', whereOverlay)];

            % add the customized color map if we have one
            overlayCmd = custom_colormap(derivDir,overlayName,colormapName,overlayCmd,hemi{whichHemi});
        end
    end
    if isempty(overlayCmd)
        warning(['none of the overlay files are found for ' hemi{whichHemi} 'h hemi'])
    end
    cmd = sprintf('%s -f %s%s', cmd, inflated, overlayCmd);

    % Legacy ROI labels (MT, MST, FST, Glasser2016) - not used in sixthfinger project
    % if ismember(whichSub,{'fsaverage','fsaverage6'})
    %     fstlabel = sprintf('%s/label/Glasser2016/%sh.Glasser2016.157.label', subjectDir,hemi{whichHemi});
    %     mstlabel = sprintf('%s/label/Glasser2016/%sh.Glasser2016.2.label', subjectDir,hemi{whichHemi});
    %     mtlabel = sprintf('%s/label/Glasser2016/%sh.Glasser2016.23.label', subjectDir,hemi{whichHemi});
    %     cmd = sprintf('%s -f %s%s:label=%s:label_outline=1:label_color=black:label_opacity=1:label=%s:label_outline=1:label_color=blue:label_opacity=1:label=%s:label_outline=1:label_color=green:label_opacity=1',cmd,inflated,overlayCmd,mtlabel,mstlabel,fstlabel);
    % else
    %     fstlabel = sprintf('%s/label/0localizer/%sh.FST.label', subjectDir,hemi{whichHemi});
    %     mstlabel = sprintf('%s/label/retinotopy_RE/%sh.pMST_REmanual.label', subjectDir,hemi{whichHemi});
    %     mtlabel = sprintf('%s/label/retinotopy_RE/%sh.pMT_REmanual.label', subjectDir,hemi{whichHemi});
    %     mtlabel2 = sprintf('%s/label/0localizer/%sh.func2D.label', subjectDir,hemi{whichHemi});
    %     cmd = sprintf('%s -f %s%s:label=%s:label_outline=1:label_color=black:label_opacity=1:label=%s:label_outline=1:label_color=blue:label_opacity=1:label=%s:label_outline=1:label_color=black:label_opacity=1:label=%s:label_outline=1:label_color=white:label_opacity=1',cmd,inflated,overlayCmd,mtlabel,mstlabel,fstlabel,mtlabel2);
    % end

    % % check if we have a camera saved
    mycam = fullfile(derivDir,'freesurfer',[hemi{whichHemi} 'h.camera.txt']);
    if isfile(mycam)
        mycam = fread(fopen(mycam, 'rt'), '*char')';
        cmd = sprintf('%s %s',cmd, mycam);
    else
    end



end



freeview_cmd = sprintf('%s%s &',fvCmd, cmd);
system(freeview_cmd);

end

%% sub functions
%% which folders are my overlay files in
function [folder, fileParts] = parse_input(whichFile,derivDir,subject,iHemi)

    % create temp variable fileParts that is {whichFolder} {whichOverlay} {whichColormap} {whichHemi}
    fileParts = regexp(whichFile, '[:/]', 'split'); % if folder and colormap are specified
    if count(whichFile, '/') == 1 % yes folder no session
        fileParts = [fileParts(1) '**' fileParts(2:end)];
    elseif  count(whichFile, '/') == 0 % no folder no session
        fileParts = ['**' '**' fileParts];
    end
    if ~contains(whichFile,':') % if colormap is not specified
        fileParts = [fileParts 'NA'];
    end

    fileParts = [fileParts iHemi]; % which hemi
    folder = {};
    for iSub = 1:numel(subject) % if sub has more than one name we check across all of them
        tmpFolder = find_my_files(subject{iSub},derivDir,fileParts); % look for the overlay files
        if isfolder(tmpFolder)
            folder = [folder tmpFolder];
        end
    end

    if isempty(folder)
        warning(['<' iHemi 'h.' fileParts{3} '.mgz> not found in any subfolders for this subject']);
        warning(['skipping ' fileParts{3} ' for ' iHemi 'h']);
    end


end

%% return all sub folders that contains wanted overlay mgz file
function folder = find_my_files(subject,derivDir,fileParts)

    subDirs = dir(fullfile(derivDir, '*'));
    
    if strcmp(fileParts{1},'**') % if mgz folder not specified we will look across all subfolders
        subDirs = subDirs([subDirs.isdir] & ~ismember({subDirs.name}, {'.', '..', 'derivatives','freesurfer'}));
    else % if mgz folder is specified we will only check that folder for the mgz files
        subDirs = subDirs([subDirs.isdir] & ismember({subDirs.name}, {fileParts{1}}));
    end

    tmpFiles = [];
    for subDir = subDirs'

            tmpFiles = [tmpFiles; dir(fullfile(derivDir, subDir.name, subject, fileParts{2}, [fileParts{5} 'h.' fileParts{3} '.mgz']))];
        
    end

    folder = cell(numel(tmpFiles),1);
    for iFile = 1:length(tmpFiles)
        if ~tmpFiles(iFile).isdir
            folder{iFile}  = tmpFiles(iFile).folder;
        end
    end
end

%% load customized color maps if we have
function overlayCmd = custom_colormap(derivDir,overlayName,colormapName, overlayCmd, iHemi)

if contains(overlayName,'eccen')
    whichMap = 'eccentricity_color_scale';
elseif contains(lower(overlayName),'myelin')
    whichMap = 'myelin2';
    whichMap=[];
elseif contains(overlayName,'angle_adj')
    whichMap  = ['angle_corr_' iHemi 'h_color_scale'];
elseif contains(lower(overlayName),'cdratio1')
    whichMap = 'cddiff';


elseif ismember(overlayName,{'mt+1','mt+2','mt+12','bio1','cw','ccw','cwccw','in','out','inout','upper','lower'})
    whichMap = 'rainbow'; % default rainbow color map for bold beta weights 0:0.1:0.7
    whichMap = [];


elseif ~strcmp(colormapName,'NA') % mannual input overwrites default
    whichMap = colormapName;
else
    whichMap =[];
end

whereMap = sprintf('%s/freesurfer/%s',derivDir,whichMap); % find the colormap
if isfile(whereMap)
    overlayCmd = [overlayCmd,sprintf(':overlay_custom=%s',whereMap)];
end

if ~isempty(whichMap) && ~exist(whereMap) % if it is specified but doesn't exist
    disp(['customized color map <' whichMap '> not found in <' derivDir '/freesurfer/>'])
    % check if we have a default map for it
    if ismember(overlayName,{'mt+1','mt+2','mt+12','bio1','cw','ccw','cwccw','in','out','inout','upper','lower'})
        disp(['we will use default color map <rainbow> for ' iHemi 'h.' overlayName '.mgz'])
        whereMap = sprintf('%s/freesurfer/%s',derivDir,'rainbow'); % find the colormap
        if isfile(whereMap)
            overlayCmd = [overlayCmd,sprintf(':overlay_custom=%s',whereMap)];
        else
            disp(['could not locate default color map <rainbow> in <' derivDir '/freesurfer/>'])
        end
    end
end

end
