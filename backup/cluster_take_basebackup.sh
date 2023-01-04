#!/bin/bash

set -euo pipefail

source $(dirname "$0")/../util/config_parser.sh

cluster_cfg=$1

backupBaseDir=$(get_backup_base_dir "$cluster_cfg")
backupName=$(get_backup_to_restore "$cluster_cfg")
nodes=$(get_all_nodes "$cluster_cfg")

for node in $nodes ; do
	echo ${node} | base64 --decode
	nodeName=$(get_node_property "$cluster_cfg" "$node" "name")
	nodeHostname=$(get_node_property "$cluster_cfg" "$node" "hostname")
	nodePort=$(get_node_property "$cluster_cfg" "$node" "port")
	nodeUsername=$(get_node_property "$cluster_cfg" "$node" "username")
	nodeDbname=$(get_node_property "$cluster_cfg" "$node" "dbname")

	# take backup
	pg_basebackup -D ${backupBaseDir}/${nodeName}/${backupName} -Ft -h ${nodeHostname} -d postgres://${nodeUsername}@${nodeHostname}:${nodePort}/${nodeDbname} --checkpoint=fast
done
