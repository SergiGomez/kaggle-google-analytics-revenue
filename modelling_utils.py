import pandas as pd

from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import LabelBinarizer

import lightgbm as lgb

import category_encoders

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

def run_lgb(X_train, y_train, X_val, y_val, X_test, params_lgb = {}):

    lgb_train_data = lgb.Dataset(X_train, label=y_train)
    lgb_val_data = lgb.Dataset(X_val, label=y_val)

    model = lgb.train(params, lgb_train_data,
                      num_boost_round=5000,
                      valid_sets=[lgb_train_data, lgb_val_data],
                      early_stopping_rounds=100,
                      verbose_eval=500)

    y_pred_train = model.predict(X_train, num_iteration=model.best_iteration)
    y_pred_val = model.predict(X_val, num_iteration=model.best_iteration)
    y_pred_submit = model.predict(X_test, num_iteration=model.best_iteration)

    print(f"LGBM: RMSE val: {rmse(y_val, y_pred_val)}  - RMSE train: {rmse(y_train, y_pred_train)}")
    return y_pred_submit, model
