import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

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
    
def plot_scatter(df, x, y, xticklabels, outfile, title=None, palette=None):
    sns.set(style="ticks", context="talk", palette='Set1')
    sns.lmplot(x, y, df, color='Group', 
                x_jitter=.15, x_partial=['Age','GM'], ci=None,
                palette=palette,scatter_kws=dict(marker='o'),
                line_kws=dict(linewidth=2))
    plt.xticks(np.arange(7), xticklabels, size=18)
    plt.xlabel(x, fontsize=24, labelpad=15)
    plt.ylabel(y, fontsize=24)
    plt.tick_params(direction='out', width=1)
    plt.tight_layout()
    #plt.legend(loc='best', fancybox=True).get_frame().set_alpha(0.7)
    plt.subplots_adjust(top=0.92)
    lgd = plt.legend(loc='upper center', bbox_to_anchor=(0.5, 1.15), ncol=2, prop={'size':20})
    sns.despine()   
    plt.savefig(outfile, dpi=300) 
    
def plot_pyplot_bar(df, error, outfile, title=None):    
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
    ax.set_ylabel('Z Score', fontweight='bold')
    ax.set_xlabel('Group', fontweight='bold', labelpad=15)
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
   
def plot_pandas_bar(df, error, outfile, title=None):
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    sns.set(style="darkgrid", context="poster", palette='Set1')
    df.plot(kind='bar', ax=ax, sort_columns=False)
    plt.xlabel(ax.get_xlabel(), fontweight='bold', labelpad=15)
    ax.set_ylabel('Z Score', fontweight='bold')
    plt.tight_layout()
    # Shink current axis by 20%
    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])
    # Put a legend to the right of the current axis
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5), fancybox=True)
    plt.savefig(outfile)