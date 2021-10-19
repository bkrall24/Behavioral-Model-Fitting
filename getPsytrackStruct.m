function booSelect= getPsytrackStruct(name, filename,  stimP, select)
    
    % Pull out the relevant information from the name structure
    lick = name.lick;
    trialStims = name.animal.stimulus;
    opto = name.animal.LED;
    sessions = name.animal.sessionName;
    nogo = name.lick(:,5);
    
    
    % answer gives what side was correct 1 for low sounds 2 for high
    if mode(name.animal.lowSide) == 1
        %answer = -(name.animal.target -2);
        answer = name.animal.target;
        answer = changem(answer,[1 2],[2 1]);
    else
        %answer = name.animal.target -1;
        answer = name.animal.target;
    end
    
    % stims represents the stim values from the Hz to the parameterized
    % as the log distance from 8 Hz. Therefore low sounds are negative and
    % high sounds are positive
    stims = log2(trialStims/8)/2;
    
    % low and highStims are simply the difficulty of the low or high
    % stimulus presented. so highStims == 0 when a low sound plays.
    lowStims = -stims;
    lowStims(lowStims < 0) = 0;
    
    highStims = stims;
    highStims(highStims < 0) = 0;
    
    
    % difficulty gives the distance from 8 of each sound played without any
    % information about what direction
    difficulty = highStims+lowStims;
    
    % lowHigh gives 1 for high sounds and -1 for lowSounds
    lowHigh = stims;
    lowHigh(lowHigh > 0 ) = 1;
    lowHigh(lowHigh < 0) = -1;
    

    
    
    % lickChoice represents which spout was licked on each trial such that
    % -1 represents a lick to whatever side is yoked to low sounds and 1 is
    % yoked to high sounds. 0 is a non choice (no go or error)
    if mode(name.animal.lowSide) == 0
        lowLick = (lick(:,2) |  lick(:,3))';
        highLick = (lick(:,1) |  lick(:,4))';
    else
        lowLick = (lick(:,1) |  lick(:,4))';
        highLick = (lick(:,2) |  lick(:,3))';
    end
    lickChoice = (lowLick'*-1) + (highLick)';
    
    % correctLick represents whether or not the animal made the correct choice
    % on the given trial 1 represents a correct choice, -1 an incorrect
    % choice and 0 is a non choice (no go or error)
    correctLick = (lick(:,1) |  lick(:,2));
    incorrectLick = (lick(:,3) | lick(:,4)) * -1;
    correctLick = correctLick+incorrectLick;
    
    
    % lastCorrect represents the side that the animal last was rewarded on
    % so if the animal got a reward on the low side then the next three
    % trials missed (regardless of the choice) it will be negative one
    % until the animal gets rewarded on the high side
   
    hits = name.lick(:,1:2);
    if mode(name.animal.lowSide) == 0
        hits(:,2) = hits(:,2)*-1;
    else
        hits(:,1) = hits(:,1)*-1;
    end
    lastCorrect = sum(hits')';
    for i = 2:length(lastCorrect)
        if lastCorrect(i) == 0
            lastCorrect(i) = lastCorrect(i-1);
        end
    end
    lastCorrect = [0; lastCorrect(1:end-1)];
    
%     % bias represents the proportion of the previous 10 trials that the
%     % animal licked to one side
%     
%     bias(1:9) = 0;
%     
%     for i = 10:length(highLick)
%         bias(i) = sum(highLick(i-9:i))/10;
%     end
    
   
    
    % This creates history information for each parameter - essentially
    % each new column gives the previous trial's information. So column 2
    % gives the information for one trial previous, column 3 give 2 trial
    % previous etc. 
    stims = getHistoricalRegressors(stims, 2);
    lickChoice = getHistoricalRegressors(lickChoice, 2);
    correctLick = getHistoricalRegressors(correctLick, 2);
    opto = getHistoricalRegressors(opto,2);
    lowHigh= getHistoricalRegressors(lowHigh,2);
    difficulty = getHistoricalRegressors(difficulty,2);
    lastCorrect = getHistoricalRegressors(lastCorrect, 2);
    nogo = getHistoricalRegressors(nogo,3);
    nogo = nogo(:,2:4);
    lowStims = getHistoricalRegressors(lowStims,2);
    highStims = getHistoricalRegressors(highStims, 2);
    
    
    
    
    y = lickChoice(:,1);
    y(y == 1) = 2;
    y(y == -1) = 1;
  
    
    exclude = (y == 0);
    include = contains(name.animal.parameterName, 'dualspout_op')';
    
    if nargin == 4
        include = include & select';
    end
    
    y = y(~exclude & include);
    lowHigh = lowHigh(~exclude& include,:);
    opto = opto(~exclude& include,:);
    correctLick = correctLick(~exclude& include,:);
    lickChoice = lickChoice(~exclude& include,:);
    lastCorrect = lastCorrect(~exclude & include);
    difficulty = difficulty(~exclude & include);
    stims = stims(~exclude& include,:);
   
    answer = answer(~exclude & include);
    nogo = nogo(~exclude & include);
    lowStims = lowStims(~exclude & include);
    highStims = highStims(~exclude & include);
    
    sessions = sessions(~exclude& include);
    [seshs, order, ~] = unique(sessions, 'stable');
    sessionNum = cellfun(@str2num, extract(seshs, digitsPattern));
    [~,sortIdx] = sort(sessionNum,'ascend');
    order = [order(sortIdx); length(sessions)];
    order(1) = 0;
    dayLength = diff(order);
           
    startPath = 'W:\Data\2AFC_Behavior';
    pathname = uigetdir(startPath);
    filepath = [ pathname, '\', filename,'.mat'];
    correct = correctLick(:,1);
    correct(correct == -1) = 0;
    
    if stimP == 1
        inputs = {stims, correctLick(:,2:3), lickChoice(:,2:3), opto, lastCorrect, nogo};%, lowHigh, difficulty,  lowStims, highStims};
        vars = {'stims', 'correctLick', 'lickChoice', 'opto', 'nogo'};%'lowHigh', 'difficulty', , 'lowStims', 'highStims'};
    elseif stimP == 2
        inputs = {correctLick(:,2:3), lickChoice(:,2:3), opto,  nogo, lowHigh, difficulty};
        vars = {'correctLick', 'lickChoice', 'opto',  'nogo','lowHigh', 'difficulty'};
    elseif stimP == 3
        inputs = {correctLick(:,2:3), lickChoice(:,2:3), opto, nogo,  lowStims, highStims};
        vars = { 'correctLick', 'lickChoice', 'opto', 'nogo' , 'lowStims', 'highStims'};
    end
    
    save(filepath, 'y',  'dayLength', 'answer', 'correct', 'inputs', 'vars');

    booSelect = ~exclude & include;
end