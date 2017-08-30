use base "consoletest";
use strict;
use testapi;
 
sub run {
    select_console 'root-console';
    type_string ("date\n");
    wait_still_screen 1;
    save_screenshot;
    type_string ("Do not wait_still_screen\n", max_interval => 100, wait_screen_changes => 10, wait_still_screen => 0);
    type_string ("date\n");
    wait_still_screen 1;
    save_screenshot;
    type_string ("wait_still_screen for 5 seconds\n",max_interval =>  100, wait_screen_changes => 10, wait_still_screen => 5);
    type_string ("date\n");
    wait_still_screen 1;
    save_screenshot;
    type_string ("wait_still_screen for 10 seconds\n", max_interval => 50, wait_screen_changes => 20, wait_still_screen => 10);
    type_string ("date\n");
    wait_still_screen 1;
    save_screenshot;
    type_string ("wait_still_screen for 20 seconds\n", max_interval => 125, wait_screen_changes => 10, wait_still_screen => 20);
    type_string ("date\n");
    wait_still_screen 1;
    save_screenshot;
    type_string ("wait_still_screen for 30 seconds\n", max_interval => 250, wait_screen_changes => 0, wait_still_screen => 30);
    type_string ("date\n");
    wait_still_screen 1;
    save_screenshot;
}

1;
# vim: set sw=4 et:

