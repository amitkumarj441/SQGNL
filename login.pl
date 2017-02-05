use strict;

use Tk;
use Tk::Balloon;

############################################################################
### Create the login window ###
my $win_login = MainWindow->new;

### Set the window title ###
$win_login->title("Login to database - SQGNL");

### Center this winodw in the screen ###
my $h = 125;    ### Window height ###
my $w = 200;    ### Window width  ###
my $x =  int(($win_login->screenwidth()-$w)/2);       ### x position ###
my $y =  int(($win_login->screenheight()-100-$h)/2);  ### y position ###
$win_login->geometry("${w}x${h}+${x}+${y}");

### Set the minimu and maximum sizes to be the same ###
### so that the user can not resize the window      ###
$win_login->maxsize( $w, $h );
$win_login->minsize( $w, $h );

############################################################################
### Create window controls ###

### create the balloon widget to display tooltips ###
my $tooltip = $win_login->Balloon;

### label displaying the selected datasource -------------------------------
my $lbl_dat_src = $win_login->Label( -text => "Data source: ${db_type}::${db_source}")
                             ->pack( -fill => "x");

$tooltip->attach($lbl_dat_src,
                 -msg => "Data source used in SQGNL.\nThis can be changed in the configuration widnow");

my $frame1 = $win_login->Frame->pack( -side => "top",
                                      -fill => "x",
                                      -expand => 1);

my $frame1_1 = $frame1->Frame->pack( -side => "left",
                                     -fill => "x",
                                     -expand => 1);

my $frame1_2 = $frame1->Frame->pack( -side => "right",
                                     -fill => "x",
                                     -expand => 1);

$frame1_1->Label( -text => "user",
                  -anchor => "e")
          ->pack( -side => "top",
                  -fill => "x",
                  -expand => 1);

### user name entry area ---------------------------------------------------
my $txt_user = $frame1_2->Entry( -textvariable => \$user, -width =>15 )
                         ->pack( -side => "top",
                                 -fill => "x",
                                 -expand => 1);

$tooltip->attach($txt_user,
                 -msg => "Enter the user name for the database login.");

$frame1_1->Label( -text => "password",
                  -anchor => "e")
          ->pack( -side => "top",
                  -fill => "x",
                  -expand => 1);

### password entry area ----------------------------------------------------
my $txt_pwd = $frame1_2->Entry( -textvariable => \$passwd,
                                -width => 10,
                                -show => "*")
                        ->pack( -side => "left",
                                -fill => "x",
                                -expand => 1);

$tooltip->attach($txt_pwd,
                 -msg => "Enter the password for the database login.");

my $fra_buttons = $win_login->Frame->pack( -side => "top",
                                      -pady => 5);

### OK button to accept values ---------------------------------------------
my $cmd_ok = $fra_buttons->Button( -text => "OK",
                                   -default => "active",
                                   -command =>
                                   sub
                                   {
                                       ### close this window                ###
                                       ### user name and passwords will be  ###
                                       ### automatically saved in variables ###
                                       $win_login->destroy();
                                   }
                                 )
                           ->pack( -side  => "left",
                                   -ipadx => 15,
                                   -padx  => 5);

$tooltip->attach($cmd_ok,
                 -msg => "Accept user name and password and Run SQGNL.");

### Cancel button to discard values ----------------------------------------
my $cmd_cancel = $fra_buttons->Button( -text => "Cancel",
                                       -command =>
                                       sub
                                       {
                                           ### end the program ###
                                           exit;
                                       }
                                     )
                               ->pack( -side => "right",
                                       -ipadx => 5,
                                       -padx  => 5);

$tooltip->attach($cmd_cancel,
                 -msg => "Exit to the system.");

### set the initial focus to the password field ----------------------------
#$txt_pwd->focus;
$cmd_ok->focus;

### Update winodw controls before displaying the window ###
$win_login->update();

### Show this window and process messages ###
MainLoop;
