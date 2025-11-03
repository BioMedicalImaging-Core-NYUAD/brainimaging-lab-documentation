function overDone(const)
% overDone - Cleanup after experiment

try
    sca;
catch
end

try
    ListenChar(0);
    ShowCursor;
catch
end

fprintf('\n=== Experiment finished ===\n');
fprintf('Data saved to: %s\n', const.runDir);

end
