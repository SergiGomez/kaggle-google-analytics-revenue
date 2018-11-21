import pandas as pd

from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import LabelBinarizer
from sklearn.metrics import mean_squared_error

import lightgbm as lgb

import category_encoders

def rmse(y_true, y_pred):
    return round(np.sqrt(mean_squared_error(y_true, y_pred)), 5)

def processingPreModelling(df, catVarsDict = {}):

    # Data Processing before Modelling

    # Bools to int
    df.isMobile = df.isMobile.astype(int)

    # Date objects to datetime format
    df.date = pd.to_datetime(df.date, format='%Y-%m-%d')

    for var , value in catVarsDict.items():

        if (value == 'BinaryEncoder'):
            encoder = category_encoders.BinaryEncoder(cols = [var],
                                        drop_invariant = True,
                                        return_df = True)
            df = encoder.fit_transform(df)
        elif (value == 'LabelEncoder'):
            df[var] = LabelEncoder().fit_transform(df[var])
        elif (value == 'OneHot'):
            encoder = category_encoders.one_hot.OneHotEncoder(cols = [var],
                                        drop_invariant = True,
                                        return_df = True,
                                        use_cat_names = True)
            df = encoder.fit_transform(df)

    return df

def do_training(train_X, train_y, val_X, val_y, model_name, params):

    if model_name == 'lgb':

        lgb_train = lgb.Dataset(train_X, label = train_y)
        lgb_val = lgb.Dataset(val_X, label = val_y)

        model = lgb.train(params,
                          lgb_train,
                          num_boost_round=500,
                          valid_sets=[lgb_train, lgb_val],
                          early_stopping_rounds=100,
                          verbose_eval=50)

        train_y_pred = model.predict(train_X, num_iteration = model.best_iteration)
        val_y_pred = model.predict(val_X, num_iteration = model.best_iteration)
        print(f"LGBM: RMSE val: {rmse(val_y, val_y_pred)}  - RMSE train: {rmse(train_y, train_y_pred)}")

    return model

def prepare_submission(test_X, test_y_pred, filename = 'submit.csv'):

    submission = test_X[['fullVisitorId']].copy()
    submission.loc[:, 'PredictedLogRevenue'] = test_y_pred
    grouped_submission = submission[['fullVisitorId', 'PredictedLogRevenue']].groupby('fullVisitorId').sum().reset_index()
    grouped_submission.to_csv(filename,index=False)    
