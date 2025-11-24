import os
import zipfile
from datetime import datetime, timedelta

class LogManager:
    def __init__(self, log_file_base):
        self.log_file_base = log_file_base
        self.directory, self.base_name = os.path.split(log_file_base)
    
    def update_log(self, message):
        # Ensure the directory exists
        if not os.path.exists(self.directory):
            os.makedirs(self.directory)
        
        # Get the current date and time
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        # Define the log file name with the current date
        log_file = os.path.join(self.directory, f"{self.base_name}_{current_date}.txt")
        
        # Format the log entry
        log_entry = f"{current_time} - {message}\n"
        
        # Open the log file in append mode and write the log entry
        with open(log_file, 'a') as file:
            file.write(log_entry)
    
    def zip_old_logs(self):
        # Define the zip file name
        zip_file_name = os.path.join(self.directory, f"{self.base_name}_logs.zip")
        
        # Ensure the directory exists
        if not os.path.exists(self.directory):
            os.makedirs(self.directory)
        
        # Calculate the date 7 days ago
        seven_days_ago = datetime.now() - timedelta(days=7)
        
        # Create a zip file
        with zipfile.ZipFile(zip_file_name, 'a') as zipf:
            # Iterate over all files in the directory
            for file_name in os.listdir(self.directory):
                # Check if the file matches the base name and is older than 7 days
                if file_name.startswith(self.base_name) and file_name.endswith('.txt'):
                    file_date_str = file_name[len(self.base_name) + 1:-4]
                    file_date = datetime.strptime(file_date_str, "%Y-%m-%d")
                    if file_date < seven_days_ago:
                        # Add the file to the zip archive
                        zipf.write(os.path.join(self.directory, file_name), file_name)
                        # Optionally, delete the original log file after zipping
                        os.remove(os.path.join(self.directory, file_name))

class ExampleClass:
    def __init__(self, log_file_base):
        # Create an instance of LogManager
        self.log_manager = LogManager(log_file_base)
        # Example attributes
        self.stg_name = "StorageName"
        self.stg_uuid = "UUID1234"
        self.stg_version = "v1.0"
        self.stg_mgmt_ip = "192.168.1.1"
        self.stg_timezone = "UTC"
        self.local_config_state = "Configured"
    
    def perform_task(self):
        # Create the message string with all the details
        message = (
            f"stg_name: {self.stg_name}\n"
            f"stg_uuid: {self.stg_uuid}\n"
            f"stg_version: {self.stg_version}\n"
            f"stg_mgmt_ip: {self.stg_mgmt_ip}\n"
            f"stg_timezone: {self.stg_timezone}\n"
            f"Metro Cluster Local config state: {self.local_config_state}"
        )
        
        # Log the message
        self.log_manager.update_log(message)

    def archive_logs(self):
        # Archive old log files
        self.log_manager.zip_old_logs()

# Example usage
example = ExampleClass('../log/example_log')
example.perform_task()
example.archive_logs()

