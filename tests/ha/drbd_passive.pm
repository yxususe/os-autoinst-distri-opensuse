# SUSE's openQA tests
#
# Copyright (c) 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: DRBD active/passive OpenQA test
# Create DRBD device
# Create crm ressource
# Check resource migration
# Check multistate status
# Maintainer: Loic Devulder <ldevulder@suse.com>

use base 'opensusebasetest';
use strict;
use version_utils 'sle_version_at_least';
use testapi;
use lockapi;
use hacluster;

sub run {
    my $csync_conf    = '/etc/csync2/csync2.cfg';
    my $drbd_res      = 'drbd_passive';
    my $drbd_res_file = "/etc/drbd.d/$drbd_res.res";

    # 2 LUN are needed for DRBD
    my $drbd_lun_01 = block_device_real_path '/dev/disk/by-path/ip-*-lun-3';
    my $drbd_lun_02 = block_device_real_path '/dev/disk/by-path/ip-*-lun-4';

    # DRBD needs 2 nodes for the test, so we can easily
    # arbitrary choose the first two
    my $node_01    = choose_node(1);
    my $node_02    = choose_node(2);
    my $node_01_ip = script_output "host -t A $node_01 | awk '{ print \$NF }'";
    my $node_02_ip = script_output "host -t A $node_02 | awk '{ print \$NF }'";

    # At this time, we only test DRBD on a 2 nodes cluster
    # And if the cluster has more than 2 nodes, we only use the first 2 nodes
    return if (!is_node(1) && !is_node(2));

    # Wait until DRBD test is initialized
    barrier_wait("DRBD_INIT_$cluster_name");

    # DRBD LUNs need to be filter in LVM to avoid duplicate PVs
    lvm_add_filter('r', $drbd_lun_01);
    lvm_add_filter('r', $drbd_lun_02);

    # Do the DRBD configuration only on the first node
    if (is_node(1)) {
        # Modify DRBD global configuration file
        assert_script_run 'sed -i \'/^[[:blank:]]*startup[[:blank:]]*{/a \\\t\twfc-timeout 100;\n\t\tdegr-wfc-timeout 120;\' /etc/drbd.d/global_common.conf';

        # Get resource configuration template from the openQA server
        assert_script_run "curl -f -v " . autoinst_url . "/data/ha/$drbd_res.res.template -o $drbd_res_file";

        # And modify the template according to our needs
        assert_script_run "sed -i 's/%NODE_01%/$node_01/g' $drbd_res_file";
        assert_script_run "sed -i 's/%NODE_02%/$node_02/g' $drbd_res_file";
        assert_script_run "sed -i 's/%ADDR_NODE_01%/$node_01_ip/g' $drbd_res_file";
        assert_script_run "sed -i 's/%ADDR_NODE_02%/$node_02_ip/g' $drbd_res_file";

        # Note: we use ';' instead of '/' as the sed separator because of UNIX file names
        assert_script_run "sed -i 's;%DRBD_LUN_01%;$drbd_lun_01;g' $drbd_res_file";
        assert_script_run "sed -i 's;%DRBD_LUN_02%;$drbd_lun_02;g' $drbd_res_file";

        # Show the result
        type_string "cat $drbd_res_file\n";

        # We need to add the configuration in csync2.conf
        assert_script_run "grep -q drbd $csync_conf || sed -i 's|^}\$|include /etc/drbd*;\\n}|' $csync_conf";

        # Execute csync2 to synchronise the configuration files
        # Sometimes we need to run csync2 twice to have all the files updated!
        assert_script_run 'csync2 -v -x -F ; sleep 2 ; csync2 -v -x -F';
    }
    else {
        diag 'Wait until DRBD configuration is created...';
    }

    # Wait until DRBD configuration is created
    barrier_wait("DRBD_CREATE_CONF_$cluster_name");

    # Create the DRBD device
    assert_script_run "drbdadm create-md $drbd_res";
    assert_script_run "drbdadm up $drbd_res";

    # Wait for first node to complete its configuration
    barrier_wait("DRBD_CREATE_DEVICE_$cluster_name");

    # Configure primary node
    if (is_node(1)) {
        assert_script_run "drbdadm -- --overwrite-data-of-peer --force primary $drbd_res";
        assert_script_run "drbdadm status $drbd_res";

        # Run assert_script_run timeout 240 during the long assert_script_run drbd sync
        assert_script_run "while ! \$(drbdadm status $drbd_res | grep -q \"peer-disk:UpToDate\"); do sleep 10; drbdadm status $drbd_res; done", 240;
    }
    else {
        diag 'Wait until drbd device is activated on primary node...';
    }

    # Wait for DRBD to complete its activation
    barrier_wait("DRBD_ACTIVATE_DEVICE_$cluster_name");

    # Configure slave node
    if (is_node(2)) {
        assert_script_run "drbdadm status $drbd_res";

        # Run assert_script_run timeout 240 during the long assert_script_run drbd sync
        assert_script_run "while ! \$(drbdadm status $drbd_res | grep -q \"peer-disk:UpToDate\"); do sleep 10; drbdadm status $drbd_res; done", 240;
    }
    else {
        diag 'Wait until drbd device is activated on slave node...';
    }

    # Wait for DRBD HA setup to complete
    barrier_wait("DRBD_SETUP_DONE_$cluster_name");

    # Stop DRBD device before configuring Pacemaker
    if (is_node(1)) {
        # Force node to wait a little before stopping DRBD device
        # Because if we try to stop on both node at the same time it can fail!
        sleep 5;

        # Sometimes down failed on primary node
        # So set secondary mode to avoid this issue
        assert_script_run "drbdadm secondary $drbd_res";
    }
    assert_script_run "drbdadm down $drbd_res";

    # Wait for DRBD device to stop
    barrier_wait("DRBD_DOWN_DONE_$cluster_name");

    # Create the HA resource
    if (is_node(1)) {
        assert_script_run "EDITOR=\"sed -ie '\$ a primitive $drbd_res ocf:linbit:drbd params drbd_resource=$drbd_res'\" crm configure edit";
        assert_script_run
          "EDITOR=\"sed -ie '\$ a ms ms_$drbd_res $drbd_res meta master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true'\" crm configure edit";
        assert_script_run "EDITOR=\"sed -ie '\$ a order order_ms_$drbd_res inf: base-clone ms_$drbd_res'\" crm configure edit";

        # Just to be sure that Pacemaker has done its job!
        sleep 5;

        # Sometimes we need to cleanup the resource
        assert_script_run "crm resource cleanup $drbd_res";

        # Just to be sure that Pacemaker has done its job!
        sleep 5;

        # Do a check of the cluster with a screenshot
        save_state;

        # Check for result
        ensure_resource_running("ms_$drbd_res", ":[[:blank:]]*$node_01\[[:blank:]]*[Mm]aster\$");
    }
    else {
        diag 'Wait until drbd resource is created/activated...';
    }

    # Wait for DRBD to be checked
    barrier_wait("DRBD_RESOURCE_CREATED_$cluster_name");

    if (sle_version_at_least('12-SP3')) {
        # Need to stop/start the DRBD resource to be able to migrate it after
        # Is it the wanted behavior? Was not in SLE12-SP2, need to check with
        # developers for the new versions
        if (is_node(1)) {
            # Force node to wait a little before stopping DRBD device
            # Because if we try to stop on both node at the same time it can fail!
            sleep 5;
        }
        assert_script_run "crm resource stop $drbd_res";

        # Wait for DRBD to be stopped
        barrier_wait("DRBD_RESOURCE_STOPPED_$cluster_name");

        if (is_node(2)) {
            # Force node to wait a little before stopping DRBD device
            # Because if we try to stop on both node at the same time it can fail!
            sleep 5;
        }
        assert_script_run "crm resource start $drbd_res";

        # Wait for DRBD to be started
        barrier_wait("DRBD_RESOURCE_STARTED_$cluster_name");
    }

    # Migrate DRBD resource on the other node
    if (is_node(2)) {
        assert_script_run "crm resource migrate ms_$drbd_res $node_02";

        # Just to be sure that Pacemaker has done its job!
        sleep 5;

        # Check the migration / timeout 240 sec it takes some time to update
        assert_script_run "while ! \$(drbdadm status $drbd_res | grep -q \"$drbd_res role:Primary\"); do sleep 10; drbdadm status $drbd_res; done", 240;

        # Check for result
        ensure_resource_running("ms_$drbd_res", ":[[:blank:]]*$node_02\[[:blank:]]*[Mm]aster\$");
    }

    # Wait for DRBD resrouce migration to be done
    barrier_wait("DRBD_MIGRATION_DONE_$cluster_name");

    # Do a check of the cluster with a screenshot
    save_state;

    # Revert the migration - we need to have the Master on first node for the next test
    if (is_node(1)) {
        assert_script_run "crm resource migrate ms_$drbd_res $node_01";

        # Just to be sure that Pacemaker has done its job!
        sleep 5;

        # Check the migration / timeout 240 sec it takes some time to update
        assert_script_run "while ! \$(drbdadm status $drbd_res | grep -q \"$drbd_res role:Primary\"); do sleep 10; drbdadm status $drbd_res; done", 240;

        # Check for result
        ensure_resource_running("ms_$drbd_res", ":[[:blank:]]*$node_01\[[:blank:]]*[Mm]aster\$");
    }

    # Wait for DRBD resrouce migration to be done
    barrier_wait("DRBD_REVERT_DONE_$cluster_name");

    # Do a check of the cluster with a screenshot
    save_state;

    # Add the tag for resource configuration
    write_tag("$drbd_res");
}

1;
# vim: set sw=4 et:
