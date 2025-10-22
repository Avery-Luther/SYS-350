from pyVim.connect import SmartConnect
import getpass
import ssl
import json

#fetching logon informaiton
with open("vcenterConf.json",'r') as rawConfig:
	jsonConfig = rawConfig.read()
	config = json.loads(jsonConfig)
	vcenterConfig = config["vcenter"]
	#print(config)

passw = getpass.getpass()
s = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
s.verify_mode=ssl.CERT_NONE
si = SmartConnect(host=vcenterConfig["vcenterhost"], user=vcenterConfig["vcenteradmin"], pwd=passw,sslContext=s)
serverInfo = si.content.about
sessionInfo = si.content.sessionManager.currentSession
datacenter = si.content.rootFolder.childEntity[0]
vms = datacenter.vmFolder.childEntity

def getVMs(vmname):
	response = []
	if vmname == "":
		for vm in vms:
			if "vm" in str(vm):#filtering out groups
				response.append(vm)
	else:
		for vm in vms:
			if vm.name == vmname:
				response.append(vm)
			else:
				continue
	return(response)
def getVM(): #Gets a single VM
    vmname = ""
    inputLoopCon = True
    while inputLoopCon:
        vmname = input("Enter a VM name:")
        if vmname == None or vmname == "":
            print("Please enter a name")
        else:
            vmList = getVMs(vmname)
            if vmList == []:
                print("Please enter a valid name")
                continue
            else:
                vm = vmList[0]
                inputLoopCon = False
                return vm

#Menu Structure and execution
operation = True
menu = ["Select an option"]
menu += ["1 - Info about this server"]
menu += ["2 - Info about this session"]
menu += ["3 - List VMs"]
menu += ["4 - Toggle Power of a VM"]
menu += ["5 - Take a VM snapshot"]
menu += ["6 - Change the CPU count of a VM"]
menu += ["7 - Clone a VM"]
menu += ["8 - Restore the latest snapshot"]
menu += ["9 - Change a VM's network"]
menu += ["0 - Exit"]

while operation:
	#Print menu
    for i in menu:
        print(i)

    choice = input()
    if choice == "0": # Exit
        print("goodbye")
        operation = False
    elif choice == "1": # Info about the server
    	print(serverInfo)
    elif choice == "2": # Info about the session
    	print("Session ID:", sessionInfo.key)
    	print("Username:", sessionInfo.userName)
    	print("IP Address:", sessionInfo.ipAddress)
    elif choice == "3": # List and filter VMs
    	vmname = ""
    	vmname = input("Enter a name (Empty for all):")
    	vmList = getVMs(vmname)
    	for vm in vmList:
    		print("VM name:", vm.name)
    		print("	PowerState:", vm.summary.runtime.powerState)
    		print("	Number of CPUs:", vm.summary.config.numCpu)
    		print("	Memory: ", str(vm.summary.config.memorySizeMB / 1024) + "GB")
    		if vm.guest.ipAddress == None:
    			print("	IP Address:", "None or VMWare Tools are Uninstalled")
    		else:
    			print("	IP Address:", vm.guest.ipAddress)
    elif choice == "4": #Toggle power
        vm = getVM()
        if vm.summary.runtime.powerState == "poweredOn":
            print("VM powered on, Powering off...")
            vm.PowerOff()
        elif vm.summary.runtime.powerState == "poweredOff":
            print("VM powered off, Powering on...")
            vm.PowerOn()
        else:
            print("Unknown Powerstate. No action taken.")
    elif choice == "5": #Take a snapshot
        vm = getVM()
        inputCon = True
        while inputCon:
            snapShotName = input("Snapshot name?:")
            if snapShotName == "":
                print("Please enter a snapshot name.")
            else:
                inputCon = False
                break
        snapShotDesc = input("Snapshot description?:")
        vm.CreateSnapshot_Task(name=snapShotName,description=snapShotDesc,memory=True,quiesce=False)
            
        
    elif choice == "6": #Change CPU count
        vm = getVM()
        if vm.summary.runtime.powerState == "poweredOn":
            print("VM is powered on. Please shut it down before changing the cpu count.")
            continue
        inputCon = True
        while inputCon:
            newCpuCount = input("Please enter a new CPU count:")
            if newCpuCount.isnumeric():
                newCpuCount = int(newCpuCount)
                if newCpuCount <= 0 or newCpuCount > 5:
                    print("Please enter an integer from 1-5")
                else:
                    print("Changing CPU count")
                    inputCon = False
                    break
            else:
                print("Please enter an integer from 1-5")
    elif choice == "7": #Clone VM
        print("stuff")
    elif choice == "8": #Restore the latest snapshot
        vm = getVM()
        vm.RevertToCurrentSnapshot_Task()
        print("Reverted to current snapshot")
    elif choice == "9": #Change Network
        print("stuff")
    else:
    	print("Please enter a number between 1 and 4")

