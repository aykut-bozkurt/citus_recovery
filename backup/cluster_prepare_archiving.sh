#!/bin/bash

set -euo pipefail

source $(dirname "$0")/../util/config_parser.sh

cluster_cfg=$1

clusterBaseDir=$(get_cluster_base_dir "$cluster_cfg")
archiveBaseDir=$(get_archive_base_dir "$cluster_cfg")
nodes=$(get_all_nodes "$cluster_cfg")

for node in $nodes ; do
	echo $node | base64 --decode

	nodeName=$(get_node_property "$cluster_cfg" "$node" "name")

	# prepare archiving
	echo "archive_mode = on" >> ${clusterBaseDir}/${nodeName}/postgresql.conf
	echo "archive_command = 'test ! -f ${archiveBaseDir}/${nodeName}/%f && cp %p ${archiveBaseDir}/${nodeName}/%f'" >> ${clusterBaseDir}/${nodeName}/postgresql.conf
done
