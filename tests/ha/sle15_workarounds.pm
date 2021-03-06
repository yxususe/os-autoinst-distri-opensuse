# SUSE's openQA tests
#
# Copyright (c) 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Add some SLE15 workarounds
#          Should be removed after SLE15 will be released!
# Maintainer: Loic Devulder <ldevulder@suse.com>

use base 'opensusebasetest';
use strict;
use version_utils 'sle_version_at_least';
use testapi;
use hacluster;

# Do some stuff that need to be workaround in SLE15
sub run {
    return unless sle_version_at_least('15');

    # Modify the device number if needed
    if ((get_var('ISO', '') eq '') && (get_var('ISO_1', '') ne '')) {
        assert_script_run "sed -i 's;sr1;sr0;g' /etc/zypp/repos.d/*";
    }
}

1;
# vim: set sw=4 et:
