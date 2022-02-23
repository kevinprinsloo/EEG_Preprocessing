
function [] = logProcFix(subjStr,study_path)

% subjStr = subjects{subject_idx}
% 

readLogPath = [study_path,'/','Presentation_for_analysis','/',subjStr,'/'];
writeLogPath = [study_path,'/','Presentation_for_analysis','/',subjStr,'/'];
picsPath = [study_path,'/','PresentationCode','/'];

listing_mat = dir([readLogPath,'*.log']);
log_listings = listing_mat.name;


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
createFinalLogfile_new(subjStr,readLogPath,writeLogPath,log_listings)
end

% That's correct a correct NoGo trial must be DistPrevNoGo_0 AND ButtonResp_0
% but also ButtonRespPrev_1 (in other words, make sure that the trial before
% the NoGo was a hit, otherwise it's meaningless. because there is no actual inhibition

