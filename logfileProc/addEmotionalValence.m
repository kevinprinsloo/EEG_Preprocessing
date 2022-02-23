%Function for adding an extra column to the logfile, which contains the
%valence of each image
%Author: Eleni Patelaki
 
function [] = addEmotionalValence(subjStr,readLogPath,writeLogPath,picsPath)
    
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
   
    fileID1 = fopen([readLogPath,'GoNoGo_SSDs.txt'],'r');
    if fileID1 == -1
        fileID1 = fopen([readLogPath,'GoNoGoPark_noTraining_',subjStr,'.txt'],'r');
    end
    
    textMatrix = textscan(fileID1,'%s','delimiter','\n');
    textMatrix = textMatrix{1,1};
    fclose(fileID1);
    numRows = size(textMatrix,1);

    % Open a file to write the extended .txt content
    if ~exist(writeLogPath, 'dir')
        mkdir(subjStr)
    end
    fileID2 = fopen([writeLogPath,'GoNoGoPark_',subjStr,'_plusEmotState.txt'],'w');
    fprintf(fileID2,'%s \n','Block Trial Image RespTime MotState Button EmoSate');

    % Create an cell array containing the names of all the positive
    % images
    posPicsStruct = dir([picsPath,'positive']);
    posPicsNames = extractfield(posPicsStruct,'name');

    % Create an cell array containing the names of all the neutral
    % images
    neutPicsStruct = dir([picsPath,'neutral']);
    neutPicsNames = extractfield(neutPicsStruct,'name');

    % Create an cell array containing the names of all the negative
    % images
    negPicsStruct = dir([picsPath,'negative']);
    negPicsNames = extractfield(negPicsStruct,'name');

    % Line by line searching of the emotion category
    for i = 3:numRows
        textRow = textscan(textMatrix{i},'%d %d %s %d %s %d');
        currPicName = textRow{3}{1};
        % Check to which category the current picture belongs
        if any(strcmp(posPicsNames,currPicName))
            %disp('Positive');
            emotState = 'positive';
        elseif any(strcmp(neutPicsNames,currPicName))
            %disp('Neutral');
            emotState = 'neutral';
        elseif any(strcmp(negPicsNames,currPicName))
            %disp('Negative');
            emotState = 'negative';
        else
            %disp('Not Found');
            emotState = ' ';
        end

        % Write the new logfile, line by line
        fprintf(fileID2,'%d %d %s %d %s %d %s\n',textRow{1},textRow{2},textRow{3}{1},textRow{4},textRow{5}{1},textRow{6},emotState);
    end
    
    fclose(fileID2);
end

