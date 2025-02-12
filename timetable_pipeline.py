import os
import json
import requests
import zipfile
import glob
import shutil
from datetime import datetime

def check_existing_download():
    """Checks if today's timetable zip file already exists and is valid."""
    today_str = datetime.today().strftime("%Y%m%d")
    zip_filename = f"{today_str}_timetable.zip"
    return os.path.exists(zip_filename) and os.path.getsize(zip_filename) > 50 * 1024 * 1024

def get_api_token():
    """
    Retrieves an authentication token from the National Rail API.
    Credentials are stored in auth.json (excluded via .gitignore for security).
    """
    with open("auth.json", "r") as f:
        auth = json.load(f)
    
    url = "https://opendata.nationalrail.co.uk/authenticate"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = {"username": auth["username"], "password": auth["password"]}
    
    response = requests.post(url, headers=headers, data=data)
    response.raise_for_status()
    return response.json().get("token")

def download_timetable(token):
    """Downloads the latest timetable zip file and extracts it."""
    url = "https://opendata.nationalrail.co.uk/api/staticfeeds/3.0/timetable"
    headers = {"X-Auth-Token": token}
    
    today_str = datetime.today().strftime("%Y%m%d")
    zip_filename = f"{today_str}_timetable.zip"
    extract_folder = f"{today_str}_timetable"
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    with open(zip_filename, "wb") as f:
        f.write(response.content)
    
    with zipfile.ZipFile(zip_filename, "r") as zip_ref:
        zip_ref.extractall(extract_folder)
    
    # Find the MCA file in the extracted folder
    mca_files = glob.glob(os.path.join(extract_folder, "*.MCA"))
    if not mca_files:
        raise FileNotFoundError("No MCA file found in extracted timetable.")
    
    return mca_files[0]

def parse_locations(mca_file):
    """Extracts locations from the MCA file."""
    locations = []
    with open(mca_file, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("TI"):
                tiploc = line[2:9].strip()
                atoc_code = line[53:56].strip()
                station_name = line[18:44].strip()
                
                locations.append((tiploc, atoc_code, station_name))
    
    return locations

def parse_trains_and_stops(mca_file, valid_tiplocs):
    """Parses train headers and stops, including TOC code from BX records."""
    trains = []
    stops = []
    
    with open(mca_file, "r", encoding="utf-8") as f:
        train_id = None
        line_num = 0
        lines = f.readlines()
        
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if line.startswith("BS"):
                train_id = len(trains) + 1
                trans_typ = line[2]
                uid = line[3:9].strip()
                start_date = line[9:15]
                end_date = line[15:21]
                days_run = [int(b) for b in line[21:28]]
                
                toc_code = None
                if i + 1 < len(lines) and lines[i + 1].startswith("BX"):
                    bx_line = lines[i + 1].strip()
                    toc_code = bx_line[11:13].strip()
                    i += 1  # Skip BX line since we just processed it
                
                trains.append((train_id, trans_typ, uid, start_date, end_date, *days_run, toc_code))
                line_num = 0  # Reset line number per train
            elif line.startswith(("LO", "LI", "LT")) and train_id:
                tiploc = line[2:9].strip()
                if tiploc in valid_tiplocs:
                    sched_arr = line[10:14].strip() or None
                    sched_dep = line[15:19].strip() or None
                    
                    if sched_arr is not None or sched_dep is not None:
                        stops.append((train_id, line_num, tiploc, sched_arr, sched_dep))
                        line_num += 1
            i += 1
    
    return trains, stops

def save_csv(data, filename, headers):
    """Saves data to a CSV file."""
    with open(filename, "w", encoding="utf-8") as f:
        f.write(",".join(headers) + "\n")
        for row in data:
            f.write(",".join(map(str, row)) + "\n")

def main():
    """Main pipeline function."""
    today_str = datetime.today().strftime("%Y%m%d")
    zip_filename = f"{today_str}_timetable.zip"
    output_folder = f"{today_str}_output"
    output_zip = f"{output_folder}.zip"
    
    if not check_existing_download():
        print("Getting API token")
        token = get_api_token()
        print("Downloading")
        mca_file = download_timetable(token)
    else:
        print("Using existing download")
        extract_folder = f"{today_str}_timetable"
        mca_files = glob.glob(os.path.join(extract_folder, "*.MCA"))
        if not mca_files:
            raise FileNotFoundError("No MCA file found in extracted timetable.")
        mca_file = mca_files[0]
    
    # Remove old output folders and zip
    for folder in [output_folder, output_zip]:
        if os.path.exists(folder):
            if os.path.isdir(folder):
                shutil.rmtree(folder)
            else:
                os.remove(folder)
    print("Cleaned up any old output")
    
    os.makedirs(output_folder, exist_ok=True)
    
    locations = parse_locations(mca_file)
    valid_tiplocs = {loc[0] for loc in locations}  # Get valid TIPLOCs
    print(f"Parsed {len(valid_tiplocs)} locations")
    
    trains, stops = parse_trains_and_stops(mca_file, valid_tiplocs)
    print(f"Parsed {len(trains)} trains and {len(stops)} stops")
    
    save_csv(locations, os.path.join(output_folder, "locations.csv"), ["tiploc", "atoc_code", "station_name"])
    save_csv(trains, os.path.join(output_folder, "trains.csv"), ["train_id", "trans_typ", "uid", "start_date", "end_date", "mon", "tue", "wed", "thu", "fri", "sat", "sun", "toc_code"])
    save_csv(stops, os.path.join(output_folder, "stops.csv"), ["train_id", "line_num", "tiploc", "sched_arr", "sched_dep"])
    print("Built output files")
    
    # Zip the output with compression
    with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED) as zipf:
        for file in os.listdir(output_folder):
            zipf.write(os.path.join(output_folder, file), file)
    print("Zipped output")
    
if __name__ == "__main__":
    main()
