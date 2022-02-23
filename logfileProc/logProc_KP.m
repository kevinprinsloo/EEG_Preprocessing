% Main function for processing of the logfiles, in order to be usable in the
% EEG Pipeline
% Author: Eleni Patelaki
function [] = logProc(subjStr)
    % Find the subject group, i.e. if the subject is a pilot or a real one
    if contains(subjStr,'010705') || contains(subjStr,'020705')
        subjGroup = 'GoNoGo';
    elseif contains(subjStr,'subj')
        subjGroup = 'Pilot';
    else
        error('Wrong subject string! Try again');
    end


    readLogPath = ['C:\Users\kevin\Box\MoBI-SSDs-data'];
    writeLogPath = ['C:\Users\kevin\Box\MoBI-SSDs-data'];
    picsPath = ['C:\Users\kevin\Box\MoBI-SSDs-data'];

    if ~exist(writeLogPath, 'dir')
        mkdir(writeLogPath)
    end

    % Find the number of blocks from the content of the
    % motion_state_{subjStr} file
    nBlocks = findnBlocks(subjStr,readLogPath);
    
    % First create and save an extended version of the initial manually-created
    % logfile, having added a column EmoState, containing the emotional valence
    % of each picture
    addEmotionalValence(subjStr,readLogPath,writeLogPath,picsPath)

    % Probably not necessary if everything has gone well, but if motion state
    % order is not correct, it can be fixed with the following function.
    correctMotionState(subjStr,readLogPath,writeLogPath,nBlocks)

    % Remove any trials, which are inluded in significantly large clusters of
    % non-responses for the wireless gamepad
    removeGamepadArtifactsNew(subjStr,writeLogPath)    

    % Finally, create a final logfile, which is a fused version of the manually
    %-created and the Presentation-created logfile. This logfile is going to be
    %used in the EEG processing pipeline
    createFinalLogfile_new(subjStr,readLogPath,writeLogPath)
end



