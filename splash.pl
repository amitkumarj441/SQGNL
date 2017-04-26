use strict;

# Modular level variables
use vars qw( $win_splash );      # window handle for this splash screen
my $PARSER_FILE  = "parser.pl";  # name of the parser file
my $splash_shown = 0;            # splash screen is already shown or not
my $splash_info;                 # message to be displayed on the splash screen

# Display the spalsh screen and load parser grammar in the background
sub show_splash
{
    ### do not show the splash screen if already shown ###
    ### we do not want to load the grammar twice       ###
    if ($splash_shown == 1)    {  return 0; }

    $splash_shown = 1;    ### splash screen has been shown ###

    ### create splash screen  ###
    $win_splash = MainWindow->new();

    ### do no show the title bar for the splash screen ###
    $win_splash->overrideredirect(1);

    $win_splash->configure( -background => "white");
    $win_splash->configure( -borderwidth => 1);

    ### center this window ###
    my $h = 270;    ### window height ###
    my $w = 360;    ### window width  ###
    my $x =  int(($win_splash->screenwidth()-$w)/2);      ### x position ###
    my $y =  int(($win_splash->screenheight()-100-$h)/2); ### y position ###
    $win_splash->geometry("${w}x${h}+${x}+${y}");

    ########################################################################
    ### create window controls ###
    my $img_sq_hal = $win_splash->Photo( -file => 'splash.png');

    
    $win_splash->Label( -borderwidth => 0,
                        -image => $img_sq_hal )->pack;

    ### display area for splash screen messages ###
    $win_splash->Label( -textvariable => \$splash_info,
                        -background => "white")
                ->pack( -fill => "x",
                        -side => "top");

    ### Exit button - to exit to the system ###
    $win_splash->Button( -text => "  Exit  ",
                         -background => "white",
                         -borderwidth => 0,
                         -command => sub { exit })
                 ->pack( -fill => "x",
                         -side => "top");

    ### show spalsh screen ###
    $win_splash->update();
    $win_splash->raise();

    # start loading the parser immediately after displaying the splash screen ###
    $win_splash->after(10, \&load_data);

    MainLoop;
}

# Load initial data and the parser at startup
sub load_data
{
    ### connect to the database ###
    $splash_info = 'Connecting to the database...';
    $win_splash->update();

    ### if unsuccessful database connection, then exit the program ###
    if (! connect_to_db($db_type, $db_source, $user, $passwd ))
    {
        exit;
    }

    ### load SQ-HAL parser ###
    $splash_info = 'Loading SQ-HAL parser...';
    $win_splash->update();
    load_parser();

    ### Destroy the splash screen ###
    $win_splash->destroy();
}

1;  # so the 'do' command succeeds
