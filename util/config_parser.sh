#!/bin/bash

set -euo pipefail

get_node_property()
{
	config_file=$1
	nodeEncoded=$2
	property=$3

     	nodeProperty=$(echo ${nodeEncoded} | base64 --decode | jq -r ".${property}")
	echo ${nodeProperty}
}

get_cluster_name()
{
        config_file=$1
        clusterName=$(cat "${config_file}" | jq -r '.clusterName')
        echo ${clusterName}
}

get_coordinator()
{
        config_file=$1
        coordinator=$(cat "${config_file}" | jq -r '.coordinatorNode | @base64')
        echo ${coordinator}
}

get_workers()
{
        config_file=$1
        workers=$(cat "${config_file}" | jq -r '.workerNodes[] | @base64')
        echo ${workers}
}

get_all_nodes()
{
	config_file=$1
	coordinator=$(get_coordinator "${config_file}")
	workers=$(get_workers "${config_file}")
	echo "${coordinator}" "${workers}"
}

get_all_node_names()
{
	config_file=$1
	all_nodes=$(get_all_nodes "${config_file}")
	node_names=""

	for node in $all_nodes; do
		name=$(get_node_property "${config_file}" "${node}" "name")
		node_names+=("${name}")
	done

	echo "${node_names[@]}"
}

get_cluster_base_dir()
{
        config_file=$1

        clusterBaseFolder=$(cat "${config_file}" | jq -r '.clusterBaseFolder')
        echo ${clusterBaseFolder}
}

get_backup_base_dir()
{
        config_file=$1

        backupBaseDir=$(cat "${config_file}" | jq -r '.backupBaseFolder')
	echo ${backupBaseDir}
}

get_archive_base_dir()
{
        config_file=$1

        archiveBaseDir=$(cat "${config_file}" | jq -r '.archiveBaseFolder')
        echo ${archiveBaseDir}
}

get_backup_to_restore()
{
        config_file=$1

        backupToRestore=$(cat "${config_file}" | jq -r '.backupToRestore')
        echo ${backupToRestore}
}

get_restore_point()
{
        config_file=$1

        restorePoint=$(cat "${config_file}" | jq -r '.restorePoint')
        echo ${restorePoint}
}

# tests
#get_cluster_name "$1"
#get_coordinator "$1"
#get_workers "$1"
#get_all_nodes "$1"
#get_backup_base_dir "$1"
#get_archive_base_dir "$1"
#get_backup_to_restore "$1"
#get_restore_point "$1"
#get_cluster_base_dir "$1"

#all_nodes=$(get_all_nodes "$1")
#for node in $all_nodes; do
#	echo $(get_node_property "$1" "$node" "name")
#done

#get_all_node_names "$1"
