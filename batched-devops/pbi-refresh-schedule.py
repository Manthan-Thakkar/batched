import requests
import json
from datetime import datetime
import pytz

# Configuration
tenant_id = '52e3b736-bb3a-4585-ba4a-1f43e46bbee3'
client_secret = ''
client_id = '30a67f99-d5fc-45c5-93fe-80f6769c5eb0'

# Auth URL
auth_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token'
auth_data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'https://analysis.windows.net/powerbi/api/.default'
}

# Windows to IANA Timezone Mapping
windows_to_iana = {
    'Dateline Standard Time': 'Etc/GMT+12',
    'UTC-11': 'Etc/GMT+11',
    'Aleutian Standard Time': 'America/Adak',
    'Hawaiian Standard Time': 'Pacific/Honolulu',
    'Marquesas Standard Time': 'Pacific/Marquesas',
    'Alaskan Standard Time': 'America/Anchorage',
    'UTC-09': 'Etc/GMT+9',
    'Pacific Standard Time (Mexico)': 'America/Tijuana',
    'UTC-08': 'Etc/GMT+8',
    'Pacific Standard Time': 'America/Los_Angeles',
    'US Mountain Standard Time': 'America/Phoenix',
    'Mountain Standard Time (Mexico)': 'America/Chihuahua',
    'Mountain Standard Time': 'America/Denver',
    'Central America Standard Time': 'America/Guatemala',
    'Central Standard Time': 'America/Chicago',
    'Easter Island Standard Time': 'Pacific/Easter',
    'Central Standard Time (Mexico)': 'America/Mexico_City',
    'Canada Central Standard Time': 'America/Regina',
    'SA Pacific Standard Time': 'America/Bogota',
    'Eastern Standard Time (Mexico)': 'America/Cancun',
    'Eastern Standard Time': 'America/New_York',
    'Haiti Standard Time': 'America/Port-au-Prince',
    'Cuba Standard Time': 'America/Havana',
    'US Eastern Standard Time': 'America/Indianapolis',
    'Turks And Caicos Standard Time': 'America/Grand_Turk',
    'Paraguay Standard Time': 'America/Asuncion',
    'Atlantic Standard Time': 'America/Halifax',
    'Venezuela Standard Time': 'America/Caracas',
    'Central Brazilian Standard Time': 'America/Cuiaba',
    'SA Western Standard Time': 'America/La_Paz',
    'Pacific SA Standard Time': 'America/Santiago',
    'Newfoundland Standard Time': 'America/St_Johns',
    'Tocantins Standard Time': 'America/Araguaina',
    'E. South America Standard Time': 'America/Sao_Paulo',
    'SA Eastern Standard Time': 'America/Cayenne',
    'Argentina Standard Time': 'America/Buenos_Aires',
    'Greenland Standard Time': 'America/Godthab',
    'Montevideo Standard Time': 'America/Montevideo',
    'Magallanes Standard Time': 'America/Punta_Arenas',
    'Saint Pierre Standard Time': 'America/Miquelon',
    'Bahia Standard Time': 'America/Bahia',
    'UTC-02': 'Etc/GMT+2',
    'Azores Standard Time': 'Atlantic/Azores',
    'Cape Verde Standard Time': 'Atlantic/Cape_Verde',
    'UTC': 'Etc/UTC',
    'GMT Standard Time': 'Europe/London',
    'Greenwich Standard Time': 'Atlantic/Reykjavik',
    'Sao Tome Standard Time': 'Africa/Sao_Tome',
    'Morocco Standard Time': 'Africa/Casablanca',
    'W. Europe Standard Time': 'Europe/Berlin',
    'Central Europe Standard Time': 'Europe/Budapest',
    'Romance Standard Time': 'Europe/Paris',
    'Central European Standard Time': 'Europe/Warsaw',
    'W. Central Africa Standard Time': 'Africa/Lagos',
    'Jordan Standard Time': 'Asia/Amman',
    'GTB Standard Time': 'Europe/Bucharest',
    'Middle East Standard Time': 'Asia/Beirut',
    'Egypt Standard Time': 'Africa/Cairo',
    'E. Europe Standard Time': 'Europe/Chisinau',
    'Syria Standard Time': 'Asia/Damascus',
    'West Bank Standard Time': 'Asia/Hebron',
    'South Africa Standard Time': 'Africa/Johannesburg',
    'FLE Standard Time': 'Europe/Kiev',
    'Israel Standard Time': 'Asia/Jerusalem',
    'Kaliningrad Standard Time': 'Europe/Kaliningrad',
    'Sudan Standard Time': 'Africa/Khartoum',
    'Libya Standard Time': 'Africa/Tripoli',
    'Namibia Standard Time': 'Africa/Windhoek',
    'Arabic Standard Time': 'Asia/Baghdad',
    'Turkey Standard Time': 'Europe/Istanbul',
    'Arab Standard Time': 'Asia/Riyadh',
    'Belarus Standard Time': 'Europe/Minsk',
    'Russian Standard Time': 'Europe/Moscow',
    'E. Africa Standard Time': 'Africa/Nairobi',
    'Iran Standard Time': 'Asia/Tehran',
    'Arabian Standard Time': 'Asia/Dubai',
    'Astrakhan Standard Time': 'Europe/Astrakhan',
    'Azerbaijan Standard Time': 'Asia/Baku',
    'Russia Time Zone 3': 'Europe/Samara',
    'Mauritius Standard Time': 'Indian/Mauritius',
    'Saratov Standard Time': 'Europe/Saratov',
    'Georgian Standard Time': 'Asia/Tbilisi',
    'Volgograd Standard Time': 'Europe/Volgograd',
    'Caucasus Standard Time': 'Asia/Yerevan',
    'Afghanistan Standard Time': 'Asia/Kabul',
    'West Asia Standard Time': 'Asia/Tashkent',
    'Ekaterinburg Standard Time': 'Asia/Yekaterinburg',
    'Pakistan Standard Time': 'Asia/Karachi',
    'Qyzylorda Standard Time': 'Asia/Qyzylorda',
    'India Standard Time': 'Asia/Calcutta',
    'Sri Lanka Standard Time': 'Asia/Colombo',
    'Nepal Standard Time': 'Asia/Katmandu',
    'Central Asia Standard Time': 'Asia/Almaty',
    'Bangladesh Standard Time': 'Asia/Dhaka',
    'Omsk Standard Time': 'Asia/Omsk',
    'Myanmar Standard Time': 'Asia/Rangoon',
    'SE Asia Standard Time': 'Asia/Bangkok',
    'Altai Standard Time': 'Asia/Barnaul',
    'W. Mongolia Standard Time': 'Asia/Hovd',
    'North Asia Standard Time': 'Asia/Krasnoyarsk',
    'N. Central Asia Standard Time': 'Asia/Novosibirsk',
    'Tomsk Standard Time': 'Asia/Tomsk',
    'China Standard Time': 'Asia/Shanghai',
    'North Asia East Standard Time': 'Asia/Irkutsk',
    'Singapore Standard Time': 'Asia/Singapore',
    'W. Australia Standard Time': 'Australia/Perth',
    'Taipei Standard Time': 'Asia/Taipei',
    'Ulaanbaatar Standard Time': 'Asia/Ulaanbaatar',
    'Aus Central W. Standard Time': 'Australia/Eucla',
    'Transbaikal Standard Time': 'Asia/Chita',
    'Tokyo Standard Time': 'Asia/Tokyo',
    'North Korea Standard Time': 'Asia/Pyongyang',
    'Korea Standard Time': 'Asia/Seoul',
    'Yakutsk Standard Time': 'Asia/Yakutsk',
    'Cen. Australia Standard Time': 'Australia/Adelaide',
    'AUS Central Standard Time': 'Australia/Darwin',
    'E. Australia Standard Time': 'Australia/Brisbane',
    'AUS Eastern Standard Time': 'Australia/Sydney',
    'West Pacific Standard Time': 'Pacific/Port_Moresby',
    'Tasmania Standard Time': 'Australia/Hobart',
    'Vladivostok Standard Time': 'Asia/Vladivostok',
    'Lord Howe Standard Time': 'Australia/Lord_Howe',
    'Bougainville Standard Time': 'Pacific/Bougainville',
    'Russia Time Zone 10': 'Asia/Srednekolymsk',
    'Magadan Standard Time': 'Asia/Magadan',
    'Norfolk Standard Time': 'Pacific/Norfolk',
    'Sakhalin Standard Time': 'Asia/Sakhalin',
    'Central Pacific Standard Time': 'Pacific/Guadalcanal',
    'Russia Time Zone 11': 'Asia/Kamchatka',
    'New Zealand Standard Time': 'Pacific/Auckland',
    'UTC+12': 'Etc/GMT-12',
    'Fiji Standard Time': 'Pacific/Fiji',
    'Chatham Islands Standard Time': 'Pacific/Chatham',
    'UTC+13': 'Etc/GMT-13',
    'Tonga Standard Time': 'Pacific/Tongatapu',
    'Samoa Standard Time': 'Pacific/Apia',
    'Line Islands Standard Time': 'Pacific/Kiritimati'
}

def get_access_token():
    response = requests.post(auth_url, data=auth_data)
    response.raise_for_status()
    return response.json().get('access_token')

def convert_to_utc(times, timezone_id):
    iana_tz_name = windows_to_iana.get(timezone_id, 'UTC')
    try:
        local_tz = pytz.timezone(iana_tz_name)
    except pytz.UnknownTimeZoneError:
        local_tz = pytz.utc
        print(f"Warning: Unknown timezone '{timezone_id}', defaulting to UTC")

    utc_times = []
    now = datetime.now()
    
    for t_str in times:
        try:
            h, m = map(int, t_str.split(':'))
            # Create a naive datetime for today at the scheduled time
            dt_local = datetime(now.year, now.month, now.day, h, m)
            
            # Localize it to the dataset's timezone
            dt_aware = local_tz.localize(dt_local)
            
            # Convert to UTC
            dt_utc = dt_aware.astimezone(pytz.utc)
            
            utc_times.append(dt_utc.strftime('%H:%M'))
        except Exception as e:
            utc_times.append(f"{t_str} (Error)")
            
    return utc_times, iana_tz_name

def main():
    try:
        print("Authenticating...")
        token = get_access_token()
        headers = {'Authorization': f'Bearer {token}'}
        print("Authenticated successfully.")
        
        # Get all groups (workspaces)
        groups_url = 'https://api.powerbi.com/v1.0/myorg/groups' 
        groups_res = requests.get(groups_url, headers=headers)
        groups_res.raise_for_status()
        groups = groups_res.json().get('value', [])
        
        print(f"Found {len(groups)} workspaces.")
        
        results = []
        failed_datasets = []

        for group in groups:
            group_id = group['id']
            group_name = group['name']
            print(f"Processing Workspace: {group_name}")
            
            # Get datasets in group
            datasets_url = f'https://api.powerbi.com/v1.0/myorg/groups/{group_id}/datasets'
            datasets_res = requests.get(datasets_url, headers=headers)
            
            if datasets_res.status_code != 200:
                print(f"  Error fetching datasets for group {group_name}: {datasets_res.text}")
                continue
                
            datasets = datasets_res.json().get('value', [])
            
            for dataset in datasets:
                dataset_id = dataset['id']
                dataset_name = dataset['name']
                
                # Only process Sales and Operations KPIs datasets
                if 'Sales and Operations' not in dataset_name:
                    continue

                # Check refresh history for failures
                history_url = f'https://api.powerbi.com/v1.0/myorg/groups/{group_id}/datasets/{dataset_id}/refreshes?$top=1'
                history_res = requests.get(history_url, headers=headers)
                
                if history_res.status_code == 200:
                    history = history_res.json().get('value', [])
                    if history:
                        last_run = history[0]
                        if last_run.get('status') == 'Failed':
                            try:
                                error_detail = json.loads(last_run.get('serviceExceptionJson', '{}'))
                            except:
                                error_detail = last_run.get('serviceExceptionJson')
                            
                            attempts = last_run.get('refreshAttempts', [])
                            attempt_count = len(attempts)
                            
                            failed_datasets.append({
                                'workspace': group_name,
                                'dataset': dataset_name,
                                'error': error_detail,
                                'start_time': last_run.get('startTime'),
                                'attempts': attempt_count,
                                'retry_detected': attempt_count > 1
                            })
                            print(f"  !! REFRESH FAILED for '{dataset_name}' (Attempts: {attempt_count})")
                
                # Get refresh schedule
                schedule_url = f'https://api.powerbi.com/v1.0/myorg/groups/{group_id}/datasets/{dataset_id}/refreshSchedule'
                schedule_res = requests.get(schedule_url, headers=headers)
                
                if schedule_res.status_code == 200:
                    schedule = schedule_res.json()
                    if schedule.get('enabled', False) and schedule.get('times'):
                        days = schedule.get('days', [])
                        times = schedule.get('times', [])
                        timezone = schedule.get('localTimeZoneId', 'UTC')
                        
                        utc_times, iana_tz = convert_to_utc(times, timezone)
                        
                        results.append({
                            'Workspace': group_name,
                            'Dataset': dataset_name,
                            'DatasetID': dataset_id,
                            'Days': days,
                            'Times': times,
                            'TimeZone': timezone,
                            'UTCTime': utc_times,
                            'IANATimeZone': iana_tz
                        })
                        print(f"  Found Schedule for '{dataset_name}': {times} -> UTC: {utc_times}")
                    else:
                        pass
                elif schedule_res.status_code == 404:
                    pass
                else:
                    print(f"  Error fetching schedule for '{dataset_name}': {schedule_res.status_code}")
        
        # Output results
        print("\n" + "="*100)
        print("SCHEDULED REFRESH REPORT (UTC)")
        print("="*100)
        
        if not results:
            print("No scheduled refreshes found.")
        
        # Sort results by first UTC time to help identify clusters
        def get_first_utc(item):
            if item['UTCTime']:
                return item['UTCTime'][0]
            return "23:59"
            
        results.sort(key=get_first_utc)

        for item in results:
            print(f"Workspace: {item['Workspace']}")
            print(f"Dataset:   {item['Dataset']}")
            print(f"Local Time: {', '.join(item['Times'])} ({item['TimeZone']})")
            print(f"UTC Time:   {', '.join(item['UTCTime'])}")
            print(f"Days:      {', '.join(item['Days'])}")
            print("-" * 40)

        # Aggregation by 30-minute intervals
        print("\n" + "="*100)
        print("REFRESH SCHEDULE BY 30-MINUTE INTERVAL (UTC)")
        print("="*100)

        # Initialize buckets for 24 hours
        buckets = {}
        for h in range(24):
            buckets[f"{h:02d}:00"] = []
            buckets[f"{h:02d}:30"] = []

        for item in results:
            for utc_time in item['UTCTime']:
                try:
                    h, m = map(int, utc_time.split(':'))
                    if m < 30:
                        bucket_key = f"{h:02d}:00"
                    else:
                        bucket_key = f"{h:02d}:30"
                    
                    buckets[bucket_key].append(f"{item['Workspace']} - {item['Dataset']} ({utc_time})")
                except ValueError:
                    continue

        for time_slot in sorted(buckets.keys()):
            datasets = buckets[time_slot]
            if datasets:
                end_min = "29" if time_slot.endswith("00") else "59"
                print(f"\nTime Slot: {time_slot} - {time_slot[:3]}{end_min} (Count: {len(datasets)})")
                for ds in datasets:
                    print(f"  - {ds}")

        # Print Failure Report
        if failed_datasets:
            print("\n" + "="*100)
            print("CRITICAL: DATASETS WITH RECENT REFRESH FAILURES")
            print("="*100)
            for fail in failed_datasets:
                print(f"Workspace: {fail['workspace']}")
                print(f"Dataset:   {fail['dataset']}")
                print(f"Status:    FAILED")
                print(f"Last Run:  {fail['start_time']}")
                print(f"Attempts:  {fail['attempts']} (Retry Mechanism Active: {'Yes' if fail['retry_detected'] else 'No'})")
                print(f"Error:     {fail['error']}")
                print("-" * 40)
        else:
             print("\nNo recent refresh failures detected in Sales and Operations reports.")

    except Exception as e:
        print(f"An error occurred: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
