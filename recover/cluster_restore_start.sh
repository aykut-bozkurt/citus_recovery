#!/bin/bash

set -eu

source $(dirname "$0")/../util/config_parser.sh

cluster_cfg=$1

clusterBaseDir=$(get_cluster_base_dir "$cluster_cfg")
archiveBaseDir=$(get_archive_base_dir "$cluster_cfg")
backupBaseDir=$(get_backup_base_dir "$cluster_cfg")
backupName=$(get_backup_to_restore "$cluster_cfg")
restorePointName=$(get_restore_point "$cluster_cfg")
nodes=$(get_all_nodes "$cluster_cfg")

# stop cluster if it is running
citus_dev stop "${clusterBaseDir}" || true

# rename old data directory
mv ${clusterBaseDir} "${clusterBaseDir}"Old

for node in $nodes ; do
	echo $node
	nodeName=$(get_node_property "$cluster_cfg" "$node" "name")

	# create empty data directory
	mkdir -p ${clusterBaseDir}/${nodeName}

	# fill data directory with basebackup that we want to recover from
	cd ${clusterBaseDir}/${nodeName} && tar -xvf ${backupBaseDir}/${nodeName}/${backupName}/base.tar
	cd -

	# configure restore command
	echo "restore_command = 'cp ${archiveBaseDir}/${nodeName}/%f %p'" >> ${clusterBaseDir}/${nodeName}/postgresql.conf

	# configure recovery target name
	echo "recovery_target_name = '${restorePointName}'" >> ${clusterBaseDir}/${nodeName}/postgresql.conf

	# create recovery signal file
	touch ${clusterBaseDir}/${nodeName}/recovery.signal
done

# update directory permissions
chmod -R 700 ${clusterBaseDir}

# start Postgres, it will go into recovery mode and apply wals from basebackup's starting wal until the restore point wal record is reached.
citus_dev start ${clusterBaseDir}

# wait until recovery pause state is reached
pause_reached='f'
while [ ${pause_reached} = 'f' ]
do
        pause_reached='t'

        for node in $nodes ; do
		nodePort=$(get_node_property "$cluster_cfg" "$node" "port")
		nodeHostname=$(get_node_property "$cluster_cfg" "$node" "hostname")
		nodeUsername=$(get_node_property "$cluster_cfg" "$node" "username")
		nodeDbname=$(get_node_property "$cluster_cfg" "$node" "dbname")

                recovery_pause_state=$(psql -h ${nodeHostname} -p ${nodePort} -U ${nodeUsername} -d ${nodeDbname} \
                                            -c "select pg_is_wal_replay_paused()" | tail -3 | head -1)
                echo ${recovery_pause_state}
                if [ ${recovery_pause_state} = 'f' ]; then
                        pause_reached='f'
                        break;
                fi
        done

        sleep 1
done

# After finishing wal appply, Postgres will be in pause mode by default(Ensure recovery_target_action = 'pause'). At that point, no writes are allowed to the node.
# Only select queries are allowed. You can connect to the node and make sanity checks via read only queries.
