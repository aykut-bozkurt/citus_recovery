#!/bin/bash

set -euo pipefail

source $(dirname "$0")/util/config_parser.sh

cluster_cfg=$1

clusterBaseDir=$(get_cluster_base_dir "$cluster_cfg")
archiveBaseDir=$(get_archive_base_dir "$cluster_cfg")
backupBaseDir=$(get_backup_base_dir "$cluster_cfg")

# remove old backup and archive folder
rm -rf ${clusterBaseDir}
rm -rf "${clusterBaseDir}"Old
rm -rf ${archiveBaseDir}
rm -rf ${backupBaseDir}

nodes=$(get_all_nodes "$cluster_cfg")
for node in $nodes ; do
        echo $node | base64 --decode
	nodeName=$(get_node_property "$cluster_cfg" "$node" "name")
	mkdir -p ${archiveBaseDir}/${nodeName}
	mkdir -p ${backupBaseDir}/${nodeName}
done

coordinator=$(get_coordinator "$cluster_cfg")
coordinator_name=$(get_node_property "$cluster_cfg" "$coordinator" "name")
coordinator_username=$(get_node_property "$cluster_cfg" "$coordinator" "username")
coordinator_port=$(get_node_property "$cluster_cfg" "$coordinator" "port")
coordinator_dbname=$(get_node_property "$cluster_cfg" "$coordinator" "dbname")
coordinator_hostname=$(get_node_property "$cluster_cfg" "$coordinator" "hostname")

# create cluster
citus_dev make ${clusterBaseDir} --destroy
# stop cluster
citus_dev stop ${clusterBaseDir}
# prepare archiving
bash $(dirname "$0")/backup/cluster_prepare_archiving.sh "${cluster_cfg}"
# start cluster
citus_dev start ${clusterBaseDir}
# take base backups
bash $(dirname "$0")/backup/cluster_take_basebackup.sh "${cluster_cfg}"
# create table xx and insert 15m records
psql -h ${coordinator_hostname} -p ${coordinator_port} -U ${coordinator_username} -d ${coordinator_dbname} \
     -c "create table xx(id int); select create_distributed_table('xx','id'); insert into xx select i from generate_series(1,15000000) i;"
# create restore point
bash $(dirname "$0")/backup/cluster_create_restore_points.sh "${cluster_cfg}"
# insert into xx 15m records again
psql -h ${coordinator_hostname} -p ${coordinator_port} -U ${coordinator_username} -d ${coordinator_dbname} \
     -c "insert into xx select i from generate_series(1,15000000) i;"
# stop cluster
citus_dev stop ${clusterBaseDir}
# restore cluster into recent basebackup and restore point
bash $(dirname "$0")/recover/cluster_restore_start.sh "${cluster_cfg}"
# sanity check should return 15m rows
psql -h ${coordinator_hostname} -p ${coordinator_port} -U ${coordinator_username} -d ${coordinator_dbname} \
     -c "select count(*) from xx;"
# put cluster into production mode to allow writes
bash $(dirname "$0")/recover/cluster_restore_finish.sh "${cluster_cfg}"

