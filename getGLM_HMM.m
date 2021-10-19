function getGLM_HMM(name, filename)
    
    % This function is designed to organize the relevant information from a
    % given animal to be saved for use in the python GLM-HMM notebook.
    
    % It takes an animal structure outputted from the analyzeAnimal()
    % function and pulls out the psychometric sessions. The GLM-HMM
    % requires data to be input as a matrix AxBxC where A = num of
    % sessions, B = num of trials per session and C = num of weights. Since
    % the animals do a variable number of sessions per trial, first it will
    % need to determine the maximum number of trials that can be used per
    % session.
    
    sessions = name.animal.sessionName;
    params = name.animal.parameterName;
    
    % first, find the first session where the animal did >250 psychometric
    % trials as a proxy for the first day where the animal is proficient at
    % the task
    sesh = unique(name.animal.sessionName, 'stable');
    pT= [];
    for i = 1:length(sesh)
        select = sessions == sesh(i);
        pT(i) = sum(contains(params(select), 'OPTO'));
    end
    idxFirstPsych = find(pT>250, 1, 'first');
    
    % then subsample the animal to select all trials from that session on
    name = subsampleAnimal(name, idxFirstPsych:length(sesh));
    maxTrials = min([name.day.opTrials]);
    
    
    % iterate through each session, pull out the weights for each animal -
    % low stim, high stim, nogo, opto, previous correct, and previous 
    % choice. These are based on the psytrack weights but may be better to
    % use fewer weights overall. The notebook doesn't explicitly state to
    % exclude nogos and errors like psytrack, but here I'll assume that is
    % the appropriate means to select. 
    sessions = name.animal.sessionName;
    sesh = unique(name.animal.sessionName, 'stable');
    
    for i = 1:length(sesh)
        select = sessions == sesh(i);
        lick = name.lick(select,:);
        trialStims = name.animal.stimulus(select);
        opto = name.animal.LED(select);
        
        nogo = name.lick(select,5);
        nogo = getHistoricalRegressors(nogo, 1);
        nogo = nogo(:,2);
        
        
        stims = (log2(trialStims/8)/2)';    
        lowStims = -stims;
        lowStims(lowStims < 0) = 0;
        highStims = stims;
        highStims(highStims < 0) = 0;
        
        if mode(name.animal.lowSide) == 0
            lowLick = (lick(:,2) |  lick(:,3))';
            highLick = (lick(:,1) |  lick(:,4))';
        else
            lowLick = (lick(:,1) |  lick(:,4))';
            highLick = (lick(:,2) |  lick(:,3))';
        end
        lickChoice = (lowLick') + (highLick*2)';
        lickChoice = getHistoricalRegressors(lickChoice, 1);
        y = lickChoice(:,1);
        %y(y == 1) = 2;
        %y(y == -1) = 1;
        lickChoice = lickChoice(:,2);
        
        correctLick = (lick(:,1) |  lick(:,2));
        %incorrectLick = (lick(:,3) | lick(:,4)) * -1;
        %correctLick = correctLick+incorrectLick;
        correctLick = getHistoricalRegressors(correctLick, 1);
        correctLick = correctLick(:,2);
        
        exclude = (y == 0);
        y = y(~exclude);
        lowStims = lowStims(~exclude);
        highStims = highStims(~exclude);
        opto = opto(~exclude);
        nogo = nogo(~exclude);
        correctLick = correctLick(~exclude);
        lickChoice = lickChoice(~exclude);
        
        ans(i,:) = y(1:maxTrials)-1;
        w(i,:,1) = lowStims(1:maxTrials);
        w(i,:,2) = highStims(1:maxTrials);
        w(i,:,3) = opto(1:maxTrials);
        w(i,:,4) = nogo(1:maxTrials);
        w(i,:,5) = correctLick(1:maxTrials);
        w(i,:,6) = lickChoice(1:maxTrials);
        w(i,:,7) = ones(maxTrials,1);
        
        
    end
    
    startPath = 'W:\Data\2AFC_Behavior';
    pathname = uigetdir(startPath);
    filepath = [ pathname, '\', filename,'.mat'];
    
    save(filepath, 'w', 'ans');

end