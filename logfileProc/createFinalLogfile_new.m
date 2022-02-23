%Function for creating the final logfile
%Author: Eleni Patelaki
 
function [] = createFinalLogfile_new(subjStr,readLogPath,writeLogPath,log_listings)
    
   
    % Store the content of the manually created logfile in a cell array
    fileID1 = fopen([writeLogPath,'GoNoGoPark_',subjStr,'_plusEmotState_correctedMotState_removedGamepadArifacts.txt'],'r');

    manLogMatrix = textscan(fileID1,'%s','delimiter','\n');
    manLogMatrix = manLogMatrix{1,1};
    fclose(fileID1);
    numRowsMan = size(manLogMatrix,1);

    % Store the content of the automatically created logfile in a cell array
    presLog = dir([readLogPath,log_listings]);
   
    fileID2 = fopen([readLogPath,presLog.name],'r');
    presLogMatrix = textscan(fileID2,'%s','delimiter','\n');
    presLogMatrix = presLogMatrix{1,1};
    fclose(fileID2);
    numRowsPres = size(presLogMatrix,1);

    % Open a file to write the extended .txt content

    fileID3 = fopen([writeLogPath,'FinalLogfile_',subjStr,'.txt'],'w');
    trialsPerBlock = 240; %240 pictures
    realExper = false;
    distPrevNoGo = 0;
    flagwo1 = false;
    flagwo2 = false;

    for i=1:numRowsPres
        if contains(presLogMatrix{i},'Picture') || contains(presLogMatrix{i},'Response') || contains(presLogMatrix{i},'Pause') || contains(presLogMatrix{i},'Resume')|| contains(presLogMatrix{i},'Quit')
            textRowPres = textscan(presLogMatrix{i},'%f %s %s');

            if realExper
                if strcmp(textRowPres{3}{1},'pic_display')
                    if flagwo1 && flagwo2
                        presTrial = textRowPres{1}(1)-2;
                        blockNum = floor((presTrial-offset)/trialsPerBlock)+2;
                    elseif flagwo1 && ~flagwo2
                        presTrial = textRowPres{1}(1)-2;
                        blockNum = floor((presTrial-offset)/trialsPerBlock)+2;
                    else
                        presTrial = textRowPres{1}(1);
                        blockNum = floor((presTrial-offset)/trialsPerBlock)+1;
                    end
                    trialNum = mod(presTrial-offset,trialsPerBlock) + 1;
                    for j=2:numRowsMan
                        textRowMan = textscan(manLogMatrix{j},'%d %d %s %d %s %d %s %d');
                        if (textRowMan{1} == blockNum) && (textRowMan{2} == trialNum)
                            compString = strcat('StimOnset_',textRowMan{5}{1},'_',textRowMan{7}{1});
                            if j>=3
                                textRowManPrev = textscan(manLogMatrix{j-1},'%d %d %s %d %s %d %s %d');
                                if textRowManPrev{1} == textRowMan{1}
                                    if strcmp(textRowManPrev{3}{1},textRowMan{3}{1})
                                        distPrevNoGo = 0;
                                    else
                                        distPrevNoGo = distPrevNoGo + 1;
                                    end
                                else
                                    distPrevNoGo = 1;
                                end
                            else
                                distPrevNoGo = 1;
                            end
                            
                            if textRowMan{6} == 0
                                RespTime = 0;
                            else
                                RespTime = textRowMan{4} + 183;
                            end
                            
                            compString = strcat(compString,'_DistPrevNoGo_',num2str(distPrevNoGo),'_ButtonResp_',num2str(textRowMan{6}),'_ZeroCluster_',num2str(textRowMan{8}),'_RT_',num2str(RespTime),'_BlockNum_',num2str(blockNum));
                            presLogMatrix{i} = strrep(presLogMatrix{i},'pic_display',compString);
                            break;
                        end
                    end
                elseif contains(textRowPres{3}{1},'countdown')
                    if ~flagwo1
                        offset = mod(textRowPres{1}(1),trialsPerBlock)+1;
                    else
                        offset = mod(textRowPres{1}(1)-2,trialsPerBlock)+1;
                    end
                elseif contains(textRowPres{3}{1},'walking_only_cross')
                    flagwo1 = true;
                elseif contains(textRowPres{3}{1},'walking_only_end')
                    flagwo2 = true;
                end
            end

            if strcmp(textRowPres{3}{1},'exper_start_message')
                realExper = true;
            end

            fprintf(fileID3,'%s\n',presLogMatrix{i});
        end
    end
    
    fclose(fileID3);
end

