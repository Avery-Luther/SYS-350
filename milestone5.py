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

#Menu Structure and execution
operation = True
menu = ["Select an option"]
menu += ["1 - Info about this server"]
menu += ["2 - Info about this session"]
menu += ["3 - List VMs"]
menu += ["4 - Exit"]

while operation:
	#Print menu
	for i in menu:
		print(i)

	choice = input()
	if choice == "4": # Exit
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
	else:
		print("Please enter a number between 1 and 4")


