# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: start preference of tracker
# Maintainer: nick wang <nwang@suse.com>
# Tags: tc#1436344

use base "x11regressiontest";
use strict;
use testapi;


sub run {
    x11_start_program("tracker-preferences", target_match => 'tracker_pref_launched');
    send_key "alt-f4";
}

1;
# vim: set sw=4 et:
