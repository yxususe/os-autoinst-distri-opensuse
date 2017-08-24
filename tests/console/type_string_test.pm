use base "consoletest";
use strict;
use testapi;
 
sub run {
    select_console 'root-console';
    type_string ("Do not wait_still_screen", 25, 0, 0);
    type_string ("wait_still_screen for 5 seconds", 25, 0, 5);
    type_string ("wait_still_screen for 10 seconds", 25, 0, 10);
    type_string ("wait_still_screen for 20 seconds", 25, 0, 20);
}

1;
# vim: set sw=4 et:

