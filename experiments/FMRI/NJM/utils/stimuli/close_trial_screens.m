function pa = close_trial_screens(pa)
% CLOSE_TRIAL_SCREENS - Free the pre-rendered screens of the previous trial

for i = 1:numel(pa.screenTex)
    try
        Screen('Close', pa.screenTex(i));
    catch
    end
end
pa.screenTex = [];
pa.screenTrial = 0;

end
