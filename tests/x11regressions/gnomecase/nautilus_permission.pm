# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: case 1436125-use nautilus to change file permissions
# Maintainer: Xudong Zhang <xdzhang@suse.com>

use base "x11regressiontest";
use strict;
use testapi;


sub run {
    x11_start_program('touch newfile', valid => 0);
    x11_start_program('nautilus');
    send_key_until_needlematch 'nautilus-newfile-matched', 'right', 15;
    send_key "shift-f10";
    assert_screen 'nautilus-rightkey-menu';
    send_key "r";    #choose properties
    assert_screen 'nautilus-properties';
    send_key "up";       #move focus onto tab
    send_key "right";    #move to tab Permissions
    for (1 .. 4) { send_key "tab" }
    send_key "ret";
    assert_screen 'nautilus-access-permission';
    send_key "down";
    send_key "ret";
    send_key "tab";
    send_key "ret";
    assert_screen 'nautilus-access-permission';
    send_key "down";
    send_key "ret";
    send_key "esc";      #close the dialog
                         #reopen the properties menu to check if the changes kept
    send_key "shift-f10";
    assert_screen 'nautilus-rightkey-menu';
    send_key "r";        #choose properties
    assert_screen 'nautilus-properties';
    send_key "up";       #move focus onto tab
    send_key "right";    #move to tab Permissions
    assert_screen 'nautilus-permissions-changed';
    send_key "esc";      #close the dialog


    #clean: remove the created new note
    x11_start_program('rm newfile', valid => 0);
    send_key "ctrl-w";
}

1;
# vim: set sw=4 et:
