function y = gampdf(x, a, b)
%GAMPDF_NOSTATS  Gamma PDF without Statistics Toolbox
%   y = gampdf_nostats(x, a, b)
%
%   x : array of evaluation points (any size)
%   a : shape  (>0, scalar or same size as x)
%   b : scale  (>0, scalar or same size as x)

    % Basic input check (skip for speed in tight loops)
    if any(a(:)<=0 | b(:)<=0)
        error('Shape (a) and scale (b) must be positive.');
    end

    % Ensure inputs are compatible sizes (implicit expansion in R2016b+)
    y = (x.^(a-1) .* exp(-x./b)) ./ (b.^a .* gamma(a));

    % Force pdf=0 for x<0
    y(x<0) = 0;
end
