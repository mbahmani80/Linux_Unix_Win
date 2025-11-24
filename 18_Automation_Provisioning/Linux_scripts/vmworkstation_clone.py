import requests
import json
from requests.auth import HTTPBasicAuth
# https://docs.vmware.com/en/VMware-Workstation-Pro/17/com.vmware.ws.using.doc/GUID-C3361DF5-A4C1-432E-850C-8F60D83E5E2B.html
# (ansible-env)mbahmani@mbctux ~ $ vmrest -C
#VMware Workstation REST API
#Copyright (C) 2018-2024 VMware Inc.
#All Rights Reserved
#
#vmrest 1.3.1 build-23775571
#Username:admin
#New password: Admin123!
#Retype new password:
#Processing...
#Credential updated successfully
#(ansible-env)mbahmani@mbctux ~ $

#(ansible-env)mbahmani@mbctux ~ $ vmrest
#VMware Workstation REST API
#Copyright (C) 2018-2024 VMware Inc.
#All Rights Reserved

#vmrest 1.3.1 build-23775571
#-
#Using the VMware Workstation UI while API calls are in progress is not recommended and may yield #unexpected results.
#-
#Serving HTTP on 127.0.0.1:8697
#-
#Press Ctrl+C to stop.

# VMware Workstation details
vmware_host = 'http://127.0.0.1:8697'
username = 'admin'
password = 'Admin123!'
source_vm_id = 'BOHDOFQC0JEBNO23DGBHSP41JL6DF222'  # The ID of the VM you want to clone
clone_vm_path = '/home/mbahmani/VMWare/'  # The directory where the clones will be stored
vm_names = ['microk8s-controller', 'microk8s-node1', 'microk8s-node2', 'microk8s-node3']  # Names for the cloned VMs

# Base64 encoded credentials
credentials = HTTPBasicAuth(username, password)

# Disable warnings about insecure requests (self-signed SSL certificates)
requests.packages.urllib3.disable_warnings()

def invoke_workstation_rest_request(method, uri, headers, body=None):
    response = requests.request(method, uri, headers=headers, data=json.dumps(body), auth=credentials, verify=False)
    if response.status_code in [200, 201]:
        return response.json()
    else:
        print(f"Request failed: {response.status_code}, {response.text}")
        return None

def select_vm():
    uri = f"{vmware_host}/api/vms"
    headers = {
        'Accept': 'application/vnd.vmware.vmw.rest-v1+json'
    }
    return invoke_workstation_rest_request("GET", uri, headers)

def select_one_vm(vm_id):
    uri = f"{vmware_host}/api/vms/{vm_id}"
    headers = {
        'Accept': 'application/vnd.vmware.vmw.rest-v1+json'
    }
    return invoke_workstation_rest_request("GET", uri, headers)

def new_workstation_vm(source_vm_id, new_vm_name, clone_vm_path):
    uri = f"{vmware_host}/api/vms"
    headers = {
        'Content-Type': 'application/vnd.vmware.vmw.rest-v1+json',
        'Accept': 'application/vnd.vmware.vmw.rest-v1+json'
    }
    body = {
        'name': new_vm_name,
        'parentId': source_vm_id,
        'path': clone_vm_path,
        'powerOn': False
    }
    return invoke_workstation_rest_request("POST", uri, headers, body)

def register_vm(vm_name, vm_path):
    uri = f"{vmware_host}/api/vms/registration"
    headers = {
        'Content-Type': 'application/vnd.vmware.vmw.rest-v1+json',
        'Accept': 'application/vnd.vmware.vmw.rest-v1+json'
    }
    body = {
        'name': vm_name,
        'path': vm_path
    }
    return invoke_workstation_rest_request("POST", uri, headers, body)

def main():
    # List all VMs to verify the source VM exists
    vms = select_vm()
    if vms:
        print("Available VMs:")
        for vm in vms:
            print(f"ID: {vm['id']}, Path: {vm['path']}")
        
        # Check if the source VM exists
        source_vm = None
        for vm in vms:
            if vm['id'] == source_vm_id:
                source_vm = vm
                break
        
        if source_vm:
            # Dictionary to store cloned VM names and IDs
            cloned_vms = {}
            
            # Clone and register VMs for each name in vm_names
            for vm_name in vm_names:
                clone_result = new_workstation_vm(source_vm_id, vm_name, clone_vm_path)
                if clone_result:
                    new_vm_id = clone_result['id']
                    new_vm_path = f"{clone_vm_path}/{vm_name}/{vm_name}.vmx"
                    new_vm = select_one_vm(new_vm_id)
                    print(f"Cloned VM '{vm_name}' Details: {json.dumps(new_vm, indent=2)}")

                    # Register the new VM
                    registration_result = register_vm(vm_name, new_vm_path)
                    if registration_result:
                        print(f"Registered VM '{vm_name}': {json.dumps(registration_result, indent=2)}")
                        # Store cloned VM name and ID in dictionary
                        cloned_vms[vm_name] = new_vm_id
                    else:
                        print(f"Failed to register the cloned VM '{vm_name}'.")
                else:
                    print(f"Failed to clone the VM '{vm_name}'.")
            
            # Print the dictionary of cloned VM names and IDs
            print("Cloned VMs:")
            print(json.dumps(cloned_vms, indent=2))
        else:
            print(f"Source VM with ID '{source_vm_id}' not found.")
    else:
        print("No VMs found.")

if __name__ == "__main__":
    main()


