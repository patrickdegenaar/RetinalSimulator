% Generate a noisy binary circle
% This is part of the retinalBlur algorithm and required to prevent
% banding.

function noisyCircle = noisycircles(imageSize, radius, noiseLevel)

% % Define the center of the circle
centre= [round(imageSize/2) , round(imageSize/2)];

% Generate the x and y coordinates for the circle
theta = linspace(0, 2*pi, 1000);
noise = round(noiseLevel*rand(1,length(theta)));

% add the noise level to the radius
radii = radius + noise;

% generate the coordinates
x = (radii.*cos(theta)) + centre(1);
y = (radii.*sin(theta)) + centre(2);

% Create a binary mask for the circle
noisyCircle = poly2mask(x, y, imageSize, imageSize);