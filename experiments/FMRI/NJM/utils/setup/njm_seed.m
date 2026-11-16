function seed = njm_seed(subjectID, sessionID, mode)
% NJM_SEED - Reproducible random seed from subject, session and mode
%
% The same subject/session always gets the same randomisation (run split,
% trial order, sides, faces, jitter), so the 4 runs of a session - each a
% separate call of main - stay consistent, and a design can be rebuilt later.

str = sprintf('%s|%s|%s', char(subjectID), char(sessionID), char(mode));
v = double(str);
seed = mod(sum(v .* (1:numel(v))) * 7919 + 104729 * numel(v) + 31 * sum(v), 2^31 - 1);

end
