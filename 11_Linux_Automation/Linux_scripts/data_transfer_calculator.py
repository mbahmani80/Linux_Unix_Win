import sys

def calculate_transfer_time(total_data_TB, copy_speed_MBps):
    # Convert total data to MB for calculation
    total_data_MB = total_data_TB * 1024 * 1024

    # Calculate the time required in seconds
    time_required_seconds = total_data_MB / copy_speed_MBps

    # Convert the time to days for better readability
    time_required_days = time_required_seconds / (3600 * 24)

    return time_required_days

def print_usage():
    print("Usage: python script.py <total_data_TB> <copy_speed_MBps>")
    print("Calculate the time required to transfer data.")
    print()
    print("Arguments:")
    print("  total_data_TB      Total data to be transferred in terabytes (TB)")
    print("  copy_speed_MBps    Copy speed in megabytes per second (MB/s)")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print_usage()
        sys.exit(1)

    try:
        total_data_TB = float(sys.argv[1])
        copy_speed_MBps = float(sys.argv[2])
    except ValueError:
        print("Please provide valid numerical values for total_data_TB and copy_speed_MBps.")
        sys.exit(1)

    time_required_days = calculate_transfer_time(total_data_TB, copy_speed_MBps)

    print(f"To transfer {total_data_TB} TB of data at a speed of {copy_speed_MBps} MB/s, it will take approximately {time_required_days:.2f} days.")
