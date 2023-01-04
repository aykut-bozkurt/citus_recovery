#!/bin/bash

set -euo pipefail

source $(dirname "$0")/../util/config_parser.sh

cluster_cfg=$1
clusterBaseDir=$(get_cluster_base_dir "$cluster_cfg")
nodes=$(get_all_nodes "$cluster_cfg")

for node in $nodes ; do
        nodePort=$(get_node_property "$cluster_cfg" "$node" "port")
        nodeHostname=$(get_node_property "$cluster_cfg" "$node" "hostname")
        nodeUsername=$(get_node_property "$cluster_cfg" "$node" "username")
        nodeDbname=$(get_node_property "$cluster_cfg" "$node" "dbname")

	# execute following to go into production mode
	psql -h ${nodeHostname} -p ${nodePort} -U ${nodeUsername} -d ${nodeDbname} -c "select pg_wal_replay_resume()"

	# remove recovery.signal file
	rm -rf ${clusterBaseDir}/recovery.signal
done
