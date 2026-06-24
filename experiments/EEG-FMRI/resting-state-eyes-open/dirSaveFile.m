function [const] = dirSaveFile(const)
% ----------------------------------------------------------------------
% [const]=dirSaveFile(const)
% ----------------------------------------------------------------------
% Goal of the function :
% Make directory and saving files.
% ----------------------------------------------------------------------
% Input(s) :
% const : struct containing a lot of constant configuration
% ----------------------------------------------------------------------
% Output(s):
% const : struct containing a lot of constant configuration
% ----------------------------------------------------------------------


% Subject name:
if const.DEBUG ~= 1
    const.subjID = input(sprintf('\n\tSubjectID (4 digits): '),'s');
    while length(const.subjID) ~= 4
        const.subjID = input(sprintf('\n\tInitials (MUST BE 4 digits): '),'s');
    end
else
    const.subjID = 'XXXX';
    const.EL_mode = 0;
end

% Subject Directory
[MainDirectory, ~] = fileparts(pwd);
datadir = fullfile(MainDirectory, 'Data');
const.subjDir = fullfile(datadir,const.subjID);
const.runLog = fullfile(datadir,const.subjID, 'runlog.txt');

if ~isfile(const.runLog)
    mkdir(const.subjDir);
    const.run = 1;
else
    fid = fopen(const.runLog, 'r');
    runs = fscanf(fid, '%s');
    runarray = split(runs, 'Run');
    const.run = str2num(runarray{end})+1;
end

% make run directory
const.runDir = fullfile(const.subjDir, sprintf('Run%i', const.run));
mkdir(const.runDir);

const.eyeDataDir = fullfile(const.runDir, 'eyedata');
const.eyeFileName = datestr(now, 'mmddHHMM');

if length(const.eyeFileName) > 8, error('EYELINK SET UP: filename must be <= 8 digits!'),end

end