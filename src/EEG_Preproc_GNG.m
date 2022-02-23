%----------------------------------
% Summary:
% Script to Preprocess EEG Data
%---------------------------------

% Status:
% Under Development

% Notes:
% n/a

% Author(s):
% Kevin Prinsloo

% Editor(s):
%

%% Prepare Workspace
%clearvars
%close all
%clc

%% Prepare variables for Cluster
% Manually Initialise Variables

%>> Define Paths
code_path = 'C:\Users\kevin\Documents\Github\EEG_Preprocessing';
study_path = 'D:\aa_Tori_Box';

%>> Initialise Subject Variables
listing = dir([study_path,'/','LSL']);
subejct_listings = {listing.name};
subejct_listings(cellfun('length',subejct_listings)<3) = [];
subjects_orig = subejct_listings;
subjects_number = numel(subjects_orig);
subjects = subjects_orig;

%--------------------------
%% Convert xdf to mat
%--------------------------

for subject_idx = 1:subjects_number
    subject_idx_log = subjects{subject_idx}; %subjects(subject_idx);
    disp(subjects_orig{subject_idx})
    
    listing_mat = dir([study_path,'/','LSL','/', subjects{subject_idx},'/','*.xdf']);
    subejct_listings_mat = {listing_mat.name};
    subejct_ls_is = ~contains(subejct_listings_mat,'head'); 
    subejct_listings_mat = {subejct_listings_mat{subejct_ls_is}};
    subejct_ls_is = find(~contains(subejct_listings_mat,'old'));
    subejct_listings_mat = {subejct_listings_mat{subejct_ls_is}};
    
    % Fix Logfile
    logProcFix(subjects{subject_idx},study_path) % <<-- this contain a next set of subfunctions to fix the logfile
    disp('Logfile Created and saved')
    
    data_all_load_mat = cell(1,length(subejct_listings_mat));
    for k = 1:length(subejct_listings_mat)
        
        if k == 1
            start_line = 1;
        elseif k == 2
            start_line = start_line;
        end
        
        listing_txt = dir([study_path,'/','Presentation_for_analysis','/',subjects{subject_idx},'/','FinalLogfile_',subjects{subject_idx},'.txt']);
        subject_log_name = {listing_txt.name};        
        subejct_listings = subjects{subject_idx};
        filename = ([study_path,'/','LSL','/',subjects{subject_idx},'/',subejct_listings_mat{k}]);
        
        % Process logfile with xdf
        [data_all_load_mat{k},start_line] = eeg_load_mat_xdf_tori(filename,study_path,subject_log_name,subejct_listings,start_line,'streamtype','EEG','streamname','BioSemi');
    end
    data_all_load_mat = data_all_load_mat(~cellfun('isempty',data_all_load_mat));
    disp('xdf converted')
    
    % Verify Directory Exists and if Not Create It
    if exist([study_path,'/','Proc_xdf_mat','/',subjects_orig{subject_idx},'/'],'dir') == 0
        mkdir([study_path,'/','Proc_xdf_mat','/',subjects_orig{subject_idx},'/']);
    end
    % Save Figures and Data
    filename = [study_path,'/','Proc_xdf_mat','/',subjects_orig{subject_idx},'/',...
        subjects_orig{subject_idx}];    filetype = '.mat';
    save([filename,filetype],'data_all_load_mat','-v7.3'); clear filename filetype
    clear data_all_load_mat
    disp('xdf saved')
end

%-------------------------------------
%% Preprocess mat file | EEG Preproc
%-------------------------------------

Filter_type = 'Fieldtrip';           %>>> Fieldtrip | Matlab
ICA_application_type = 'Fiedltrip';  %>>> Fieldtrip | Matlab

% %% FILTER
FstopH = 0.0025; %HARD STOP get rid of all frequencies below this, "hard stop"
FpassH = 0.1; %high pass band
AstopH = 65; %decibels to attenuate in high pass
FpassL = 40; %low pass band
FstopL = 50; %get rid of all frequencies above this
AstopL = 65; %decibels to attenuate in low pass
Apass = 1; %amplitude of pass band

Fs = 2048; fs = 2048;
% % Generate bandpass filter
% Generate high/low-pass filters
h = fdesign.highpass(FstopH,FpassH,AstopH,Apass,fs);
hpf = design(h,'cheby2','MatchExactly','stopband'); clear h
h = fdesign.lowpass(FpassL,FstopL,Apass,AstopL,fs);
lpf = design(h,'cheby2','MatchExactly','stopband'); clear h
% fvtool(hpf)

listing = dir([study_path,'/','Proc_xdf_mat']);
subejct_listings = {listing.name};
subejct_listings(cellfun('length',subejct_listings)<3) = [];
subjects_orig = subejct_listings;
subjects_number = numel(subjects_orig);
subjects = subjects_orig;

bad_subs = [2];

for subject_idx = 6 %1:subjects_number
    subject_idx_log = subjects{subject_idx}; %subjects(subject_idx);
    disp(subjects_orig{subject_idx})
    
    % Load data
    clear data_all_load_mat
    load([study_path,'/','Proc_xdf_mat','/',subjects_orig{subject_idx},'/',subjects_orig{subject_idx}]);
    
    data_pre_index = cell(1,length(data_all_load_mat));
    for block_Idx = 1:length(data_all_load_mat)
        
        clear data_all_load
        EEG = data_all_load_mat{block_Idx};
        
        % Initialise event information
        events = extractfield(EEG.event,'type')';
        eventFrames = extractfield(EEG.event,'latency'); % time in seconds?
        srate = EEG.srate;
        
        % Find and discard single events
        eventsIndsBefStart = 1:(find(contains(events,'exper_start_message')));
        eventsInds = find(contains(events,["countdown_3","countdown_2","countdown_1","countdown_go","walking_only","Pause","Resume"],'IgnoreCase',true))';
        longEvents = find(diff(eventFrames)/srate>2);
        inp = events;
        tmp = str2double(inp);
        pauseResumeEvents = find(tmp(:)> 3)'; % Find pause/resume - which are index as numerical values > 3 values
        % Index common redundant trials
        singleEventInds2Del = unique([eventsIndsBefStart,eventsInds,longEvents,pauseResumeEvents]);
        
        allEventInds = 1:length(events); % List all events
        singleEventInds2Keep = setdiff(allEventInds,singleEventInds2Del); % Index redundant trials
        eventsTypeKeep = events(singleEventInds2Keep);
        eventsFramesKeep = eventFrames(singleEventInds2Keep);
        newStr = regexprep(eventsTypeKeep, '^1\w*','push_push_push_0_push_0_push_0_push_0');  % replace 1 with this text
        eventsTypeKeep_clean = find(contains(newStr,["StimOnset","push"],'IgnoreCase',true));
        eventsTypeKeepName_clean = newStr(eventsTypeKeep_clean); % Keep stimOnset & Button push
        eventsFramesKeepFS_clean = eventsFramesKeep(eventsTypeKeep_clean)'; % Now get the time samples for these
        
        %% Define trial definition
        clear list_cond_variables
        trial_def = zeros(length(eventsTypeKeepName_clean),8);
        token2 = extractAfter(eventsTypeKeepName_clean ,'StimOnset_'); % Find only the StimOnset
        idx = cellfun(@isempty,token2); % Find the indexes of empty cell
        idx_notEmptry = find(~cellfun(@isempty,token2)); % Find hwere it's
        token2(idx) = {'push_push_push_0_push_0_push_0_push_0_push_0'}; % Replace the empty cells with push
        start_idx = "_"; end_idx = "_";
        % list_cond_variables = extractBetween(token2(idx_notEmptry),start_idx,end_idx,'Boundaries','exclusive');
        list_cond_variables = extractBetween(token2,start_idx,end_idx,'Boundaries','exclusive');
        
        % Extract motion type
        start_idx = "_";
        list_cond_motion = extractBefore(token2,start_idx);
        cond_mov = {list_cond_motion{:,1}}';
        newStr = strrep(cond_mov,'walking','2');
        newStr = strrep(newStr,'sitting','1');
        newStr = strrep(newStr,'push','0');
        
        % any([k_idx, k_idx_2, k_idx_3] == 2) &&
        
        for k = 1:length(newStr)-2
            k_idx = str2double(newStr{k}); k_idx_2 = str2double(newStr{k+1}); k_idx_3 = str2double(newStr{k+2});
            if  newStr{k} == '0'
                a = unique([k_idx; k_idx_2; k_idx_3]);
                b = find(a>0); c = a(b);
                newStr{k} = num2str(c);
            end
        end
        trial_def(:,8) = str2double(newStr);
        
        % Extract RT (ms)
        start_idx = "RT_";
        text_extraction2 = extractAfter(eventsTypeKeepName_clean,start_idx);
        start_idx = "_";
        text_extraction2 = extractBefore(text_extraction2,start_idx);
        RT = str2double(text_extraction2);
        kidx = find(isnan(RT));
        RT(kidx) = 0; trial_def(:,6) = RT;
        
        % Reassign picture type to integer value
        %>> [-1 negative] [0 neutral] [1 postive]
        valence = list_cond_variables(:,1);
        newStr = strrep(valence,'negative','-11');
        newStr = strrep(newStr,'neutral','22');
        newStr = strrep(newStr,'positive','11');
        newStr = strrep(newStr,'push','0');
        trial_def(:,3) = str2double(newStr); clear newStr valence
        
        %% >> list_cond_variables
        % [valence, Go/noGo (> 1 ==> GO | <=0 ==> noGo), ButtonResp (1 ==> yes | 0 ==> no), ZeroClust (not needed ignore) ]
        tmp_Idx = strrep(list_cond_variables,'push','1'); % replace push with 1
        tmp_Idx(:,2) = list_cond_variables(:,2);
        tmp_Idx = str2double(tmp_Idx); % Ignore 1st col which has Pos|Neu|Neg string
        temp_beh = zeros(length(eventsTypeKeepName_clean),1);
        temp_trig = zeros(length(eventsTypeKeepName_clean),1);
        temp_push = zeros(length(eventsTypeKeepName_clean),1);
        FAresp = zeros(length(eventsTypeKeepName_clean),1);
        for k = 1:length(eventsTypeKeepName_clean)
            
            %% >> Hit
            if tmp_Idx(k,2) > 0 && tmp_Idx(k,3) == 1 && tmp_Idx(k,4) == 1; temp_beh(k) = 1; temp_trig(k) = 75;  end
            %% >> Correct Rejection
            if tmp_Idx(k,2) == 0 && tmp_Idx(k,3) == 0 && tmp_Idx(k,4) == 1; temp_beh(k) = 2; temp_trig(k) = 85; end
            %% >> False Alarm
            if tmp_Idx(k,2) == 0 && tmp_Idx(k,3) == 1 && tmp_Idx(k,4) == 1; temp_beh(k) = -1; temp_trig(k) = 85; end
            %% >> Miss
            if tmp_Idx(k,2) > 0 && tmp_Idx(k,3) == 0 && tmp_Idx(k,4) == 1; temp_beh(k) = 3; temp_trig(k) = 75; end
            %% >> False Alarm Resp
            if tmp_Idx(k,2) == 0 && tmp_Idx(k,3) == 1 && tmp_Idx(k,4) == 1 && k ~= length(eventsTypeKeepName_clean)
                trial_def(k+1,4) = 1; temp_beh(k+1) = -11; temp_trig(k+1) = 1; FAresp(k+1) = -1; end
        end
        
        trial_def(:,5) = temp_beh; % Performance
        trial_def(:,4) = temp_trig; % Trig value
        trial_def(:,7) = FAresp; % FA response trig
        % Assign start pts to trigger matrix
        trial_def(:,1) = round(eventsFramesKeepFS_clean(1:end),1);
        
        for k = 1:length(trial_def)
            if trial_def(k,2:end) == 0
                trial_def(k,:) = 0;
            end
        end
        trial_def = trial_def(~all(trial_def == 0, 2),:);
        
        %---------------------------
        %% Insert into ft_structure
        %---------------------------
        
        testdat = eeglab2fieldtrip(EEG,'preprocessing');
        elec = ft_read_sens(['C:\Users\kevin\Box\RCBI_Server_Storage\aa_Neuro_Typical_Database\Resources_Misc\BioSemi_64_names.sfp'],'filetype','sfp');
        testdat.label = elec.label;
        testdat = rmfield(testdat,'elec');
        testdat.trial{1} = testdat.trial{1}(2:65,:);
        
        % Def hdr
        hdr = [];
        hdr.Fs = srate;
        hdr.nChan = size(elec.label,1);
        hdr.label = elec.label;
        hdr.nTrials = 1;
        hdr.nSamples = size(EEG.data,2);
        hdr.nSamplesPre = 0;
        hdr.chantype = cellstr(repmat('EEG',[size(elec.label,1),1]));
        hdr.chanunit = cellstr(repmat('uV',[size(elec.label,1),1]));
        testdat.hdr = hdr;
        
        clear data_pre
        cfg = [];
        cfg.detrend = 'no';
        cfg.demean = 'no';
        cfg.continuous = 'yes';
        data_pre = ft_preprocessing(cfg, testdat); clear testdat EEG
        
        data_pre_index{block_Idx} = data_pre; clear data_pre
    end
    
    %-----------------
    %% Apend data
    %-----------------
    
    clear data_pre
    if length(data_pre_index)>2
        data_pre = ft_appenddata([], data_pre_index{:});
    else
        data_pre = data_pre_index{1};
    end
    clear data_pre_index
    
    %--------------------
    %% Filter EEG
    %-------------------
    
    if strcmp(Filter_type, 'Matlab')
        clear EEGdata_filt EEGdata_raw
        EEGdata_raw = data_pre.trial{1}; EEGdata_raw=EEGdata_raw';
        EEGdata_filt = filtfilthd(hpf,EEGdata_raw);  % (time x chan) filtfilthd filters by columns if given a matrix;
        clear EEGdata_raw
        EEG_data_filt = filtfilthd(lpf,EEGdata_filt);   % don't transpose because next step looks for bad channels in a (time x channel) format
        clear EEGdata_filt
        data_pre.trial{1} = EEG_data_filt';
        all_data = data_pre; clear data_pre
    elseif strcmp(Filter_type, 'Fieldtrip')
        %% Epoching & Filtering
        % Epoch one continous dataset & apply filters
        cfg = [];
        cfg.detrend = 'no';
        cfg.lpfilter = 'yes';
        cfg.hpfilter = 'yes';
        cfg.lpfreq = 30;
        cfg.hpfreq = 1;
        cfg.hpfilttype = 'firws';
        cfg.hpfiltdir = 'onepass-zerophase';
        cfg.hpfiltwintype = 'hamming';
        all_data = ft_preprocessing(cfg, data_pre);
    end
    clear data_pre
    
    %------------------------
    %% Organise trial_def
    %------------------------
    
    sample = trial_def(:,1);
    value = trial_def(:,4);
    RT = trial_def(:,6);
    beh = trial_def(:,5);
    rsp = trial_def(:,7);
    mobi = trial_def(:,8);
    
    clear val t_onset
    for k=1:length(value)
        val(k) = value(k);
        t_onset(k) = sample(k);
    end
    
    % Define trial epochs
    sampling_rate = srate;
    format long
    prestimT = 0.1;
    poststimT = 0.8;
    trl =[];
    for t = 1:length(t_onset)
        ts = t_onset(t);
        begsample     = ts - prestimT*sampling_rate; % sample at trigger
        endsample     = ts + poststimT*sampling_rate; % sample at end
        offset        = -prestimT*sampling_rate;
        % offset : each trial has an offset that defines where the relative
        % t=0 point (usually the point of the stimulus trigger) is for that trial.
        trl(t,:) = [round([begsample endsample offset]) value(t) beh(t) RT(t) rsp(t) mobi(t)];
    end
    trl(1,:) = [];
    trl_hd = trl(:,1:3);
    
    %% Epoch data
    clear all_data_epoch
    cfg = [];
    cfg.trl = trl_hd;
    cfg.channel = 'EEG';
    cfg.continuous = 'yes';
    cfg.detrend = 'yes';
    cfg.demean = 'no';
    cfg = ft_definetrial(cfg);
    all_data_epoch = ft_redefinetrial(cfg, all_data); %redefines the filtered data
    
    % Add trl info
    all_data_epoch.trialinfo = trl; clear all_data
    
    clear eventsFramesKeepFS_clean newStr allEventInds ventsTypeKeep eventsFramesKeep eventsTypeKeepName_clean
    clear pauseResumeEvents singleEventInds2Del eventsInd eventsIndsBefStart eventsTypeKeep_clean
    clear events eventFrames token2 trial_def newStr list_cond_motion trl eventsTypeKeep
    clear mobi rsp beh RT value sample text_extraction2
    
    %-----------------------
    %% Artefact rejection
    %-----------------------
    
    elec = ft_read_sens(['C:\Users\kevin\Box\RCBI_Server_Storage\aa_Neuro_Typical_Database\Resources_Misc\BioSemi_64_names.sfp'],'filetype','sfp');
    EEG_data_trl.elec = elec;
    
    cfg = [];
    cfg.method = 'summary';
    cfg.layout = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    EEG_data_trl = ft_rejectvisual(cfg, all_data_epoch);
    
    %--------------------------------------
    %% Remove BAD Channel
    %--------------------------------------
    
    elec = ft_read_sens(['C:\Users\kevin\Box\RCBI_Server_Storage\aa_Neuro_Typical_Database\Resources_Misc\BioSemi_64_names.sfp'],'filetype','sfp');
    EEG_data_trl.elec = elec;
    channels_number_cephalic =  size(EEG_data_trl.label,1);
    
    cfg=[];
    cfg.layout = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    cfg.method = 'triangulation';
    neighbours = ft_prepare_neighbours(cfg, EEG_data_trl);
    
    cfg = [];
    cfg.layout = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    cfg.method = 'summary';
    cfg.keepchannel = 'repair';
    cfg.channel = 'eeg';
    cfg.neighbours = neighbours;
    cfg.metric = 'zvalue';
    EEG_data_chn = ft_rejectvisual(cfg, EEG_data_trl); clear EEG_data_trl
    
    %---------------------
    %% Rereference data
    %---------------------
    
    cfg = [];
    cfg.reref = 'yes';
    cfg.refchannel = 'all';
    EEG_data = ft_preprocessing(cfg, EEG_data_chn);
    clear EEG_data_chn EEG_data_trl
    
    %% Downsample data
    cfg = [];
    cfg.resamplefs = 256;
    EEG_data_ds = ft_resampledata(cfg, EEG_data);
    
    %-----------------
    %% Save Pre ICA
    %-----------------
    
    %% Go
    cfg = [];
    cfg.keepindividual = 'yes';
    %cfg.trials = find(EEG_data_ds.trialinfo(:,4) == 850 & EEG_data_ds.trialinfo(:,5) == -1);
    cfg.trials = find(EEG_data_ds.trialinfo(:,4) < 78  & EEG_data_ds.trialinfo(:,5) == 1 & EEG_data_ds.trialinfo(:,8) == 2);
    tm_data11 = ft_timelockanalysis(cfg,  EEG_data_ds);
    cfg =[];
    cfg.keepindividual = 'yes';
    cfg.baseline = [-0.1 0];
    tm_data11 = ft_timelockbaseline(cfg, tm_data11);
    %% NoGo
    cfg = [];
    cfg.keepindividual = 'yes';
    %cfg.trials = find(EEG_data_ds.trialinfo(:,4) == 1850 & EEG_data_ds.trialinfo(:,5) == -1);
    cfg.trials = find(EEG_data_ds.trialinfo(:,4) > 80 & EEG_data_ds.trialinfo(:,5) == 2 & EEG_data_ds.trialinfo(:,8) == 2);
    tm_data22 = ft_timelockanalysis(cfg,  EEG_data_ds);
    cfg =[];
    cfg.keepindividual = 'yes';
    cfg.baseline = [-0.1 0];
    tm_data22 = ft_timelockbaseline(cfg, tm_data22);
    
    figure;
    cfg = [];
    cfg.graphcolor = 'gr';
    cfg.linewidth = 2;
    cfg.layout = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    ft_multiplotER(cfg, tm_data11, tm_data22);
    
    
    % Verify Directory Exists and if Not Create It
    if exist([study_path,'/','Proc_preICA_mat','/',subjects_orig{subject_idx},'/'],'dir') == 0
        mkdir([study_path,'/','Proc_preICA_mat','/',subjects_orig{subject_idx},'/']);
    end
    % Save Figures and Data
    filename = [study_path,'/','Proc_preICA_mat','/',subjects_orig{subject_idx},'/',...
        subjects_orig{subject_idx}];    filetype = '.mat';
    save([filename,filetype],'EEG_data_ds','-v7.3'); clear filename filetype
    
    clear tm_data11 tm_data22
    
    %-------------------------
    %% Transform to SCD
    %------------------------
    
    cfg = [];
    cfg.channel = 'eeg';
    cfg.layout = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    cfg.trials = 'all';
    cfg.method = 'spline';
    cfg.lambda = 1e-4;
    EEG_data_CSD = ft_scalpcurrentdensity(cfg, EEG_data_ds);
    
    % Verify Directory Exists and if Not Create It
    if exist([study_path,'/','Proc_preICA_CSD','/',subjects_orig{subject_idx},'/'],'dir') == 0
        mkdir([study_path,'/','Proc_preICA_CSD','/',subjects_orig{subject_idx},'/']);
    end
    % Save Figures and Data
    filename = [study_path,'/','Proc_preICA_CSD','/',subjects_orig{subject_idx},'/',...
        subjects_orig{subject_idx}];    filetype = '.mat';
    save([filename,filetype],'EEG_data_CSD','-v7.3'); clear filename filetype
    
    %----------------------
    %% ICA Analysis
    %----------------------
    
    data_orig = EEG_data; %save the original CLEAN data for later use
    cfg = [];
    cfg.resamplefs = 150; %downsample frequency
    cfg.detrend = 'no';
    disp('Downsampling data');
    data = ft_resampledata(cfg, data_orig);
    
    % decompose the data
    disp('About to run ICA using the Runica method')
    cfg            = [];
    cfg.method     = 'fastica';
    comp = ft_componentanalysis(cfg, data);
    
    %% Remove components from original data
    %% Decompose the original data as it was prior to downsampling
    cfg           = [];
    cfg.unmixing  = comp.unmixing;
    cfg.topolabel = comp.topolabel;
    comp_orig = ft_componentanalysis(cfg, data_orig);
    
    % Display Components - change layout as needed
    cfg           = [];
    cfg.component = [1:30];       % specify the component(s) that should be plotted
    cfg.layout    = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    cfg.comment   = 'no';
    ft_topoplotIC(cfg, comp)
    
    %     cfg             = [];
    %     cfg.channel     = [1:20]; % components to be plotted
    %     cfg.compscale   = 'local';
    %     cfg.viewmode    = 'component';
    %     cfg.zlim        = 'maxmin';
    %     cfg.layout      = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    %     ft_databrowser(cfg, comp)
    
    %-------------------------
    %% Remove comps now
    %-------------------------
    
    %% The original data can now be reconstructed, excluding specified components
    % This asks the user to specify the components to be removed
    fprintf('loading GUI:\n\n\t\t\t\t\t\t\t');
    badcomp_value_tmp  = inputdlg('What is the chosen bad comps? :',...
        'bad_comp', [1 50]);
    badcomp_Sub = str2num(badcomp_value_tmp{:}); disp(badcomp_Sub)
    
    % remove bad components
    temp = 'badcomp_Sub'; clear badcomp_value_tmp
    cfg.component = eval(temp);
    data_clean    = ft_rejectcomponent(cfg, comp_orig, data_orig);
    
    %-----------------------
    %% Downsample data
    %-----------------------
    
    cfg = [];
    cfg.resamplefs = 256;
    data_clean = ft_resampledata(cfg, data_clean);
    
    %-----------------
    %% Save Pre ICA
    %-----------------
    
    %% Go
    cfg = [];
    cfg.keepindividual = 'yes';
    %cfg.trials = find(EEG_data_ds.trialinfo(:,4) == 850 & EEG_data_ds.trialinfo(:,5) == -1);
    cfg.trials = find(data_clean.trialinfo(:,4) < 78  & data_clean.trialinfo(:,5) == 1 & data_clean.trialinfo(:,8) == 1);
    tm_data11 = ft_timelockanalysis(cfg,  data_clean);
    cfg =[];
    cfg.keepindividual = 'yes';
    cfg.baseline = [-0.1 0];
    tm_data11 = ft_timelockbaseline(cfg, tm_data11);
    %% NoGo
    cfg = [];
    cfg.keepindividual = 'yes';
    %cfg.trials = find(EEG_data_ds.trialinfo(:,4) == 1850 & EEG_data_ds.trialinfo(:,5) == -1);
    cfg.trials = find(data_clean.trialinfo(:,4) > 80 & data_clean.trialinfo(:,5) == 2 & data_clean.trialinfo(:,8) == 1);
    tm_data22 = ft_timelockanalysis(cfg,  data_clean);
    cfg =[];
    cfg.keepindividual = 'yes';
    cfg.baseline = [-0.1 0];
    tm_data22 = ft_timelockbaseline(cfg, tm_data22);
    
    figure;
    cfg = [];
    cfg.graphcolor = 'gr';
    cfg.linewidth = 2;
    cfg.layout = ['biosemi',num2str(channels_number_cephalic),'.lay'];
    ft_multiplotER(cfg, tm_data11, tm_data22);
    
    
    % Verify Directory Exists and if Not Create It
    if exist([study_path,'/','Proc_ICA_mat','/',subjects_orig{subject_idx},'/'],'dir') == 0
        mkdir([study_path,'/','Proc_ICA_mat','/',subjects_orig{subject_idx},'/']);
    end
    % Save Figures and Data
    filename = [study_path,'/','Proc_ICA_mat','/',subjects_orig{subject_idx},'/',...
        subjects_orig{subject_idx}];    filetype = '.mat';
    save([filename,filetype],'data_clean','-v7.3'); clear filename filetype
    
    clear EEG_data tm_data11 tm_data22
    
end

























