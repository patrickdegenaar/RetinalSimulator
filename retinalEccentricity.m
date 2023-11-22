% this function calculates the resolution change with eccentrcitiy. It is
% calibrated to an image size of 1024 x 1024 using data from human vison.

function [radii, imagecaling, eccentricity]  = retinalEccentricity(imSize, iterations)

% Create a funciton to map the acuity/resolution as a function of image
% size, assuming that the image spans 100 degrees of view

FoV             = 100;                                  % Field of View - current the system is fized to this.
maxRadius       = floor(imSize/2);                      % Maximum radius is image centre to extremit
radii           = linspace(0,maxRadius, iterations);    
retinalScale    = 1;                                    % These have been scaled to match human data from paper
gradient        = 9;                                    % These have been scaled to match human data from paper
minimum         = 0.02;                                 % These have been scaled to match human data from paper
imagecaling     = minimum + (retinalScale-minimum) * exp(-gradient * radii/max(radii));
eccentricity    = radii * (FoV/2)/max(radii);

