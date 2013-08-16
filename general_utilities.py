import os, sys
from glob import glob
import nibabel as nib

def load_nii(filename):
    img = nib.load(filename)
    dat = img.get_data()
    hdr = img.get_header()
    return dat, hdr
    
def save_nii(outfile, data, hdr):
    img = nib.Nifti1Image(data, hdr)
    img.to_filename(outfile)
    return outfile

def make_dir(root, name = 'temp'):
    """ generate dirname string
    check if directory exists
    return exists, dir_string
    """
    outdir = os.path.join(root, name)
    if os.path.isdir(outdir)==False:
        os.mkdir(outdir)  
        return outdir    
    else:
        #If outdir exists, rename existing outdirdir with timestamp appended
        mtime = os.path.getmtime(outdir)
        tmestamp = datetime.datetime.fromtimestamp(mtime).strftime('%Y-%m-%d_%H-%M-%S')
        newdir = '_'.join([outdir,tmestamp])
        os.rename(outdir,newdir)
        os.mkdir(outdir)
        print outdir, 'exists, moving to ', newdir
        return newdir


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

    

