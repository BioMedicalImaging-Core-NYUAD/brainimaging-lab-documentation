function trials = njm_trial_structs(P, design, nTrialsSession)
% NJM_TRIAL_STRUCTS - Turn design rows into structs with the texts to display
%
% Inputs:
%   P              - parameters from the JSON
%   design         - table of trials (rows of the participant's design)
%   nTrialsSession - total number of trials in the session (for "Trial n / N")
%
% Output:
%   trials(k).side(1) = Offer A (left), .side(2) = Offer B (right), each with
%       .origin, .face and, per attribute, .text.<attribute> / .detail.<attribute>
%   trials(k).counterText, .kind, .isCatch, .dominantSide, .trialGlobal

A = P.attributes;
n = height(design);
trials = struct('side', cell(n, 1), 'counterText', '', 'kind', '', 'isCatch', 0, 'dominantSide', '', 'trialGlobal', 0);
letters = 'AB';
for k = 1:n
    for s = 1:2
        p = letters(s);
        origin = design.([p '_origin']){k};
        iO = find(strcmp(A.employer_origin.levels, origin), 1);
        iS = find(A.salary_aed.levels == design.([p '_salary_aed'])(k), 1);
        iR = find(abs(A.rest_days_per_week.levels - design.([p '_rest_days'])(k)) < 1e-6, 1);
        iW = find(A.workload.levels == design.([p '_workload'])(k), 1);
        if isempty(iO) || isempty(iS) || isempty(iR) || isempty(iW)
            error('njm_trial_structs:level', 'Trial %d offer %s has a level that is not in the JSON', k, p);
        end
        side = struct();
        side.letter = p;
        side.origin = origin;
        side.face = design.([p '_face']){k};
        side.salary = design.([p '_salary_aed'])(k);
        side.text.employer_origin = A.employer_origin.display{iO};
        side.detail.employer_origin = A.employer_origin.detail{iO};
        side.text.salary_aed = A.salary_aed.display{iS};
        side.detail.salary_aed = A.salary_aed.detail{iS};
        side.text.rest_days_per_week = A.rest_days_per_week.display{iR};
        side.detail.rest_days_per_week = A.rest_days_per_week.detail{iR};
        side.text.workload = A.workload.display{iW};
        side.detail.workload = A.workload.detail{iW};
        trials(k).side(s) = side;
    end
    if P.session.show_trial_counter
        trials(k).counterText = sprintf('Trial %d / %d', design.trial_global(k), nTrialsSession);
    end
    trials(k).kind = design.trial_kind{k};
    trials(k).isCatch = design.is_catch(k);
    trials(k).dominantSide = design.dominant_side{k};
    trials(k).trialGlobal = design.trial_global(k);
end

end
