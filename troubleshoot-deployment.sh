#!/bin/bash

    ######################################################################################
	# Script to check Your Deployment and associated resources                           #
	# ####################################################################################


# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'
bold=$(tput bold)
normal=$(tput sgr0)

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    #clear;
	echo -e "${YELLOW}************************************************************************************************"
    echo -e "${BLUE}usage: $0 <type> <product> <component>"
	echo -e "${GREEN}eg $0 java labs rajivkapoor1"
	echo -e "eg $0 java probate submit-service"
	echo -e "${BLUE}Note: In the ${GREEN}Preview ${BLUE}environment the usage is different. You must supply the PR number too"
	echo -e "${BLUE}usage: $0 <type> <product> <component> <pr-id>"
	echo -e "${GREEN}eg $0 java probate submit-service pr-593"
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${BLUE}TIP: You can find the <type>,<product>, and <component> values by looking inside the Jenkins_CNP file"
	echo -e "${YELLOW}************************************************************************************************"
    exit 1
fi

type="$1"
product="$2"
component="$3"

deploy="unset"
helmrelease="unset"
imagerepository="unset"

namespace="$product"

if [ "$#" -eq 4 ]
then
	echo "You have supplied a PR-ID. This is mainly for the Preview environment"
	pr_id="$4"
	deploy="$product-$component-$pr_id-$type"
	helmrelease="$product-$component"
	imagerepository="$namespace/$component"
else
	echo "You are querying the main release"
	deploy="$product-$component-$type"
	helmrelease="$product-$component"
	imagerepository="$namespace/$component"
fi


the_env="unset"
registryname="unset"



sandbox() {
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${BLUE}Switching to Sandbox settings......"
	echo "This option authenticate to the Sandbox environment if you were not already authenticated"	   
	echo "This option will connect to sandbox, and then exit, at which point you will be able to re-run the script and carry on"
	echo "Please follow the instructions. After you have authenticated, the list of namespaces in this environment will be shown.."
	az aks get-credentials --resource-group cft-sbox-00-rg --name cft-sbox-00-aks --subscription DCD-CFTAPPS-SBOX --overwrite-existing
	
	sandboxsettings;

	all_ns_output=$(kubectl get ns | grep -v NAME | awk {'print $1'})
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${GREEN}You have successfully connected to ${BLUE}Sandbox ${GREEN}. This is the list of ${BLUE}namespaces ${GREEN}in this environment..."
	echo -e "${BLUE}$all_ns_output"
	echo -e "${GREEN}Please now run the script again, and choose the Option indicating you are already authenticated. This Option is the one entitled ${BLUE}'Already Authenticated, So Just Carry On..'"
	exit 0
}

preview() {
	the_env="Preview"
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${BLUE}Switching to $the_env settings......"
	echo "This option authenticate to the $the_env environment if you were not already authenticated"	   
	echo "This option will connect to $the_env, and then exit, at which point you will be able to re-run the script and carry on"
	echo "Please follow the instructions. After you have authenticated, the list of namespaces in this environment will be shown.."
	az aks get-credentials --resource-group cft-preview-00-rg --name cft-preview-00-aks --subscription DCD-CFTAPPS-DEV

	previewsettings;
	
	all_ns_output=$(kubectl get ns | grep -v NAME | awk {'print $1'})
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${GREEN}You have successfully connected to ${BLUE}$the_env ${GREEN}. This is the list of ${BLUE}namespaces ${GREEN}in this environment..."
	echo -e "${BLUE}$all_ns_output"
	echo -e "${GREEN}Please now run the script again, and choose the Option indicating you are already authenticated. This Option is the one entitled ${BLUE}'Already Authenticated, So Just Carry On..'"
	exit 0
}

aat() {
	the_env="AAT"
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${BLUE}Switching to $the_env settings......"
	echo "This option authenticate to the $the_env environment if you were not already authenticated"	   
	echo "This option will connect to $the_env, and then exit, at which point you will be able to re-run the script and carry on"
	echo "Please follow the instructions. After you have authenticated, the list of namespaces in this environment will be shown.."
	az aks get-credentials --resource-group cft-aat-00-rg --name cft-aat-00-aks --subscription DCD-CFTAPPS-STG

	aatsettings;

	all_ns_output=$(kubectl get ns | grep -v NAME | awk {'print $1'})
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${GREEN}You have successfully connected to ${BLUE}$the_env ${GREEN}. This is the list of ${BLUE}namespaces ${GREEN}in this environment..."
	echo -e "${BLUE}$all_ns_output"
	echo -e "${GREEN}Please now run the script again, and choose the Option indicating you are already authenticated. This Option is the one entitled ${BLUE}'Already Authenticated, So Just Carry On..'"
	exit 0
}

demo() {
	the_env="Demo"
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${BLUE}Switching to $the_env settings......"
	echo "This option authenticate to the $the_env environment if you were not already authenticated"	   
	echo "This option will connect to $the_env, and then exit, at which point you will be able to re-run the script and carry on"
	echo "Please follow the instructions. After you have authenticated, the list of namespaces in this environment will be shown.."
	az aks get-credentials --resource-group cft-demo-00-rg --name cft-demo-00-aks --subscription DCD-CFTAPPS-DEMO
 
	demosettings;

	all_ns_output=$(kubectl get ns | grep -v NAME | awk {'print $1'})
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${GREEN}You have successfully connected to ${BLUE}$the_env ${GREEN}. This is the list of ${BLUE}namespaces ${GREEN}in this environment..."
	echo -e "${BLUE}$all_ns_output"
	echo -e "${GREEN}Please now run the script again, and choose the Option indicating you are already authenticated. This Option is the one entitled ${BLUE}'Already Authenticated, So Just Carry On..'"
	exit 0
}


sandboxsettings() {
	the_env="Sandbox"	
	az account set --name DCD-CFT-Sandbox
	registryname="hmctssandbox"
	echo -e "${GREEN}You are now using the ${BLUE}$the_env ${GREEN} environment...."
}

previewsettings() {
	the_env="Preview"	
	az account set --name DCD-CNP-Prod
	registryname="hmctspublic"
	echo -e "${GREEN}You are now using the ${BLUE}$the_env ${GREEN} environment...."
}

aatsettings() {
	the_env="AAT"	
	az account set --name DCD-CNP-Prod
	registryname="hmctspublic"
	echo -e "${GREEN}You are now using the ${BLUE}$the_env ${GREEN} environment...."
}

demosettings() {
	the_env="Demo"	
	az account set --name DCD-CNP-Prod
	registryname="hmctspublic"
	echo -e "${GREEN}You are now using the ${BLUE}$the_env ${GREEN} environment...."
}

pod_status() {
	no_of_pods=$(kubectl get po -n $namespace -l $selector | grep -v NAME | wc -l)
             if [[ $no_of_pods -eq 0 ]]
             then
               echo "Deployment $deploy has 0 replicas"
               exit 0
             fi
	pods_status=$(for i in $(kubectl get po -n $namespace -l $selector | grep -v NAME | awk {'print $1" ="$3'} | sort -u); do echo"";echo "$i";done)
	pods_statusraj=$(echo ""; kubectl get po -n $namespace -l $selector)
	restart_count=$(kubectl get po -n $namespace -l $selector | grep -v NAME | awk {'print $4'} | grep -v RESTARTS | sort -ur | awk 'FNR <= 1')

		
	readiness() {
		r=$(kubectl get po -n $namespace | grep $deploy | grep -vE '1/1|2/2|3/3|4/4|5/5|6/6|7/7' &> /dev/null )
	        if [[ $? -ne 0 ]]
	        then
	          echo -e "${BLUE}"Readiness"                 :${GREEN}"ALL Pods are Ready""
	        else
		  echo -e "${BLUE}"Readiness"                 :${RED}"You have some Pods not ready ""
                fi
              }

		echo -e "${YELLOW}************************************************************************************************"
		readiness
		echo -e "${BLUE}"Number of Pods"          :${GREEN}$no_of_pods"
        echo -e "${BLUE}"Pods Status"             :${GREEN}$pods_statusraj"
        echo -e "${BLUE}"MAX Pod Restart Count"   :${GREEN}$restart_count"
		end_message
}

pod_logs() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE}Showing Logs for each pod..."
		echo -e "${YELLOW}************************************************************************************************"
		for i in $(kubectl get po -n $namespace -l $selector | grep -v NAME | awk {'print $1'})
		do
		   echo -e "${YELLOW}************************************************************************************************"
		   echo -e "${BLUE}Logs for pod $i"
		   echo -e "${YELLOW}************************************************************************************************"
		   pod_log_output=$(echo ""; kubectl logs $i -n $namespace)
		   echo -e "${GREEN}$pod_log_output"
		done;
		end_message
}

ns_events() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE}Showing Namespace Events..."
		echo -e "${YELLOW}************************************************************************************************"
		ns_output=$(echo ""; kubectl get events -n $namespace)
		echo -e "${GREEN}$ns_output"
		end_message
}

pod_describe() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE} Describing each pod..."
		echo -e "${YELLOW}************************************************************************************************"
		for i in $(kubectl get po -n $namespace -l $selector | grep -v NAME | awk {'print $1'})
		do
		   echo -e "${YELLOW}************************************************************************************************"
		   echo -e "${BLUE}Describe output for pod $i"
		   echo -e "${YELLOW}************************************************************************************************"
		   descr_output=$(echo ""; kubectl describe po/$i -n $namespace)
		   echo -e "${GREEN}$descr_output"
		done;
		end_message
}

helm_release_status() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE} Showing Helm Release Status..."
		echo -e "${YELLOW}************************************************************************************************"
		#hr_output=$(echo ""; kubectl get helmreleases.helm.toolkit.fluxcd.io/$helmrelease -n $namespace)
		#hr_image=$(echo ""; kubectl get helmreleases.helm.toolkit.fluxcd.io/$helmrelease -n $namespace -o yaml | grep 'image:')
		hr_output=$(echo ""; kubectl get helmrelease/$helmrelease -n $namespace)
		hr_image=$(echo ""; kubectl get helmrelease/$helmrelease -n $namespace -o yaml | grep 'image:')
		echo -e "${GREEN}$hr_output"
		echo -e "${BLUE}This Helm Release has been instructed to deploy the image as.."
		echo -e "${GREEN}$hr_image"
		end_message
}

flux_logs() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE} Showing Kustomise Logs..."
		echo -e "${YELLOW}************************************************************************************************"
		kus_output=$(echo ""; kubectl logs -n flux-system -l app=kustomize-controller --tail=200)
		echo -e "${GREEN}$kus_output"
		end_message
}

show_image_tags() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE} Showing Most Recent Image Tags On Azure Container Registry For Image: $imagerepository"
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${GREEN}.."
		all_image_tags=$(for i in $(az acr repository show-tags -n $registryname --repository $imagerepository --detail --orderby time_desc -o table | grep -v CreatedTime | grep -v '___' | awk {'print $4'});do echo"";echo "$i";done)
		echo -e "${BLUE}Image Tags List On ACR For Image: $imagerepository (Most Recent At The Top)"
		echo -e "${GREEN}$all_image_tags"	
		#hr_image=$(echo ""; kubectl get helmreleases.helm.toolkit.fluxcd.io/$helmrelease -n $namespace -o yaml | grep 'image:')
		hr_image=$(echo ""; kubectl get helmrelease/$helmrelease -n $namespace -o yaml | grep 'image:')
		echo -e "${BLUE}Check that this list correlates with what the Helm Release is Deploying?"
		echo -e "${BLUE}Remember that the Helm Release has been instructed to deploy the image as.."
		echo -e "${GREEN}$hr_image"

		
		end_message
}

show_image_tags_full_info() {
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${BLUE} Showing Most Recent Image Tags On azure Container Registry For Image: $imagerepository : Full Information"
		echo -e "${YELLOW}************************************************************************************************"
		echo -e "${GREEN}.."
		az acr repository show-tags -n $registryname --repository $imagerepository --detail --orderby time_desc -o table
		end_message
}

end_message() {
	echo -e "${YELLOW}************************************************************************************************"
	echo "$titleWithGuidance"
}




check_deployment() {
	echo -e "${YELLOW}************************************************************************************************"
	echo -e "${BLUE}Firstly, Checking Details of Deployment $deploy in namespace $namespace"
	echo -e "${YELLOW}************************************************************************************************"

	kubectl get deploy $deploy -n $namespace &> /dev/null
	status=$?
	if [ $status -ne 0 ]; then
	echo -e "The Deployment $deploy did not exist! \nPlease make sure you provide the correct deployment name and the correct namespace"
	echo -e "You supplied the following:"
	echo -e "${BLUE}type=$type"
	echo -e "${BLUE}product=$product"
	echo -e "${BLUE}component=$component"
	echo -e "${GREEN}TIP 1: Are you sure you are authenticated against the correct environment?"
	echo -e "${GREEN}       Can you see the namespace ${BLUE}$product ${GREEN}in the list of namespaces. Please double check the environment you are connecting to"
	echo -e "${GREEN}TIP 2: Normally the ${BLUE}Namespace ${GREEN}is the same name as ${BLUE}<product> ${GREEN}. However, sometimes it slightly differs.."
	echo -e "${GREEN}       You supplied the <product> as ${BLUE}$product. ${GREEN}Please try and pass in another suitable value for <product> based upon viewing the namespaces below"
	echo -e "${GREEN}To help you, here is the list of ${BLUE}namespaces ${GREEN}in the environment you are currently connecting to..."
	#all_ns_output=$(kubectl get ns | grep -v NAME | awk {'print $1'}')
	all_ns_output=$(kubectl get ns | grep -v NAME | awk {'print $1'})
	echo -e "${BLUE}$all_ns_output"

	exit $status
	fi
}

clear

options=("Authenticate To Sandbox Environment" "Authenticate To Preview Environment" "Authenticate To AAT Environment" "Authenticate To Demo Environment")
title="Select an environment to which to authenticate to, or if ALREADY authenticated, Please choose the option to Just Carry On"
prompt="Pick an option:"
echo -e "${BLUE}$title"
PS3="$prompt "
echo -e "${YELLOW}************************************************************************************************"
select opt in "${options[@]}" "Already Authenticated, So Just Carry On.."; do 
    case "$REPLY" in
    1) 
	   echo "You picked $opt which is option 1"
	   sandbox
	   ;;
	2) 
	   echo "You picked $opt which is option 2"
	   preview
	   ;;
	3) 
	   echo "You picked $opt which is option 3"
	   aat
	   ;;
	4) 
	   echo "You picked $opt which is option 4"
	   demo
	   ;;
    $((${#options[@]}+1))) echo "Carrying On..."; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
done

options=("Use Sandbox Environment" "Use Preview Environment" "Use AAT Environment" "Use Demo Environment")
title="Now you have connected, Select the ${GREEN}same ${BLUE}environment that you are currently authenticated against, before using this script..."
prompt="Pick an option:"
echo -e "${BLUE}$title"
PS3="$prompt "
echo -e "${YELLOW}************************************************************************************************"
select opt in "${options[@]}" "Quit.."; do 
    case "$REPLY" in
    1) 
	   echo "You picked $opt which is option 1"
	   sandboxsettings
	   break
	   ;;
	2) 
	   echo "You picked $opt which is option 2"
	   previewsettings
	   break
	   ;;
	3) 
	   echo "You picked $opt which is option 3"
	   aatsettings
	   break
	   ;;
	4) 
	   echo "You picked $opt which is option 4"
	   demosettings
	   break
	   ;;
    $((${#options[@]}+1))) echo "Carrying On..."; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
done


var=$(kubectl get deployment -n ${namespace} --output=json ${deploy} | \
             jq -j '.spec.selector.matchLabels | to_entries | .[] | "\(.key)=\(.value),"')
selector=${var%?}


options=("Deployment/Pod Health" "Pod Logs" "Namespace Events" "Decribe Pods" "Helm Release Status" "Show Recent ACR Image Tags" "Show Recent ACR Image Tags(FullInfo)" "Kustomise Controller Logs")
title="Select an option for $deploy in namespace $namespace"
titleWithGuidance="Select an option for $deploy in namespace $namespace. (Clock ENTER to show the Options)"

#First of all check the deployment....
check_deployment;

prompt="Pick an option:"
echo -e "${BLUE}$title"
PS3="$prompt "
echo -e "${YELLOW}************************************************************************************************"
select opt in "${options[@]}" "Quit"; do 
    case "$REPLY" in
    1) 
	   echo "You picked $opt which is option 1"
	   pod_status
	   ;;
    2) 
	   echo "You picked $opt which is option 2"
	   pod_logs
	   ;;
    3) echo "You picked $opt which is option 3"
	   ns_events
	   ;;
	4) echo "You picked $opt which is option 4"
	   pod_describe
	   ;;
	5) echo "You picked $opt which is option 5"
	   helm_release_status
	   ;;
	6) echo "You picked $opt which is option 6"
	   show_image_tags
	   ;;
	7) echo "You picked $opt which is option 7"
	   show_image_tags_full_info
	   ;;
	8) echo "You picked $opt which is option 8"
	   flux_logs
	   ;;
    $((${#options[@]}+1))) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
done



