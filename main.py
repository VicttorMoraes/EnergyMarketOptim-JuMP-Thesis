import os
import glob
import pandas as pd
from datetime import datetime

def write_revenue_into_single_file():
    # Import analysis 1
    revDA_1 = pd.read_csv("revenueDA_1.csv")
    revRT_1 = pd.read_csv("revenueRT_1.csv")

    # Import analysis 2
    revDA_2 = pd.read_csv("revenueDA_2.csv")
    revRT_2 = pd.read_csv("revenueRT_2.csv")

    with pd.ExcelWriter(f'results_{datetime.now().strftime("%Y-%m-%d")}.xlsx') as writer:  
        revDA_1.to_excel(writer, sheet_name='revenueDA_1')
        revRT_1.to_excel(writer, sheet_name='revenueRT_1')
        revDA_2.to_excel(writer, sheet_name='revenueDA_2')
        revRT_2.to_excel(writer, sheet_name='revenueRT_2')
    
    return 

def delete_revenue_files():
    # For the current working directory, you can use '.'
    directory_path = '.'

    # Use glob to get all files with names containing 'revenue' and ending in '.csv'
    files_to_delete = glob.glob(os.path.join(directory_path, '*revenue*.csv'))

    for file in files_to_delete:
        try:
            os.remove(file)
            print(f"Deleted {file}")
        except Exception as e:
            print(f"Error deleting {file}. Reason: {e}")

    return 

if __name__ == "__main__":
    write_revenue_into_single_file()
    delete_revenue_files()