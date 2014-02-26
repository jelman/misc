import os
import numpy as np
import pandas as pd
from nipype.interfaces.fsl import ImageStats 

def fslstats(infile, mask):
    stats = ImageStats()
    stats.inputs.in_file = infile
    stats.inputs.op_string = '-M'
    stats.inputs.mask_file = mask
    cout = stats.run()
    return cout.outputs.out_stat


if __name__ == '__main__':

    ###################### Set inputs ##################################
    sublist_file = '/home/jagust/DST/FSL/spreadsheets/AllSubs.txt' #List of subjects
    mask = '/home/jagust/DST/FSL/masks/HiCorr_gt_Incorr/sphere/voxelwiseGM/Left_Hippo.nii.gz' #ROI mask
    statlist = ['zstat1', 'zstat2', 'zstat3', 'zstat4', 'zstat5', 'zstat11'] #Stats to extract
    groupinfo_file = '/home/jagust/DST/FSL/spreadsheets/Included_Subjects.csv' #File listing group status
    infile_pattern = '/home/jagust/DST/FSL/functional/2ndLevel/Details/%s.gfeat/cope1.feat/stats/%s.nii.gz'
    outfile = '/home/jagust/DST/FSL/results/Details_5Bins/SphereROI/voxelwiseGM/TaskPos_Left_Hippo.csv'
    ####################################################################

    with open(sublist_file,'r+') as f:
        sublist = f.read().splitlines()
        
    groupinfo = pd.read_csv(groupinfo_file, sep=None)  
      
    statdict = {}
    for stat in statlist:
        statdict[stat] = {}
        for subj in sublist:
            infile = infile_pattern%(subj,stat)
            subjstat = fslstats(infile, mask)
            statdict[stat][subj] = subjstat
    statdf = pd.DataFrame.from_dict(statdict)
    statdf = statdf.reindex(columns=statlist) #re-order columns to match statlist above
    statdf_groupinfo = pd.merge(statdf, groupinfo, left_index=True, right_on='Subject')
