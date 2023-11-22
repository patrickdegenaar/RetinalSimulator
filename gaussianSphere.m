% This function creates a 2546x256 Gassian function which can then be
% resized to create gaussian blurring kernels

function gauss_sphere = gaussianSphere

% Create a gaussian sphere of 256, which can be resized in images
img_size= 256;
x       = linspace(-1,1,img_size);
[X,Y]   = meshgrid(x);

% Define the Gaussian sphere parameters
offset = 0; % radius of the sphere
sigma = 0.5; % standard deviation of the Gaussian

% Compute the distance from the center of the sphere
dist = sqrt(X.^2 + Y.^2);

% Create the Gaussian sphere profile
gauss_sphere = exp(-(dist - offset).^2 / (2*sigma^2));

% Normalize the profile to have a maximum intensity of 1
gauss_sphere = gauss_sphere / max(gauss_sphere(:));

% % Display the Gaussian sphere image profile
% imshow(gauss_sphere);