% Always clear everything before start
clear; clc; close all

tic
% Global variables
Stochasticity   = 50;       % To make the blur process stochastic - this helps prevent banding
noiseLevel      = 0.25;      % include noise to a value between 0-1;   
imageSize       = 1024;     % The eccentricity funciton is calibrated to 1024 pixels

% Read image from file
imRGB       = imread('donkey.jpg');

gpuEnhanced = 1;
colour      = 1;

tic
%--------------------------------------------------------------------------
% Create the base kernel
%--------------------------------------------------------------------------

% Define a basic gaussian matrix of 101 x 101 from which we can resize to
% whatever is required.
matrixSize      = [101, 101];       % Define size
sigma           = 25;               % Set sigma so Gaussian reaches edges.

% Create a gaussian matrix and define it for GPU enhanced processing
if gpuEnhanced == 1
    gaussianMatrix  = fspecial('gaussian', matrixSize, sigma);
    gaussianMatrix  = gpuArray(gaussianMatrix);
else
    gaussianMatrix  = fspecial('gaussian', matrixSize, sigma);
end

L3_gaussian     = imresize((gaussianMatrix), [3,3]);
L7_gaussian     = imresize((gaussianMatrix), [7,7]);
L15_gaussian     = imresize((gaussianMatrix), [15,15]);
L31_gaussian     = imresize((gaussianMatrix), [31,31]);
L63_gaussian     = imresize((gaussianMatrix), [63,63]);
L127_gaussian    = imresize((gaussianMatrix), [127,127]);

L3_gaussian     = (L3_gaussian)/sum(L3_gaussian);
L7_gaussian     = (L7_gaussian)/sum(L7_gaussian);
L15_gaussian    = (L15_gaussian)/sum(L15_gaussian);
L31_gaussian    = (L31_gaussian)/sum(L31_gaussian);
L63_gaussian    = (L63_gaussian)/sum(L63_gaussian);
L127_gaussian   = (L127_gaussian)/sum(L127_gaussian);

%--------------------------------------------------------------------------
% Extract image colormaps
%--------------------------------------------------------------------------

% resize to the standard image size and convert to GPU array
if gpuEnhanced == 1
    imRGB      = imresize(gpuArray(imRGB), [imageSize, imageSize ]);
else
    imRGB      = imresize(imRGB, [imageSize, imageSize ]);
end

% Depending on the colour setting, extract grey or colour colormaps;
imGreen     = double(imRGB(:,:,2)); % 1 = red, 2 = green, 3 = blue
imRed       = double(imRGB(:,:,1));
imBlue      = double(imRGB(:,:,3));


% defining grey as absolute according to the YUV Y setting, which is
% based on the human perception index. Though I'm not sure if this is
% already taken into account when defining the RGB.
imGrey      = (0.299 *imRed) +...
              (0.587 * imGreen) +...
              (0.114 * imBlue); 




%--------------------------------------------------------------------------
% GreyScale Difference of Gaussians
%--------------------------------------------------------------------------

L3_Grey     = conv2(imGrey, L3_gaussian,'same');
L7_Grey     = conv2(imGrey, L7_gaussian,'same');
L15_Grey    = conv2(imGrey, L15_gaussian,'same');
L31_Grey    = conv2(imGrey, L31_gaussian,'same');
L63_Grey    = conv2(imGrey, L63_gaussian,'same');

G1 = L3_Grey - L7_Grey;
G2 = L7_Grey - L15_Grey;
G3 = L15_Grey - L31_Grey;
G4 = L31_Grey - L63_Grey;

ON_Grey =   ((G1 > 0) .* G1) + ...
            ((G2 > 0) .* G2) + ...
            ((G3 > 0) .* G3) + ...
            ((G4 > 0) .* G4);

OFF_Grey =  ((G1 < 0) .* G1) + ...
            ((G2 < 0) .* G2) + ...
            ((G3 < 0) .* G3) + ...
            ((G4 < 0) .* G4);

Total_Grey = ON_Grey + OFF_Grey;
Net_Grey   = ON_Grey + abs(OFF_Grey);

max(max(Total_Grey))


toc


%--------------------------------------------------------------------------
% Plot figures
%--------------------------------------------------------------------------

% Depending on the colour setting, extract grey or colour colormaps;

   figure
    subplot(1,3,1); imagesc(ON_Grey); colormap(gray)
    subplot(1,3,2); imagesc(OFF_Grey); colormap(gray)
    subplot(1,3,3); imagesc(Total_Grey); colormap(gray)










