%Function for determining the number of experimental blocks
%Author: Eleni Patelaki
 
function nBlocks = findnBlocks(subjStr,readLogPath)
    
    % readLogPath is usually going to be 
    % For real data :
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\DataGoNoGo\',subjstring,'\PresentationLogs\']
    % For pilot data :
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\DataPilot\',subjstring,'\PresentationLogs\']
    % writeLogPath is usually going to be 
    % For real data :
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\EEGAnalysis\ProcessedLogs\GoNoGo\',subjstring,'\']
    % For pilot data :
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\EEGAnalysis\ProcessedLogs\Pilot\',subjstring,'\']
    % picsPath is usually going to be
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\PresentationCode\']

    % Store the content of the manually created logfile in a cell array
    fileID1 = fopen([readLogPath,'motion_state.txt'],'r');
    textMatrix = textscan(fileID1,'%s','delimiter','\n');
    textMatrix = textMatrix{1,1};
    fclose(fileID1);
    nBlocks = length(textMatrix);
end

