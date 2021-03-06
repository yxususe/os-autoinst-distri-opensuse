# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Test custom partitioning selection: Split off '/usr' partition
# Maintainer: Oliver Kurz <okurz@suse.de>

use base "y2logsstep";
use strict;
use testapi;

sub run {
    send_key "alt-e";    # Edit
                         # select vda2
    send_key "right";
    send_key "down";     # only works with multiple HDDs
    send_key "right";
    send_key "down";
    send_key "tab";
    send_key "tab";
    send_key "down";

    #send_key "right"; send_key "down"; send_key "down";
    wait_screen_change { send_key 'alt-i' };    # Resize
    send_key "alt-u";                           # Custom
    type_string "1.5G";
    send_key "ret";

    # add /usr
    wait_screen_change { send_key $cmd{addpart} };
    wait_screen_change { send_key $cmd{next} };
    for (1 .. 10) {
        send_key "backspace";
    }
    type_string "5.0G";
    send_key $cmd{next};
    assert_screen 'partition-role';
    send_key "alt-o";    # Operating System
    wait_screen_change { send_key $cmd{next} };
    send_key "alt-m";        # Mount Point
    type_string "/usr\b";    # Backspace to break bad completion to /usr/local
    assert_screen "partition-splitusr-submitted-usr";
    send_key $cmd{finish};
    assert_screen "partition-splitusr-finished";
    wait_screen_change { send_key $cmd{accept} };
    send_key "alt-y";        # Quit the warning window
}

1;
# vim: set sw=4 et:
