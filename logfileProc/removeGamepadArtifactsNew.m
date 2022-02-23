%Function for adding an extra column to the logfile, which contains "0" if
%the trial belongs to an island of non-responses and "1" if it's a valid
%trial. Islands of non-responses (island size can be adjusted) are rejected
%because they indicate thay participant might be distracted or facing other
%difficulties during the respective experimental duration.
%Author: Eleni Patelaki
 
function [] = removeGamepadArtifactsNew(subjStr,writeLogPath)
    
    % writeLogPath is usually going to be 
    % For real data :
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\EEGAnalysis\ProcessedLogs\GoNoGo\',subjstring,'\']
    % For pilot data :
    % ['\\files.rcbi.rochester.edu\foxeAnalysis\MOBI\GoNoGo\EEGAnalysis\ProcessedLogs\Pilot\',subjstring,'\']
    
    % if clustSize is x, then 
    clustSize = 6;
    
    % Store the content of the manually created logfile in a cell array
    fileID1 = fopen([writeLogPath,'GoNoGoPark_',subjStr,'_plusEmotState_correctedMotState.txt'],'r');
    textMatrix = textscan(fileID1,'%s','delimiter','\n');
    textMatrix = textMatrix{1,1};
    fclose(fileID1);
    numRows = size(textMatrix,1);

    % Open a file to write the extended .txt content
    fileID2 = fopen([writeLogPath,'GoNoGoPark_',subjStr,'_plusEmotState_correctedMotState_removedGamepadArifacts.txt'],'w');
    fprintf(fileID2,'%s \n','Block Trial Image RespTime MotState Button EmoSate ZeroClusters');

    for i=2:numRows
        textRow = textscan(textMatrix{i},'%d %d %s %d %s %d %s');
        buttonResp(i-1) = textRow{6};
        blockNum(i-1) = textRow{1};
    end

    deltaButtonResp = diff([1,buttonResp]);
    deltaBlockNum = diff([blockNum(1)-1,blockNum]);
    zeroClusterStarts = find(deltaButtonResp == -1) + 1;
    zeroClusterEnds = find(deltaButtonResp == 1);
    blockChanges = find(deltaBlockNum == 1);
    if size(zeroClusterEnds,2)== size(zeroClusterStarts,2) -1
        zeroClusterEnds = [zeroClusterEnds, numRows+1];
    end

    try
        iArt = 0;
        numClusters = min(size(zeroClusterStarts,2),size(zeroClusterEnds,2));
        for i=1:numClusters
            
            textRowZeroClusterStart = textscan(textMatrix{zeroClusterStarts(i)},'%d %d %s %d %s %d %s');
            if zeroClusterStarts(i) >= 3
                textRowZeroClusterStartPrev = textscan(textMatrix{zeroClusterStarts(i)-1},'%d %d %s %d %s %d %s');
                if strcmp(textRowZeroClusterStartPrev{3}{1},textRowZeroClusterStart{3}{1}) && textRowZeroClusterStart{6}==0 &&  textRowZeroClusterStartPrev{6}==1 
                    zeroClusterStarts(i) = zeroClusterStarts(i) + 1;
                end
            end
            
            
            blockChangesBeforeEnd = find(zeroClusterEnds(i) - blockChanges >=0);
            blockChangesAfterStart = find(blockChanges - zeroClusterStarts(i)>=0);
            blockChangeBetween = intersect(blockChangesAfterStart,blockChangesBeforeEnd);
            if ~isempty(blockChangeBetween)
                 for j = 1:length(blockChangeBetween)
                    if j == 1
                        if blockChanges(blockChangeBetween(1)) - zeroClusterStarts(i)> (clustSize-2)
                            iArt = iArt + 1;
                            artifactZeroClusterStarts(iArt) = zeroClusterStarts(i);
                            artifactZeroClusterEnds(iArt) = blockChanges(blockChangeBetween(1));
                        end
                    elseif j == length(blockChangeBetween)
                        if zeroClusterEnds(i) - (blockChanges(blockChangeBetween(length(blockChangeBetween)-1)) + 1) > (clustSize-2)
                            iArt = iArt + 1;
                            artifactZeroClusterStarts(iArt) = blockChanges(blockChangeBetween(length(blockChangeBetween)-1))+1;
                            artifactZeroClusterEnds(iArt) = zeroClusterEnds(i);
                        end
                    end
                end
            else
                if zeroClusterEnds(i) - zeroClusterStarts(i) > (clustSize-2)
                    iArt = iArt + 1;
                    artifactZeroClusterStarts(iArt) = zeroClusterStarts(i);
                    artifactZeroClusterEnds(iArt) = zeroClusterEnds(i);
                end
            end
        end
        numArtifactClusters = min(size(artifactZeroClusterStarts,2),size(artifactZeroClusterEnds,2));
    catch
        numArtifactClusters = 1;
        artifactZeroClusterStarts(1) = -2;
        artifactZeroClusterEnds(1) = -1;
    end

    

    for i=2:numRows
        textRow = textscan(textMatrix{i},'%d %d %s %d %s %d %s');

        if i<artifactZeroClusterStarts(1) || (i>=artifactZeroClusterEnds(numArtifactClusters)&&i<=numRows)
            fprintf(fileID2,'%d %d %s %d %s %d %s %d\n',textRow{1},textRow{2},textRow{3}{1},textRow{4},textRow{5}{1},textRow{6},textRow{7}{1},1);
        end
        for j=1:numArtifactClusters-1
            % Write the new logfile, line by line
            if i<artifactZeroClusterStarts(j+1) && i> artifactZeroClusterEnds(j)
                fprintf(fileID2,'%d %d %s %d %s %d %s %d\n',textRow{1},textRow{2},textRow{3}{1},textRow{4},textRow{5}{1},textRow{6},textRow{7}{1},1);
            end
        end
        for j=1:numArtifactClusters
            % Write the new logfile, line by line
            if i>=artifactZeroClusterStarts(j) && i<=artifactZeroClusterEnds(j)
                fprintf(fileID2,'%d %d %s %d %s %d %s %d\n',textRow{1},textRow{2},textRow{3}{1},textRow{4},textRow{5}{1},textRow{6},textRow{7}{1},0);
            end
        end
    end
        
    fclose(fileID2);
end

