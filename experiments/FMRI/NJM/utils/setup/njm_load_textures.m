function tex = njm_load_textures(VP, cfg, faceFiles)
% NJM_LOAD_TEXTURES - Load face photos and icons as Psychtoolbox textures
%
% Inputs:
%   VP        - Viewing parameters (VP.window)
%   cfg       - from njm_load_config
%   faceFiles - cell array of face file names to load (from the design)
%
% Output:
%   tex.face - containers.Map: file name -> texture
%   tex.icon - struct: attribute name -> texture (plus tex.icon.employer)
%
% PNG transparency is kept (faces are transparent outside the oval).

P = cfg.P;
tex = struct();
tex.face = containers.Map();
faceDir = fullfile(cfg.stimDir, P.faces.folder);
faceFiles = unique(faceFiles);
for i = 1:numel(faceFiles)
    tex.face(faceFiles{i}) = make_texture(VP.window, fullfile(faceDir, faceFiles{i}));
end

iconDir = fullfile(cfg.stimDir, 'icons');
attrs = fieldnames(P.attributes);
for a = 1:numel(attrs)
    tex.icon.(attrs{a}) = make_texture(VP.window, fullfile(iconDir, P.attributes.(attrs{a}).icon));
end
tex.icon.employer = make_texture(VP.window, fullfile(iconDir, 'icon_employer.png'));

end

%--------------------------------------------------------------------------
function t = make_texture(window, file)
if ~exist(file, 'file')
    error('njm_load_textures:missingImage', 'Image not found: %s', file);
end
[img, ~, alpha] = imread(file);
if size(img, 3) == 1, img = repmat(img, [1 1 3]); end
if ~isempty(alpha), img(:, :, 4) = alpha; end
t = Screen('MakeTexture', window, img);
end
