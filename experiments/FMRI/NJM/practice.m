function practice(opts)
% PRACTICE - NJM practice trials (mock scanner, or in the scanner before run 1)
%
% Same screens, timing and buttons as the real task, with a short set of job
% offers that is not part of the 48 scanner trials (stimuli_data/design/
% njm_practice_trials.csv). Data are saved with task-njmpractice so they can
% never be mixed up with the scanner runs.
%
%   practice            dialog asks for subject and session
%   practice(opts)      see main.m

if nargin < 1, opts = struct(); end
main('practice', opts);

end
