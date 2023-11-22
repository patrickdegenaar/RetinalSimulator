% The objective of this function is to convert a normal cartesian image
% into a retinal image with a 50 degree field of view. No retinal
% processing is included, just the blurring with eccentricity effect
% radii                     % Is a linear spacing of radii from the image centre from which to construct the logpolar retinal image
% imageScaling              % is the eccentricity scaling function - i.e. how resolution changes with distance from the fovea (image centre).
% imGrey                    % the input image - needs to be greyScale
% Stochasticity   = 50;     % To make the blur process stochastic - this helps prevent banding
% noiseImage      = 0.5;    % a profile of the retinal noise;   

function retinaImage = retinalBlur(imGrey, radii, imageScaling, Stochasticity, noiseImage)


% global variables
% The image scaling parameters are calibrated to an image size of 1024.
% So we will keep this fixed.
imSize      = 1024;                 % Image size
iterations  = round(imSize/2);

% Resize the image and convert to double
imGrey      = imresize(imGrey, [imSize imSize]);
imGrey      = double(imGrey);

% -------------------------------------------------------------------------
%% Define blur kernel
% -------------------------------------------------------------------------
% define gaussian convolution kernel to smooth the image with eccentricity
kernel = [  0, 0, 1, 1, 1, 0, 0
            0, 1, 1, 2, 1, 1, 0;
            1, 1, 2, 4, 2, 1, 1;
            1, 2, 4, 8, 4, 2, 1;
            1, 1, 2, 4, 2, 1, 1;
            0, 1, 2, 2, 1, 1, 0;
            0, 0, 1, 1, 1, 0, 0];

kernel = kernel/sum(sum(kernel));

% -------------------------------------------------------------------------
%% Create the blurring with distance
% -------------------------------------------------------------------------

% initialise the matrices
aggregateImage      = zeros([imSize imSize]);
innerCircleMatrix   = zeros([imSize, imSize]);

for n = 2:iterations

    % Create outer to a binary matrix using poly2mask
    radius            = radii(n);    
    outerCircleMatrix = noisycircles(imSize, radius, Stochasticity);

    % blur the image
    resizeIm = imresize(imGrey, imageScaling(n));
    blurImage = conv2((resizeIm), kernel, 'same');
    blurImage = imresize((blurImage), [imSize , imSize]);
    
    % Create disk
    disk = outerCircleMatrix - innerCircleMatrix;
    disk = disk > 0;
   
    % get the image segment
    imageSegment = double(disk) .* double(blurImage);

    % create aggregateImage
    aggregateImage = aggregateImage + imageSegment;
    
    % Logically add the outer cicrcle to the current one. In theory the
    % outer should replace the inner, but not necessarily in a noisy set
    % up.
    innerCircleMatrix = innerCircleMatrix | outerCircleMatrix;

end

% do a final blur to remove the rough edges
aggregateImage = conv2(aggregateImage, kernel, 'same');


% rescale final image
aggregateImage = aggregateImage * 255/max(max(aggregateImage));
aggregateImage = uint8(aggregateImage);

% Add noise
retinaImage = uint8(double(noiseImage) .*double(aggregateImage));

% end
