import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
import general_stats as gs
import statsmodels as sm

def cs109_style():
    from matplotlib import rcParams
    #colorbrewer2 Dark2 qualitative color table
    dark2_colors = brewer2mpl.get_map('Dark2', 'Qualitative', 7).mpl_colors
    
    rcParams['figure.figsize'] = (10, 6)
    rcParams['figure.dpi'] = 150
    rcParams['axes.color_cycle'] = dark2_colors
    rcParams['lines.linewidth'] = 2
    rcParams['axes.facecolor'] = 'white'
    rcParams['font.size'] = 14
    rcParams['patch.edgecolor'] = 'white'
    rcParams['patch.facecolor'] = dark2_colors[0]
    rcParams['font.family'] = 'StixGeneral'

def remove_border(axes=None, top=False, right=False, left=True, bottom=True):
    """
    Minimize chartjunk by stripping out unnecesasry plot borders and axis ticks
    
    The top/right/left/bottom keywords toggle whether the corresponding plot border is drawn
    """
    ax = axes or plt.gca()
    ax.spines['top'].set_visible(top)
    ax.spines['right'].set_visible(right)
    ax.spines['left'].set_visible(left)
    ax.spines['bottom'].set_visible(bottom)
    
    #turn off all ticks
    ax.yaxis.set_ticks_position('none')
    ax.xaxis.set_ticks_position('none')
    
    #now re-enable visibles
    if top:
        ax.xaxis.tick_top()
    if bottom:
        ax.xaxis.tick_bottom()
    if left:
        ax.yaxis.tick_left()
    if right:
        ax.yaxis.tick_right()

def plot_line(df, xticklabels, outfile, title=None):
    """
    Line plot with separate lines for each group. Takes a grouped
    pandas dataframe as input.

    Parameters:
    -----------
    df : pandas dataframe
        Should by a grouped and aggregated dataframe. If columns 
        are to be x axis, then needs to be transposed. 
    xticklabels : list
        Labels for x axis
    outfile : str
        File path for output image
    title : str
        Optional title for chart
    """
    sns.set(style="ticks", context="poster", palette='Set1')
    ax = df.plot(title=title, marker='o')
    ax.set_ylabel('Z Score', fontweight='bold')
    ax.set_xticks(range(len(xticklabels)))
    ax.set_xticklabels(xticklabels)
    plt.tight_layout()
    plt.legend(loc='best', prop={'size':12}, fancybox=True).get_frame().set_alpha(0.7)
    sns.despine()
    plt.savefig(outfile, dpi=300)
    
def plot_scatter(df, x, y, covariates, outfile, groupvar=None, xlabel=None, ylabel=None, xticklabels=None, jitter=None, title=None, palette=None):
    """
    Scatter plot with partial regression lines. Takes a 
    long pandas 
    dataframe and plots different color markers and regression
    lines for each group.

    Parameters:
    -----------
    df : pandas dataframe
        dataframe in long format (one row per condition)
    x : str
        Name of column in dataframe to be plotted on x axis
    y : str
        Name of column in dataframe to be plotted on y axis 
        (dependent variable)
    covariates : list
        List of variables in dataframe to act as covariates, 
        will be partialed out before plotting
    xticklabels : list
        Names of by plotted along x axis tick marks
    outfile : str
        File path to save image to
    groupvar : str
        Name of column to determine color grouping
    xlabel : str
        Label for x axis (optional)
    ylabel : str
        Label for y axis (optional)
    title : str
        Optional title of graph
    palette : list/str
        Valid matplotlib palette or list of hex colors (optional)
        
    Note: Legend is placed along top of chart in two columns. This may
        need to be changed.
    """

    sns.set(style="ticks", context="talk", palette=palette)
    sns.lmplot(x, y, df, color=groupvar, 
                x_jitter=jitter, x_partial=covariates, ci=None,
                palette=palette,scatter_kws=dict(marker='o'),
                line_kws=dict(linewidth=2))
    if xticklabels:
        plt.xticks(np.arange(7), xticklabels, size=18)
    plt.xlabel(xlabel, fontsize=20, labelpad=15)
    plt.ylabel(ylabel, fontsize=20)
    t = plt.title(title, fontsize=18)
    t.set_y(1.02)
    plt.tick_params(direction='out', width=1)
    plt.tight_layout()
    #plt.legend(loc='best', fancybox=True).get_frame().set_alpha(0.7)
    plt.subplots_adjust(top=0.92)
    lgd = plt.legend(loc='upper center', bbox_to_anchor=(0.5, 1.15), 
                        ncol=2, prop={'size':20})
    sns.despine()   
    plt.savefig(outfile, dpi=300) 
    
def robust_regression_plot(x, y, x_idx, outfile, xlabel=None, ylabel=None, title=None):
    """
    Runs robust regression on a given dependent variable and design matrix. Plots
    results of a specified variable with covariates partialed out.
    
    Parameters:
    ------------
    x : pandas dataframe
        m x n design matrix, where m is observations and n is variables. The 
        intercept is not automatically included, should be contained in design.
    y : array
        Dependent variable to be regressed on x. 1D array or pandas Series. 
    x_idx : int
        Index of variable to be plotted within design matrix.
    outfile : str
        File path to save image to
    xlabel : str
        Label for x axis (optional)
    ylabel : str
        Label for y axis (optional)
    title : str
        Optional title of graph
    """   
    sns.set(style="ticks", context="talk")
    f, ax = plt.subplots()
    rlm_results = gs.run_rlm(y, x)
    sm.graphics.regressionplots.plot_ccpr(rlm_results, x_idx, ax=ax)
    ax.set_xlabel(xlabel, fontsize=24, labelpad=15)
    ax.set_ylabel(ylabel, fontsize=24)
    ax.set_title(title)
    plt.tick_params(direction='out', width=1)
    plt.tight_layout()
    sns.despine()   
    plt.savefig(outfile, dpi=300) 
    
def plot_pyplot_bar(df, error, ylabel, xlabel, outfile, title=None):    
    """
    Bar chart of multiple groups and conditions with error bars.

    Parameters:
    -----------
    df : pandas dataframe
        Aggregated grouped dataframe containing means of each group
    error : pandas dataframe
        Aggregated grouped dataframe containing error 
        (i.e. SD, SE) of each group
    ylabel : str
        y axis label
    xlabel : str
        x axis label
    oufile : str
        File path to save image
    title : str
        Optional title of graph
    """
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    #sns.set(style="darkgrid", context="poster")
    sns.set(style="ticks", context="poster", palette='Set1')
    N = len(df)
    width = 0.25
    ind = np.arange(N) + width/2
    groups = len(df.ix[0])
    for group in range(groups):
        groupind = ind + (group * width)
        rects = ax.bar(groupind, df.iloc[:,group], width,
                    color=sns.color_palette()[group], 
                    label=col_labels[group],
                    yerr=error.iloc[:,group],
                    error_kw=dict(capsize=5))
    ax.set_ylabel(ylabel, fontweight='bold')
    ax.set_xlabel(xlabel, fontweight='bold', labelpad=15)
    ax.set_xticks(ind+width)
    ax.set_xticklabels(df.index)
    if title:
        ax.set_title(title)
    plt.tight_layout()
    handles, labels = ax.get_legend_handles_labels()
    lgd = ax.legend(handles, labels, loc='best', prop={'size':12}, fancybox=True).get_frame().set_alpha(0.7)
    ax.axhline(color='black', linestyle='--')
    sns.despine()
    plt.savefig(outfile)    
    
