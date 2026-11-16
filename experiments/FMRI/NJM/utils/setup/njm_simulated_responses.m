function auto = njm_simulated_responses(P, design, seed, timeScale)
% NJM_SIMULATED_RESPONSES - Choices and response times of a simulated participant
%
% Only used when debugConfig.autoRespond = 1 (testing the task and its output
% files without a person). The simulated participant prefers higher pay, more
% rest days and lighter work, ignores employer origin, is faster and more
% certain when one offer is clearly better, and sometimes fails to answer.
%
% Output: auto(k).button (1-4), .rt (seconds, already multiplied by timeScale), .timeout

rs = RandStream('mt19937ar', 'Seed', seed);
n = height(design);
auto = struct('button', cell(n, 1), 'rt', NaN, 'timeout', false);
maxRT = P.timing.phase3_decision_max_s;
for k = 1:n
    dU = utility(design.A_salary_aed(k), design.A_rest_days(k), design.A_workload(k)) - ...
         utility(design.B_salary_aed(k), design.B_rest_days(k), design.B_workload(k));
    rt = 0.7 + 1.2 * exp(-abs(dU)) + exp(-1.2 + 0.5 * randn(rs));
    chooseA = rand(rs) < 1 / (1 + exp(-1.5 * dU));
    sure = abs(dU) + 0.5 * randn(rs) > 1.0;
    if chooseA && sure, b = 1; elseif chooseA, b = 2; elseif sure, b = 4; else, b = 3; end
    auto(k).button = b;
    auto(k).timeout = rt > maxRT - 0.05 || rand(rs) < 0.05;        % too slow, or an occasional lapse
    auto(k).rt = min(rt, maxRT - 0.05) * timeScale;
end

end

function u = utility(salary, rest, workload)
restU = [-2.0, -0.4, 0.0];        % 0, 0.5, 1 day per week
workU = [0.0, -0.6, -1.4];        % light, moderate, heavy
u = 0.9 * (salary - 2500) / 700 + restU(round(rest * 2) + 1) + workU(workload);
end
