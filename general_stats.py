import os, sys
import statsmodels.api as sm
import pandas as pd

def load_design(design_file, pattern = 'B[0-9]{2}-[0-9]{3}'):
    X = pd.read_csv(design_file, delimiter='\t')
    for col in X.columns:
        if X[col].dtype == 'object':
            if X[col].str.contains(pattern).values.any():
                X = X.drop([col], axis=1)
    X = sm.add_constant(X, prepend=True)
    return X

def run_ols(y, X):
        ols_model = sm.OLS(y, X)
        ols_results = ols_model.fit()
        return ols_results
        
def run_rlm(y, X, norm = sm.robust.norms.TukeyBiweight()):
        rlm_model = sm.RLM(y, X, M = norm)
        rlm_results = rlm_model.fit()
        return rlm_results
