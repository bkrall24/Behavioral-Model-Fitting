
import pandas as pd
import os
from scipy.io import loadmat
import numpy as np

def mat_struct_2_pd(folderpath, file):

    file_data = 'analyze_animal_'+file+'.mat'
    path = os.path.join(folderpath,file_data);
    mouse_mat = loadmat(path, struct_as_record = False, squeeze_me = True, mat_dtype = True)
    
    m = mouse_mat['animal']
    beh = pd.DataFrame((m.lick.T).astype(bool))
    beh.columns = ['RH', 'LH', 'RM', 'LM', 'NG']
    beh['LED'] = (m.LED).astype(bool)
    beh['Session'] = m.sessionNum
    beh['Stimulus'] = m.stimulus
    beh['Target'] = m.target 

    file_ttl = 'ttl_info_'+file+'.mat'
    ttl_path = os.path.join(folderpath, file_ttl)
    mouse_ttl = loadmat(ttl_path, struct_as_record = False, squeeze_me = True, mat_dtype = True)
    beh['Spout_1']= np.mean(mouse_ttl['trial_info'].lick[:,750:825,0],axis = 1)
    beh['Spout_2'] = np.mean(mouse_ttl['trial_info'].lick[:,750:825,1],axis = 1)
    
    file_ttl2 = 'ttl_choices_'+file+'.mat'
    ttl_path2 = os.path.join(folderpath, file_ttl2)
    mouse_ttl2 = loadmat(ttl_path2, struct_as_record = False, squeeze_me = True, mat_dtype = True)
    c = mouse_ttl2['trial_info'].choice[:,:,750:2750]
    rx = []
    #ch= []
    for a in range(c.shape[0]):
        r = (np.argwhere(c[a,:,:]== 1))
    
        if r.size == 0 and m.rxnTime[a] > 0:
            rx.append(m.rxnTime[a]);
        elif r.size == 0:
            rx.append(np.nan)
            #ch.append(np.nan)
        else:
            #ch.append(r[0][0])
            rx.append(r[0][1])
    
    beh['latency'] = rx
    #beh['early'] = ch
    

    file_training = 'analyze_training_'+file+'.mat'
    training_path = os.path.join(folderpath, file_training)
    mouse_train = loadmat(training_path,struct_as_record = False, squeeze_me = True, mat_dtype = True)
    
    train = mouse_train['training']
    tdata = {'trials_opto': [train.trials_opto], 'trials_prof': [train.trials_proficient],
        'trials_expert': [train.trials_expert], 'days_opto': [train.days_opto],
        'days_prof':[train.days_proficient], 'days_expert': [train.days_expert]}
    
    t = pd.DataFrame(tdata)


    

    return beh, t



def clean_behavior_data(b):


    b2 = pd.DataFrame()
    ns = np.array(np.append(1, np.diff(b['Session'])), dtype = bool)

    b2['Rightward'] = (b['RH'] | b['LM']).astype(int)
    pr = np.concatenate(([0], b2['Rightward'][:-1].values));
    pr[ns] = 0;
    b2['Previous_rightward'] = pr;

    b2['Correct'] = (b['RH'] | b['LH']).astype(int)
    pc = np.concatenate(([0], b2['Correct'][:-1].values))  
    pc[ns] = 0;
    b2['Previous_correct'] = pc;

    b2['Stimulus'] =np.log2(b['Stimulus']/8)/2
    b2['LED'] = b['LED'].astype(int);
    b2['Target'] = b['Target'].astype(int);
    b2['Session'] = b['Session'];

   
    b2['Latency'] = b['latency']/1000;
    #b2['New_session']= ns;
   
    go = (b['RH'] | b['LM'] | b['RM'] | b['LH']).values
    
    b2 = b2.iloc[go,:]
    
    return b2