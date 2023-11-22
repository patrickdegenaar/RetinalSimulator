
% Always clear everything before start
clear; clc; close all

% global variables
fps             = 30;       % Frame rate of the retinal video
Stochasticity   = 50;       % To make the blur process stochastic - this helps prevent banding
noiseLevel      = 0.25;      % include noise to a value between 0-1;   
imSize          = 1024;     % The eccentricity funciton is calibrated to 1024 pixels


%--------------------------------------------------------------------------
%% open and prepare a video
%--------------------------------------------------------------------------
% We need to make the frames square so this takes a bit of manual fiddling
% to provide an optimum

% function read_video_frames(video_path)
% Open the video file for reading
inputVideo  = VideoReader('AodhanVid.mp4');
outputVideo = VideoWriter('outputFiles\resizedVid.mp4', 'MPEG-4');

% Set the frame rate of the video file
outputVideo.FrameRate = fps;

% Open the video file for writing
open(outputVideo);

% Loop through the frames until the end of the video
offset = 130;
while hasFrame(inputVideo)

    % Read in the next frame from the video
    frame = readFrame(inputVideo);

    % convert the frame into a square
    [numRows, numColms, numCols] = size(frame);
    startRow = numRows - numColms - offset;
    endRow   = startRow + numColms;

    % Get the cutscen
    cutFrame = frame(startRow:endRow, :,:);

    % Write the image to the video file
    writeVideo(outputVideo, cutFrame);

end

% Release the video objects and close any windows
delete(inputVideo);
delete(outputVideo);


%--------------------------------------------------------------------------
%% Calculate the retinal eccentricity function
%--------------------------------------------------------------------------
% this function calculates the resolution change with eccentrcitiy. It is
% calibrated to an image size of 1024 x 1024 using data from human vison.
iterations    = round(imSize/2);
[radii, eccentricity, eccentricScale] = retinalEccentricity(imSize, iterations);


%--------------------------------------------------------------------------
%% Create the retinally blurred video
%--------------------------------------------------------------------------

% open the video reader and writer objects
inputVideo  = VideoReader('outputFiles\test.mp4');
outputVideo = VideoWriter('outputFiles\retinalVid.mp4', 'MPEG-4');

% Set the frame rate of the video file
outputVideo.FrameRate = fps;

% Open the video file for writing
open(outputVideo);

while hasFrame(inputVideo)

    % Read in the next frame from the video
    vidframe = readFrame(inputVideo);

    % Initialise output frame
    retinalFrame = uint8(zeros(1024,1024,3));

    % convert each of the colour patterns of the frame into a retinal form
    for colour = 1:3

        % Extract the R, G, or B component of the image.
        imGrey = vidframe(:,:,colour);
    
        % imSize       :     Image size
        % imageScaling :     How the retinal resolution scales with eccentricity
        % noiseLevel   :     What is the noise level (Set between 0 -1)
        noiseImage = retinalNoise(imSize, eccentricity, noiseLevel);
    
        % convert to the retinal image
        % radii          : Is a linear spacing of radii from the image centre from which to construct the logpolar retinal image
        % imageScaling   : Is the eccentricity scaling function - i.e. how resolution changes with distance from the fovea (image centre).
        % imGrey         : The input image - needs to be greyScale
        % Stochasticity  : To make the blur process stochastic - this helps prevent banding
        % noiseLevel     : Include noise to a value between 0-
        retinaImage = retinalBlur(imGrey, radii, eccentricity, Stochasticity, noiseImage);
        
        % integrate into final image
        retinalFrame(:,:,colour) = retinaImage;
    end

    % make sure it is a uint8 for output
    retinalFrame = uint8(retinalFrame);

    % Write the image to the video file
    writeVideo(outputVideo, retinalFrame);


end

% Release the video objects and close any windows
delete(inputVideo);
delete(outputVideo);


