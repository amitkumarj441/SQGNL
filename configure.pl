use strict;

use Tk;
use Tk::Balloon;

# Modular level varialbes
use vars qw ( $win_config );     # configuration window
my $CONFIG_FILE = "sq-hal.ini";  # name of the configuration file
my $lst_type;                    # list of all the database types
my $lst_sources;                 # list of available data source for a particular database type
my $txt_source;                  # selected data source
my $tmp_type;                    # temporary hold the database type
my $db_status;                   # status bar for the configuration window

### temporary save the previous database type, datasource ###
### user_name and password so that any changes can be     ###
### detected and load the parser accordingly              ###
my $prev_db_type;                 # previous database type
my $prev_db_source;               # previous data source
my $prev_user;                    # previous user name
my $prev_pwd;                     # previous password

use strict;

# Load configuration info from a file
sub load_config
{
    $config_file_found = 1;

    ### check if the configuration file exists ###
    unless(open(CONFIG, "< $CONFIG_FILE"))
    {
        print "Configuration file not found\n";
        $config_file_found = 0;

        ### define default values ###
        $learn_enabled = 0;
        $rows_displayed = 20;

        return 0;   ### exit this subroutine ###
    };

    ### load configuration data from the file ###
    chomp($db_source = <CONFIG>);
    chomp($user = <CONFIG>);
    chomp($db_type = <CONFIG>);
    chomp($learn_enabled = <CONFIG>);
    chomp($rows_displayed = <CONFIG>);

    ### close the configuration file ###
    close( CONFIG );
}

# Save configuration info to a file
sub save_config
{
    ### always create a new file and overwrite existing data ###
    open( CONFIG, "> $CONFIG_FILE") or die "Can\'t create the config file!";

    ### write configuration data to the file ###
    print CONFIG $db_source,"\n";
    print CONFIG $user,"\n";
    print CONFIG $db_type,"\n";
    print CONFIG $learn_enabled,"\n";
    print CONFIG $rows_displayed,"\n";

    ### close the configuration file ###
    close( CONFIG );
}


# Create and show the configure window
sub show_config
{
    ### Creae the configuration window ###
    $win_config = MainWindow->new;

    $win_config->title("Configure SQ-HAL");

    ### center the window in the screen ###
    my $h = 250;      ### window height ###
    my $w = 600;      ### window width  ###
    my $x =  int(($win_config->screenwidth()-$w)/2);       ### x position ###
    my $y =  int(($win_config->screenheight()-100-$h)/2);  ### y position ###
    $win_config->geometry("${w}x${h}+${x}+${y}");

    ### Set the minimu and maximum sizes to be the same ###
    ### so that the user can not resize the window      ###
    $win_config->minsize( $w, $h );
    $win_config->maxsize( $w, $h );

    ### define and place window controls ###

    my $tooltip = $win_config->Balloon;

    my $fra_database = $win_config->Frame( -borderwidth => 1,
                                           -relief => "groove" )
                                   ->pack( -side => "top",
                                           -padx => 10,
                                           -pady => 10);

    $fra_database->Label( -text => "Database Properties")
                  ->pack( -side => "top",
                          -fill => 'x',
                          -expand => 1);

    my $fra_database2 = $fra_database->Frame()->pack( -side => "left",
                                                      -fill => 'x',
                                                      -expand => 1);

    my $fra_database3 = $fra_database2->Frame()->pack( -side => "left",
                                                       -fill => 'x',
                                                       -expand => 1);

    my $fra_database4 = $fra_database2->Frame()->pack( -side => "right",
                                                       -fill => 'x',
                                                       -expand => 1);

    my $fra_database6 = $fra_database->Frame()->pack( -side => "right",
                                                      -fill => 'x',
                                                      -expand => 1,
                                                      -padx => 10);


    ### data source --------------------------------------------------------
    $fra_database3->Label( -text => "Source : ",
                           -anchor => "ne")
                   ->pack( -side => "top",
                           -fill => "x",
                           -expand => 1);

    $txt_source = $fra_database4->Entry( -textvariable => \$db_source,
                                          -width => 50 )
                                  ->pack( -fill => "x",
                                          -expand => 1,
                                          -side => "top");

    $tooltip->attach($txt_source,
                     -msg => "Select the data source (database) from the available datasource
or type the path/location/name of the data source.");

    ### available data sources ---------------------------------------------
    $fra_database3->Label( -text => "Avaliable\nSources : \n",
                            -anchor => "ne")
                    ->pack( -side => "top",
                            -fill => "x",
                            -expand => 1);

    $lst_sources = $fra_database4->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "single",
                                              -height => 3)
                                      ->pack( -side => "top",
                                              -fill => "x",
                                              -expand => 1);
    $lst_sources->insert("end", &get_db_sources($db_type));

    $lst_sources->bind("<ButtonPress>", \&select_datasource );

    $tooltip->attach($lst_sources,
                    -msg => "List of all the available data sources for the selected database type.");

    ### database user name -------------------------------------------------
    $fra_database3->Label( -text => "User : ",
                           -anchor => "ne")
                   ->pack( -side => "top",
                           -fill => "x",
                           -expand => 1);

    my $txt_user = $fra_database4->Entry( -textvariable => \$user,
                                          -width => 10 )
                                  ->pack( -expand => 1,
                                          -fill => "x",
                                          -side => "top");

    $tooltip->attach($txt_user,
                     -msg => "User name for the database login.");

    ### database password --------------------------------------------------
    $fra_database3->Label( -text => "Password : ",
                           -anchor => "ne")
                   ->pack( -side => "top",
                           -fill => "x",
                           -expand => 1);

    my $txt_password = $fra_database4->Entry( -textvariable => \$passwd,
                                              -show => "*",
                                              -width => 10 )
                                      ->pack( -expand => 1,
                                              -fill => "x",
                                              -side => "top");

    $tooltip->attach($txt_password,
                     -msg => "Password for the database login.");

    ### total number of rows to dispay -------------------------------------
    $fra_database3->Label( -text => "No of rows : ",
                           -anchor => "ne")
                   ->pack( -side => "top",
                           -fill => "x",
                           -expand => 1);

    my $txt_rows = $fra_database4->Entry( -textvariable => \$rows_displayed,
                                          -width => 3 )
                                      ->pack( -expand => 1,
                                              -fill => "x",
                                              -side => "top");

    $tooltip->attach($txt_rows,
                     -msg => "Maximum number of rows to be displayed in the database records table.");

    ### database type  -----------------------------------------------------
    $fra_database6->Label( -text => "Type :", -anchor => "nw")
                   ->pack( -side => "top",
                           -fill => "x",
                           -expand => 0 );

    $lst_type = $fra_database6->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "single",
                                              -height => 5)
                                      ->pack( -side => "left");

    $lst_type->insert("end", &get_db_drivers());
    $lst_type->insert("end", "Other");
    $lst_type->insert("end", "Don't know");

    $lst_type->bind("<ButtonPress>", \&update_datasources );

    # hilight already selected database type
    if ( $db_type )
    {
        my $tmp_db_type = $db_type;
        $lst_type->selectionSet("end");
        $lst_type->see("end");
        for(my $i=0; $i < $lst_type->size(); $i++)
        {
            if ($tmp_db_type eq $lst_type->get($i))
            {
                $lst_type->selectionClear("end");
                $lst_type->selectionSet($i);
                $lst_type->see($i);
            }
        }
    }

    $tooltip->attach($lst_type,
                     -msg => "List of all the available database types.
If you don\'t know the database type, SQGNL will try to find a suitable type for you.
If the database type is \'Other\', you can not proceed any further
until you install the proper database drivers for perl (refer to user manual).");


    ### enable or disable learning -----------------------------------------
    my $chk_en_learning = $win_config->Checkbutton( -text => "Enable learning",
                                                    -anchor => "nw",
                                                    -variable => \$learn_enabled)
                                            ->pack( -fill => "x",
                                                    -side => "top",
                                                    -expand => 0);

    $tooltip->attach($chk_en_learning,
                     -msg => "Enable or disable learning grammar.");

    ### OK and Cancel ------------------------------------------------------
    my $fra_buttons = $win_config->Frame->pack( -side => "top");

    my $cmd_ok = $fra_buttons->Button( -text => "OK",
                                       -underline => 0,
                                       -command => \&OK_Pressed_config )
                                ->pack( -fill => "x",
                                        -side => "left",
                                        -ipadx => 30,
                                        -padx => 10,
                                        -expand => 0);

    $tooltip->attach($cmd_ok,
                     -msg => "Accept and save changes.  This may take some time as it may required to load the parser.");

    my $cmd_cancel = $fra_buttons->Button( -text => "Cancel",
                                           -underline => 0,
                                           -command => \&Cancel_Pressed_config )
                                   ->pack( -fill => "x",
                                           -side => "left",
                                           -ipadx => 20,
                                           -padx => 10,
                                           -expand => 0);

    $tooltip->attach($cmd_cancel,
                     -msg => "Do not accept the changes and close this window.");

    ### statusbar for this configuration window ----------------------------
    $win_config->Label( -textvariable => \$db_status,
                        -relief => "sunken",
                        -anchor => "nw",
                        -borderwidth => 2)
                ->pack( -side => "bottom",
                        -fill => "x",
                        -padx => 10,
                        -expand => 0);

    ### save the current values of the SQ-HAL configuration data ###
    $prev_db_type   = $db_type;
    $prev_db_source = $db_source;
    $prev_user      = $user;
    $prev_pwd       = $passwd;

    ### update winodw controls before displaying the window ###
    $win_config->update();

    ### make the SQGNL main window visible when this window get closed ###
    $win_config->bind("<Destroy>", sub {
                                            if ( Exists($win_sq_hal))
                                            {
                                                $win_sq_hal->MapWindow;
                                            }
                                       } );

    ### if the main window exist then hide it ###
    if ( Exists($win_sq_hal) )
    {
        $win_sq_hal->UnmapWindow;
    }

    ### show this window and process messages ###
    MainLoop;
}

# OK pressed for configuration window - save the config. data and close
# the window
sub OK_Pressed_config
{
    ### copy the tempory stored database type ###
    if ($tmp_type) { $db_type = $tmp_type; }

    ### save configuration data to a file ###
    save_config();

    ### if the configuration file is not found then close this window ###
    if ($config_file_found == 0)
    {
        $config_file_found = 1;
        $win_config->destroy();
        return 0;
    }

    ### If any one of the following configuration data is changed ###
    ### then establish new database connection and load/create    ###
    ### the SQGNL parser                                         ###
    if (($prev_db_type   ne $db_type  ) or
        ($prev_db_source ne $db_source) or
        ($prev_user      ne $user     ) or
        ($prev_pwd       ne $passwd   ))
        {
            ### disconnect the current connection ###
            disconnect_from_db();

            ### establish new database connection ###
            $db_status = "Connecting to the database...";
            $win_config->update;
            connect_to_db($db_type, $db_source, $user, $passwd );

            ### load/create the SQGNL parser ###
            $db_status = "Loading the parser to a file.  Please wait...";
            $win_config->update;
            load_parser();
            $db_status = "";
        }

    ### close/destroy configuration window        ###
    ### and bring up the main window to the front ###
    $win_config->destroy();
    $win_sq_hal->Unbusy();
    $win_sq_hal->deiconify();
}
# Cancel is pressed for config window - close the window
sub Cancel_Pressed_config

{
    ### if the config file is not found, then exit to the system ###
    if ($config_file_found == 0) { exit; }

    ### close/destroy configuration window        ###
    ### and bring up the main window to the front ###
    $win_config->destroy();
    $win_sq_hal->Unbusy();
    $win_sq_hal->deiconify();
}

# Update the list of available datasource when the user click on the
# list of database types
sub update_datasources
{
    eval
    {
        ### temporary store the selected database type        ###
        ### this is required as the list selection disappears ###
        ### when the focus is lost from the list box          ###
        $tmp_type = $lst_type->get($lst_type->curselection);

        ### remove the existing datasources from the data sources list ###
        ### and add new data sources for the selected database type    ###
        if ($tmp_type)
        {
            $lst_sources->delete(0, "end");
            $lst_sources->insert("end", &get_db_sources($tmp_type));
        }
    };
}

# Update the text area for the data source when the user select one
# data source from the list
sub select_datasource
{
    eval
    {
        ### get currently selected data source ###
        my @source = split(":", $lst_sources->get($lst_sources->curselection));

        ### delete existing data from the text area       ###
        ### and copy the new data source to the text area ###
        if (@source)
        {
            $txt_source->delete(0, "end");
            $txt_source->insert("end", $source[$#source]);
        }
    };
}

1;  ### so the 'do' command succeeds ###