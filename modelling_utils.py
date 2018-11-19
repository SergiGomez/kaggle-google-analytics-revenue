import pandas as pd

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
