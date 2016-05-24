"""
Adapted from:
https://pysurfer.github.io/examples/plot_parc_values.html
"""
import numpy as np
import nibabel as nib
from surfer import Brain
subject_id = "fsaverage"
hemi "lh"
surface = "inflated"
brain = Brain(subject_id, hemi, surface, background="white")
surface = "inflated"
aparc_file = "/home/jelman/data_VETSA2/fsurf/fsaverage/label/lh.aparc.annot"
labels, ctab, names = nib.freesurfer.read_annot(aparc_file)

dat = np.genfromtxt('/home/jelman/test/ROI_data.csv',delimiter=",",skip_header=1)
roi_data = dat[:,1]
vtx_data = roi_data[labels]
brain = Brain('fsaverage', 'lh', 'orig', cortex='low_contrast')
brain.add_annotation("aparc")
brain.add_data(vtx_data, .4, .7, colormap="Reds", hemi='lh',thresh=.1, alpha=.8)

brain = Brain('fsaverage', 'split', 'inflated', views=['lat', 'med'])
