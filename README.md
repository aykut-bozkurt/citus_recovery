# Citus Recovery
Project includes scripts to backup and recover a local Citus cluster which is created by citus_dev tool. It also includes an example scenario.

## Example Scenario
* We will create a citus cluster with 2 workers.
* We will create a basebackup at that point.
* We will create and distribute a table named xx. Then we will insert 15m rows into it. 
* We will take restore point so that we will get back to that point. 
* We will insert 15m rows again. Currently we have 30m rows in xx.
* After that, we will restore to old state. 
* We will verify we have 15m rows after restore.

You can execute example scenario:
```bash
bash example_recovery.sh cluster-config.json
```

## Configuration
Do not forget changing `backupToRestore` and `restorePoint` while taking basebackups and creating restore points.
```
{
        "clusterName": <name of the cluster citus_dev will create>,
        "workerCount": <number of workers in the cluster>,
        "coordinatorNode": {
                                "name": <name of the node>,
                                "hostname": <coordinator host name>,
                                "port": <coordinator port>,
                                "username": <coordinator username>,
                                "dbname": <coordinator dbname>
                        },
        "workerNodes": [
                <array of worker nodes that are defined similar to coordinator node>
        ],
        "clusterBaseFolder": <full base folder path for the cluster>,
        "archiveBaseFolder": <full base folder path for the archiving>,
        "backupBaseFolder": <full base folder path for the backups>,
        "backupToRestore": <name of the backup that will be restored from>,
        "restorePoint": <name of Citus restore point>
}
```

## Preparing Backups
You should prepare all nodes in the cluster for a disaster by executing following commands:

```bash
# you should apply that step just before starting the node
bash backup/cluster_prepare_archiving.sh cluster-config.json
# you should apply that step via a cron job at specified intervals by your business requirements
bash backup/cluster_take_basebackup.sh cluster-config.json
# you should apply that step via a cron job at specified intervals by your business requirements
bash backup/cluster_create_restore_points.sh cluster-config.json
```

We can summarize the steps taken here:

1. Configure archive_command inside postgresql.conf.

2. Create base backups at specific intervals. (name backupToRestore as datetime) 

3. Create restore points at specific intervals. (name restorePoint name as datetime):

Note: Archive and backup directories should be outside of Postgres data directory.

## Recovering from Backup

You should restore all nodes in the cluster to a consistent cluster state by executing following commands:

```bash
bash backup/cluster_restore_start.sh cluster-config.json
#### before taking the last step, you can connect to coordinator and run readonly queries for sanity purpose ###
#### when you take the last step, cluster will be in production mode ####
bash backup/cluster_restore_finish.sh cluster-config.json
```

We can summarize the steps taken here:

1. Stop Postgres if it is running.

2. Rename current node's Postgres data directory in case something goes wrong with restoration.

3. Create an empty Postgres data directory.

4. Fill empty directory with extracted basebackup that you want to recover from.

5. Update directory permissions.

6. Configure restore_command inside postgresql.conf.

7. Configure recovery_target_name inside postgresql.conf. (Restore point should have been taken after the current basebackup was taken.)

8. Create recovery signal file.

9. Start Postgres, it will go into recovery mode. Then, it should apply wals from basebackup's starting wal until the restore point wal record is reached.

10. After finishing wal appply, Postgres will be in pause mode by default(Ensure recovery_target_action = 'pause'). At that point, no writes are allowed to the node. 
    Only select queries are allowed. You can connect to the node and make sanity checks via read only queries.

11. If everything looks fine, you should resume recovery pause to go into production mode.

12. Delete recovery.signal file and you can also clear recovery_target_name.


Note: If you use HA tools, you need to apply those steps for each primary node in the cluster to restore to a consistent cluster state.

## Dependencies
* `citus_dev` for creating Citus cluster
* `jq` for json parsing

## Disclaimer
Scripts are never tested in production environment. I use those for testing purposes. Use it at your own risk!
