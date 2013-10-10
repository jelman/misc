import pandas as pd
import os, sys
import matplotlib.pyplot as plt
from scipy import polyfit
from scipy import polyval
sys.path.insert(0, '/home/jagust/jelman/CODE/GIFT_analysis')
import gift_utils as gu



if __name__ == '__main__':


    datadir = '/home/jagust/rsfmri_ica/results/ROI/PIB_Index'
    infile = os.path.join(datadir, 'ROI_Data.csv')


    
    data = pd.read_csv(infile, sep='\t')
    groupcolors = [data.Group[i].replace('Old','r').replace('Young','b') for i in range(len(data.Group))]

    #nuisance = data[['Age_log', 'Scanner', 'Motion_log','pve_GM_log']]
    x = olddata[design_cols]

    for roi in data.columns[7:]:
        fig = plt.figure()
        ax = fig.add_subplot(111)
        y = data[roi]
    #    betah, Yfitted, resid = gu.glm(nuisance.values, y.values)
    #    (m,b)=polyfit(x,resid,1)
        (m,b)=polyfit(x,y,1)
        yp = polyval([m,b],x)
        plt.plot(x,yp)
    #    plt.scatter(x,resid,c=groupcolors)
        plt.scatter(x,y,c=groupcolors)
        plt.xlabel('PIB Index (log)')
        plt.ylabel('Functional Connecticity')
        plt.title(roi)
        pr = plt.Circle((0, 0), radius=1, fc='r')
        pb = plt.Circle((0, 0), radius=1, fc='b')
        plt.legend([pr, pb], ['Old', 'Young'])
        outfile = os.path.join(datadir, roi + '.png')
        plt.savefig(outfile, format='png')

