#!/bin/bash

set -euo pipefail

source $(dirname "$0")/../util/config_parser.sh

cluster_cfg=$1

backupBaseDir=$(get_backup_base_dir "$cluster_cfg")
restorePointName=$(get_restore_point "$cluster_cfg")

coordinator=$(get_coordinator "$cluster_cfg")
coordinator_username=$(get_node_property "$cluster_cfg" "$coordinator" "username")
coordinator_port=$(get_node_property "$cluster_cfg" "$coordinator" "port")
coordinator_dbname=$(get_node_property "$cluster_cfg" "$coordinator" "dbname")
coordinator_hostname=$(get_node_property "$cluster_cfg" "$coordinator" "hostname")


# create restore point and save its name into file
psql -h ${coordinator_hostname} -p ${coordinator_port} -U ${coordinator_username} -d ${coordinator_dbname} -c "select citus_create_restore_point('${restorePointName}')" && \
echo ${restorePointName} >> ${backupBaseDir}/restorePoints.txt
