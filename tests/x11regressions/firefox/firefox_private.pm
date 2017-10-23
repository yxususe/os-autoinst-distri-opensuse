# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Case#1479412: Firefox: Private Browsing
# Maintainer: wnereiz <wnereiz@gmail.com>

use strict;
use base "x11regressiontest";
use testapi;

sub run {
    my ($self) = @_;
    $self->start_firefox;

    send_key "ctrl-shift-p";
    send_key "alt-d";
    type_string "gnu.org\n";
    $self->firefox_check_popups;
    assert_screen('firefox-private-gnu', 90);
    send_key "alt-d";
    type_string "facebook.com\n";
    $self->firefox_check_popups;
    assert_screen('firefox-private-facebook', 90);

    send_key "alt-f4";
    wait_still_screen 3;
    $self->exit_firefox;

    x11_start_program('firefox');
    $self->firefox_check_default;
    $self->firefox_check_popups;
    assert_screen('firefox-launch', 90);

    send_key "ctrl-h";
    assert_and_click('firefox-private-checktoday');
    assert_screen('firefox-private-checkhistory', 60);
    send_key "alt-f4";

    # Exit
    send_key "alt-f4";
    if (check_screen('firefox-save-and-quit', 30)) {
        # confirm "save&quit"
        send_key "ret";
    }
}
1;
# vim: set sw=4 et:
