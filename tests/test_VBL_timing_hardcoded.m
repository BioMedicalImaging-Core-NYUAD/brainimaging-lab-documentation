clear; clc;

AssertOpenGL;
PsychDefaultSetup(2);
Screen('Preference','SkipSyncTests',0);

screens = Screen('Screens');
screenNumber = max(screens);

[w, rect] = Screen('OpenWindow', screenNumber, 128);
ifi = Screen('GetFlipInterval', w);

Priority(MaxPriority(w));

nFrames = 300;

% Storage
waitUntilVBL      = zeros(nFrames,1);
stimMinusVBL      = zeros(nFrames,1);
cpuReturnDelay    = zeros(nFrames,1);
missed_vals       = zeros(nFrames,1);

% Initial sync flip
vbl = Screen('Flip', w);

for i = 1:nFrames
    
    % Alternate color
    if mod(i,2)==0
        Screen('FillRect', w, 255);
    else
        Screen('FillRect', w, 0);
    end
    
    tBeforeFlip = GetSecs;   % meaningful name
    
    [vbl, stimulusOnsetTime, flipTimestamp, missed] = ...
        Screen('Flip', w, vbl + 0.5*ifi);
    
    % Measurements
    waitUntilVBL(i)   = vbl - tBeforeFlip;
    stimMinusVBL(i)   = stimulusOnsetTime - vbl;
    cpuReturnDelay(i) = flipTimestamp - vbl;
    missed_vals(i)    = missed;
end

Priority(0);
Screen('CloseAll');

% Print diagnostics
fprintf('\n========== FLIP DIAGNOSTICS ==========\n');

fprintf('\n1) Wait until VBL (vbl - tBeforeFlip)\n');
fprintf('   Mean: %.6f s (%.3f ms)\n', mean(waitUntilVBL), mean(waitUntilVBL)*1000);
fprintf('   Std : %.6f s (%.3f ms)\n', std(waitUntilVBL),  std(waitUntilVBL)*1000);

fprintf('\n2) stimulusOnsetTime - vbl\n');
fprintf('   Mean: %.9f s (%.6f ms)\n', mean(stimMinusVBL), mean(stimMinusVBL)*1000);
fprintf('   Std : %.9f s (%.6f ms)\n', std(stimMinusVBL),  std(stimMinusVBL)*1000);

fprintf('\n3) CPU return delay (flipTimestamp - vbl)\n');
fprintf('   Mean: %.6f s (%.3f ms)\n', mean(cpuReturnDelay), mean(cpuReturnDelay)*1000);
fprintf('   Std : %.6f s (%.3f ms)\n', std(cpuReturnDelay),  std(cpuReturnDelay)*1000);

fprintf('\n4) Missed deadlines\n');
fprintf('   Total missed: %d out of %d frames\n', sum(missed_vals>0), nFrames);
fprintf('   Max miss amount: %.6f s\n', max(missed_vals));

fprintf('\n======================================\n\n');