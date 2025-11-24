#!/usr/bin/env python

def calculate_volume_extension():
    """Calculates the required volume extension to reach a target usage percentage.

    Returns:
        The required volume extension in GiB.
    """
    
    total_size = float(input("Enter the total size of the volume in GiB: "))
    used_percent = float(input("Enter the current percentage of used space: "))
    
    target_usage_percent = 70  # Target usage percentage
    current_used_space = total_size * (used_percent / 100)
    target_total_size = current_used_space / (target_usage_percent / 100)
    required_extension = target_total_size - total_size
    
    return round(required_extension, 2)

if __name__ == "__main__":
    extension_size = calculate_volume_extension()
    print(f"You need to extend your volume by {extension_size} GiB.")
