%Function for updating the "MotState" column, in case the block motion
%state sequence has to change
%Author: Eleni Patelaki
 
function [] = correctMotionState(subjStr,readLogPath,writeLogPath,nBlocks)
    
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
    
    % Store the content of the manually created logfile in a cell array
    fileID1 = fopen([writeLogPath,'GoNoGoPark_',subjStr,'_plusEmotState.txt'],'r');
    textMatrix = textscan(fileID1,'%s','delimiter','\n');
    textMatrix = textMatrix{1,1};
    fclose(fileID1);
    numRows = size(textMatrix,1);

    % Store the content of the motion state sequence of the experiment in a cell array
    fileID2 = fopen([readLogPath,'motion_state.txt'],'r');
    motVector = textscan(fileID2, strtrim(repmat('%s ', 1, nBlocks)) ,'delimiter',' ');
    fclose(fileID2);

    % Open a file to write the extended .txt content
    fileID3 = fopen([writeLogPath,'GoNoGoPark_',subjStr,'_plusEmotState_correctedMotState.txt'],'w');
    fprintf(fileID3,'%s \n','Block Trial Image RespTime MotState Button EmoSate');

    % Find the number of the first block
    textRow = textscan(textMatrix{2},'%d %d %s %d %s %d');
    diff = textRow{1}-1;

    % Line by line searching of the emotion category
    for i = 2:numRows
            textRow = textscan(textMatrix{i},'%d %d %s %d %s %d %s');
            currMotState = motVector{1,1}{textRow{1}-diff,1};
            %disp(currMotState);

            % Write the new logfile, line by line
            fprintf(fileID3,'%d %d %s %d %s %d %s\n',textRow{1},textRow{2},textRow{3}{1},textRow{4},currMotState,textRow{6},textRow{7}{1});         
    end
        
    fclose(fileID3);
end

