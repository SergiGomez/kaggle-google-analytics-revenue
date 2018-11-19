import pandas as pd
import numpy as np
import copy
import sys
import datetime as dt
import os

from sklearn.model_selection import train_test_split

import modelling_utils as mu

target_var = 'transactionRevenue'

catVarsDict = {'channelGrouping' : 'BinaryEncoder',
               'browser': 'LabelEncoder',
               'operatingSystem': 'LabelEncoder',
               'deviceCategory': 'OneHot',
               'continent': 'BinaryEncoder',
               'subContinent': 'LabelEncoder',
               'country': 'LabelEncoder',
               'region': 'LabelEncoder',
               'metro': 'LabelEncoder',
               'city': 'LabelEncoder',
               'networkDomain': 'LabelEncoder',
               'campaign': 'LabelEncoder',
               'source': 'LabelEncoder',
               'medium': 'LabelEncoder',
               'sourceMedium': 'LabelEncoder'}

params_lgb = {
        "objective" : "regression",
        "metric" : "rmse",
        "num_leaves" : 40,
        "learning_rate" : 0.005,
        "bagging_fraction" : 0.6,
        "feature_fraction" : 0.6,
        "bagging_frequency" : 6,
        "bagging_seed" : 42,
        "verbosity" : -1,
        "seed": 42}

todayDate = dt.datetime.today().date()
todayDateJoined = dt.datetime.today().strftime('%Y%m%d')

orig_stdout = sys.stdout
f = open('training_task_'+todayDateJoined+ '.log', 'w')
sys.stdout = f

train  = pd.read_csv(os.getcwd() + '/train_set_processed.csv', index_col=0)
test = pd.read_csv(os.getcwd() + '/test_set_processed.csv', index_col=0)

# We merge the test and train sets to ensure that
# we have consistent labels in the two sets
# Before we need a variable that indicates the set that observation belongs to
train['set'] = 'train'
test['set'] = 'test'
# Target variable for the test set is created just for data processing purpose
test[target_var]= 0

all = pd.concat([train,test],axis=0)
print('\nAll Data shape: {} Rows, {} Columns'.format(*all.shape))

print("Categorical variables: " + str(list(all.select_dtypes(include=['object']))))
all = mu.processingPreModelling(df = all, catVarsDict = catVarsDict)
if len(list(all.select_dtypes(include=['object']))) > 0:
    print("Remaining these categorical variables after Processing! " +
            str(list(all.select_dtypes(include=['object']))))


print("-- Training Done --")
