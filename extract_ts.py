import os, sys
import csv
import numpy as np
from glob import glob
import general_utilities as utils
import nibabel as nib
import pandas as pd

def get_seedname(seedfile):
    _, nme, _ = utils.split_filename(seedfile)
    return nme
    
def extract_seed_ts(data, seeds, mask):
    """ check shape match of data and seed
    if same assume registration
    extract mean of data in seed > 0"""
    data_dat = nib.load(data).get_data()
    mask_dat = nib.load(mask).get_data()
    meants = {}
    for seed in seeds:
        seednme = get_seedname(seed)
        seed_dat = nib.load(seed).get_data().squeeze()
        seed_dat[mask_dat == 0] = 0
        assert seed_dat.shape == data_dat.shape[:3]
        tmp = data_dat[seed_dat > 0,:]
        meants.update({seednme:tmp.mean(0)})
    return meants 
    
def sort_columns(df):
    new_cols = list(df.columns)
    utils.sort_nicely(new_cols)
    sorted_df = df.reindex(columns=new_cols)
    return sorted_df

def save_to_csv(d, outfile, dropna=False):
    """
    Save dict to csv by converting to pandas dataframe and saving out
    
    d : dict
    outfile : str
    """
    df = pd.DataFrame(d)
    sorted_df = sort_columns(df)
    if dropna:
        sorted_df = sorted_df.dropna(axis=1)
    sorted_df.to_csv(outfile, sep=',', header=True, index=False)
    return sorted_df


if __name__ == '__main__':


    
    ######### Set parameters #################################
    ##########################################################
    outdir = '/home/jagust/rsfmri_ica/CPAC/connectivity/timecourses'
    mask = '/home/jagust/rsfmri_ica/CPAC/rsfmriMask.nii.gz'
    data_glob = '/home/jagust/rsfmri_ica/CPAC/sym_links/pipeline_rsfmri/linear1.wm1.motion1.quadratic1.csf1_CSF_0.96_GM_0.7_WM_0.96/*/scan_func_*_4d/func/bandpass_freqs_0.01.0.08/functional_mni.nii.gz'
    data_files = glob(data_glob)
    roi_glob = '/home/jagust/jelman/templates/templates-Greicius-90rois/*.nii.gz'
    roi_files = glob(roi_glob)
    ##########################################################

    for subdat in data_files:
        submeants = extract_seed_ts(subdat, roi_files, mask)
        subid = utils.get_subid(subdat)
        outname = '_'.join([subid, 'timecourses.csv'])
        outfile = os.path.join(outdir, outname)
        subdf = save_to_csv(submeants, outfile, dropna=True)
        




