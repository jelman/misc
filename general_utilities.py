import os, sys, re
import datetime
from glob import glob
import nibabel as nib
import numpy as np
import itertools


def load_nii(filename):
    """
    Load nifti file, returns data array and affine
    """
    img = nib.load(filename)
    dat = img.get_data()
    aff = img.get_affine()
    return dat, aff
    
def save_nii(outfile, data, aff):
    """
    Create nifti image using data and hdr, save to outfile.
    """    
    img = nib.Nifti1Image(data, aff)
    img.to_filename(outfile)
    return outfile

def make_dir(root, name = 'temp'):
    """ 
    generate dirname string and check if directory exists.
    If exists, append timestamp to dir name and create newdir.
    Returns created directory string
    """
    outdir = os.path.join(root, name)
    if os.path.isdir(outdir)==False:
        os.mkdir(outdir)  
        return outdir    
    else:
        #If outdir exists, rename existing outdir with timestamp appended
        mtime = os.path.getmtime(outdir)
        tmestamp = datetime.datetime.fromtimestamp(mtime).strftime('%Y-%m-%d_%H-%M-%S')
        newdir = '_'.join([outdir,tmestamp])
        os.rename(outdir,newdir)
        os.mkdir(outdir)
        print outdir, 'exists, moving to ', newdir
        return outdir


def split_filename(fname):
    """split a filename into component parts

    Parameters
    ----------
    fname : str
        file or path name

    Returns
    -------
    pth : str
        base path of fname
    name : str
        name from fname without extension
    ext : str
        file extension from fname

    Examples
    --------
    >>> from filefun import split_filename
    >>> pth, name, ext = split_filename('/home/jagust/cindeem/test.nii.gz')
    >>> pth
    '/home/jagust/cindeem'

    >>> name
    'test'

    >>> ext
    'nii.gz'

    """
    pth, name = os.path.split(fname)
    tmp = '.none'
    ext = []
    while tmp:
        name, tmp = os.path.splitext(name)
        ext.append(tmp)
    ext.reverse()
    return pth, name, ''.join(ext)

    
def load_mapping(mapfile):
    """
    Loads text file to dictionary to map values from one column to another
    First column will be loaded as key, second column as value
    """
    template_map = {}
    with open(mapfile) as f:
        for line in f:
           (key, val) = line.split()
           template_map[key] = val
    return template_map
    
def get_subid(instr, pattern='B[0-9]{2}-[0-9]{3}'):
    """regexp to find pattern in string
    default pattern = BXX-XXX  X is [0-9]
    """
    m = re.search(pattern, instr)
    try:
        subid = m.group()
    except:
        print pattern, ' not found in ', instr
        subid = None
    return subid
    
def sort_nicely(l): 
  """ 
  Sort the given list in the way that humans expect. 
  """ 
  convert = lambda text: int(text) if text.isdigit() else text.lower() 
  alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ] 
  l.sort( key=alphanum_key) 
  
  
def flat_triu(square_array):
    """
    Given a square 2D array (ie. correlation matrix), returns a 1D array 
    of the upper triangle. Does not include the diagonal.
    """
    return square_array[np.triu_indices_from(square_array, k=1)]
    

def square_from_combos(array1D, nnodes):
    """
    Given a 1D array of upper triangle and number of nodes, returns a 
    square (symmetric) 2D array. Diagonal is 0-filled. 
    """
    
    square_mat = np.zeros((nnodes,nnodes))
    indices = list(itertools.combinations(range(nnodes), 2))
    for i in range(len(array1D)):
        square_mat[indices[i]] = array1D[i]
    return square_mat + square_mat.T

