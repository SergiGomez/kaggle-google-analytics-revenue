import pandas as pd

def processingPreModelling(df):

    # Data Processing before Modelling

    # Bools to int
    df.isMobile = df.isMobile.astype(int)

    # Date objects to datetime format
    df.date = pd.to_datetime(df.date, format='%Y-%m-%d')

    return df
