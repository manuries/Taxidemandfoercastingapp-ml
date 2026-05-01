import pandas as pd

# Path to your big dataset
file_path = r"C:\Users\hp\Desktop\Machine learning Cw\taxi-demand-project\yellow_tripdata_2015-01.csv"

# Read only the first 1500 rows
df_small = pd.read_csv(file_path, nrows=1500)

# Save to a proper CSV file (not a folder!)
output_path = r"C:\Users\hp\Desktop\Machine learning Cw\taxi-demand-project\yellow_tripdata_small.csv"
df_small.to_csv(output_path, index=False)

print("Saved yellow_tripdata_small.csv with 1500 rows")
