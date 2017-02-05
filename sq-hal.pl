use strict;

############################################################################
# Required Modules
use Tk;
use Tk::Table;
use Tk::Text;
use Tk::Photo;
use Tk::Balloon;

############################################################################
# Global variables
use vars qw ( $user_input );      # English query typed by the user
use vars qw ( $win_sq_hal );      # the main window for SQGNL
use vars qw ( $parser );          # SQGNL parser which contains all the grammar
use vars qw ( $results );         # results of SQGNL parsing of the English query
use vars qw ( $save_parser );     # whether parser need to be required at the end (0 or 1)
use vars qw ( @learn_strs );      # temporary hold new grammar to be learned
use vars qw ( $results_table );   # table to display database records
use vars qw ( $status_text );     # status bar text to be displayed
use vars qw ( $default_status_text );  # default status bar text
use vars qw ( $txt_output );      # text area where the output of SQGNL is displayed

# SQGNL configuration variables
use vars qw ( $user );            # user name to login to the database
use vars qw ( $passwd );          # password for the database login
use vars qw ( $db_source );       # database source
use vars qw ( $db_type );         # type of database
use vars qw ( $learn_enabled );   # enable/disable learning grammar (0 - disable, 1 - enable)
use vars qw ( $rows_displayed );  # number of rows from the results query to be displayed to the user

use vars qw ( $config_file_found ); # status of the configuration file (0 or 1)

############################################################################
# Modular level variables
my $txt_input;       # text area for users to type the query

############################################################################
# Combine all the required files and
# load the subroutines from various files
do "configure.pl";     # configuration window definitions

load_config();         # load the configuration data from a file

do "parser.pl";        # SQGNL parser definitions
do "splash.pl";        # splash sceen definitions
do "database.pl";      # definitions for various database functionalities

# if the configuration file is not found then
# (either due to first-time running or confgureation file got deleted)
# show the SQGNL confiugration window to get required info
if ($config_file_found == 0) { show_config(); }

do "login.pl";         # get database login password

save_config();         # user name might have changed when login screen is
                       # called. So save the new configuration data

do "db_structure.pl";       # window definition to show/get database structure
do "create_sql.pl";         # window definition to create SQL statements manually
do "learning.pl";           # window definition to display new grammar to be learnt
do "relationships.pl";      # window definition to display/get table relationships

############################################################################
### Show the splash screen while loading the parser ###
### as the parser may take some time to load        ###
show_splash();

### Create and show the main SQGNL window ###
create_main_window();


############################################################################
# Display the spalsh screen and load parser grammar in the background
sub create_main_window
############################################################################
{
    $win_sq_hal = MainWindow->new;    # create the main SQGNL window
    $win_sq_hal->appname("SQGNL");
    $win_sq_hal->title("SQGNL: The Natural Language to SQL Translator");

    ### maximize and position the SQGNL main window ###
    my $w =  $win_sq_hal->screenwidth()-10;   # window width = screen width
    my $h =  $win_sq_hal->screenheight()-100; # window height = screen height
    $win_sq_hal->geometry("${w}x${h}+0+20");

    ########################################################################
    ### define and place window controls ###

    my $tooltip = $win_sq_hal->Balloon( -statusbar => $status_text );

    my $win_sq_hal1 = $win_sq_hal->Frame( -relief => 'flat',
                                          -borderwidth => 10)
                                  ->pack( -ipadx => 10,
                                          -fill => 'both',
                                          -expand => 1);

    $win_sq_hal1->Label( -text => "Type your question below:",
                         -anchor => "sw")
                 ->pack( -fill => "x");

    ### user input text area -----------------------------------------------
    $txt_input = $win_sq_hal1->Scrolled( 'Text', -scrollbars => 'e',
                                          -height => 2,
                                          -wrap => "word")
                                  ->pack( -side => "top",
                                          -fill => "x",
                                          -expand => 0);

    $tooltip->attach($txt_input,
                     -msg => "Type your English query here and then press Tranlate button.");

    my $fra_buttons1 = $win_sq_hal1->Frame->pack( -side => 'top',
                                              -fill => 'x',
                                              -expand => 0 );

    ### button to activate translate the English query ---------------------
    my $cmd_translate  = $fra_buttons1->Button( -text => "Translate the query to SQL",
                                              -command => \&parse_input)
                                      ->pack( -side => "left",
                                              -ipadx => 10,
                                              -anchor => "ne");

    $tooltip->attach($cmd_translate,
                     -msg => "Translate the English query into SQL.");

    ### button to clear the content in the query text area -----------------
    my $cmd_clear = $fra_buttons1->Button( -text => "Clear",
                                           -command =>
                                           sub
                                           {
                                               ### delete everything in the text area ###
                                               $txt_input->delete("1.0", "end");
                                           }
                                         )
                                ->pack( -side => "left",
                                        -ipadx => 10,
                                        -padx => 10,
                                        -anchor => "ne");

    $tooltip->attach($cmd_clear,
                     -msg => "Clear the text in the English query area.");

    ### button to bring up the create_sql window ---------------------------
    my $cmd_create_sql = $fra_buttons1->Button( -text => "Create your own SQL",
                                             -command => \&show_create_sql)
                                     ->pack( -side => "right",
                                             -ipadx => 10,
                                             -anchor => "ne");

    $tooltip->attach($cmd_create_sql,
                     -msg => "Bring up the window where you can create your own SQL statements with ease.");

    my $fra_output = $win_sq_hal1->Frame->pack( -side => 'top',
                                              -fill => 'x',
                                              -expand => 0 );

    ### text area to display output results --------------------------------
    $txt_output = $fra_output->Scrolled( 'Text', -scrollbars => 'e',
                                        -height => 3,
                                        -wrap => "word")
                                ->pack( -side => "left",
                                        -anchor => "nw",
                                        -fill => "x",
                                        -expand => 1);

    $tooltip->attach($txt_output,
                     -msg => "Translated SQL statments are displayed here.
You may can modify this and press execute button\n to see the results of the SQL statment");

    ### button to execute SQL in the txt_output area -----------------------
    my $cmd_exec = $fra_output->Button( -text => "Execute SQL",
                                        -command =>
                                        sub
                                        {
                                            ### copy the content of the txt_output        ###
                                            ### (SQL statement) to the varaiable $results ###
                                            $results = $txt_output->get("1.0", "end");

                                            ### execute SQL and show the results ###
                                            if ( $results ne "")
                                            {
                                                show_data();
                                            }
                                        }
                                      )
                                ->pack( -side => "right",
                                        -ipadx => 10,
                                        -pady => 10,
                                        -anchor => "ne");

    $tooltip->attach($cmd_exec,
                     -msg => "Execute the SQL statment and display the results.");

    ### $status_text bar text area -----------------------------------------
    $default_status_text = "SQGNL: The Natural Language to SQL Translator";
    $status_text = $default_status_text;
    $win_sq_hal->Label( -textvariable => \$status_text,
                        -relief => "sunken",
                        -anchor => "nw",
                        -borderwidth => 2)
                ->pack( -side => "top",
                        -fill => "x",
                        -padx => 10,
                        -expand => 0);

    my $fra_buttons2 = $win_sq_hal1->Frame
                                   ->pack( -side => "bottom");

    ### button to bring up the database structure window -------------------
    my $cmd_database = $fra_buttons2->Button( -text => "Database",
                                             -underline => 1,
                                             -command => \&show_database)
                                     ->pack( -fill => "x",
                                             -ipadx => 20,
                                             -padx => 10,
                                             -pady => 5,
                                             -side => "left",
                                             -expand => 0);

    $tooltip->attach($cmd_database,
                     -msg => "Display the current database structure.");

    ### button to bring up the configuration window ------------------------
    my $cmd_config = $fra_buttons2->Button( -text => "Configure",
                                           -underline => 2,
                                           -command => \&show_config)
                                   ->pack( -fill => "x",
                                           -side => "left",
                                           -ipadx => 20,
                                           -padx => 10,
                                           -pady => 5,
                                           -expand => 0);

    $tooltip->attach($cmd_config,
                     -msg => "Configure SQGNL.");

    ### button to exit to the system ---------------------------------------
    my $cmd_exit = $fra_buttons2->Button( -text => "Exit",
                                          -underline => 1,
                                          -command => \&exit_sq_hal )
                                  ->pack( -fill => "x",
                                          -ipadx => 40,
                                          -padx => 10,
                                          -pady => 5,
                                          -side => "left");

    $tooltip->attach($cmd_exit,
                     -msg => "End SQGNL and Exit to the system.");

    ### table to display results from the SQL statements -------------------
    $results_table = $win_sq_hal1->Table( -rows => 1,
                                     -columns => 1,
                                     -scrollbars => "se",
                                     -relief => "groove",
                                     -borderwidth => 2,
                                     -fixedrows => 1)
                             ->pack( -side => "top",
                                     -fill => "both",
                                     -expand => 1);

    $tooltip->attach($results_table,
                     -msg => "Display data retrieved from the database.");

    ### exit the program when destroying this main window ##################
    $win_sq_hal->bind("<Destroy>", \&exit_sq_hal);

    ### set the focus to the query entering area ###
    $txt_input->focus;

    ### display  this window and start handling events ###
    MainLoop;
}


############################################################################
# parse user input and show results
sub parse_input
############################################################################
{
    ### update the statusbar text ###
    $status_text = "Translating the English statement to a SQL statement...";
    $win_sq_hal->update();

    ### the input and output files and commented lines below ###
    ### are used for testing purposes only                   ###
    #my $inputFile = "data.txt";
    #my $outputFile = "output.txt";

    #open(DATA, "< $inputFile")  || die $!;
    #open(OUT, "> $outputFile")  || die $!;

    #while (<DATA>)
    #{
    #    if (!/^#/ && !/^[\s]*\n/)       # Ignore commented lines and empty lines
    #    {
    #        print "> ";
    #        sleep 1;
    #        print;

    ### copy the English query to the variable $user_input ###
    $user_input = $txt_input->get("1.0", "end");

    ### remove special characters from the input ###
    $user_input =~ s/[:.'?!]//g;

    ### translate the user query to SQL ###
    eval{ $results = $parser->translate("\L$user_input"); };

    ### clear the current content of the output area and insert new translated SQL ###
    $txt_output->delete("1.0", "end");
    $txt_output->insert("end", $results);

    $_ = $results;

    ### if the first word of the results is "SELECT" then it is an     ###
    ### SQL statement.  Otherwise it is and untranslated error message ###
    if (/^SELECT/)
    {
        ### display the SQL statement in bule colour ###
        $txt_output->configure( -foreground => "blue" );

        ### execute SQL and show the results ###
        show_data();

        ### if there are anything to be leart, then display the learning window ###
        if ($#learn_strs >= 0) { show_learn(); }
    }
    else   ### English query not translated into SQL ###
    {
        ### if the learning is enabled, then add this English query ###
        ### to the query list that to be learnt                     ###
        if ($learn_enabled)
        {
            $learn_strs[++$#learn_strs] = "\L$user_input";
        }

        ### display the error message in red ###
        $txt_output->configure( -foreground => "red" );
    }

    ### update window controls ###
    $win_sq_hal->update();

              ### save the results in the outupt file ###
              #print OUT $user_input, $results, "\n";
    #    }
    #}


    ### close all the open files ###
    #close(DATA);
    #close(OUT);

    ### update the statusbar with default text ###
    $status_text = $default_status_text;
    $win_sq_hal->update();
}


############################################################################
# retrieve data from the database and display on to the screen
sub show_data()
############################################################################
{
    ### change the mouse icon to be busy icon ###
    $win_sq_hal->Busy;

    ### update statusbar text ###
    $status_text = "Retrieving data from the database...";
    $txt_output->configure( -foreground => "blue" );
    $win_sq_hal->update();

    ### execute the SQL results                    ###
    ### this will update the results table as well ###
    execute_sql( $results );

    ### update status bar text back to default ###
    $status_text = $default_status_text;

    ### change the mouse icon back to normal ###
    $win_sq_hal->Unbusy;
}


### used as a flag to determine the exit function is called once ###
### multiple calls to the function is posible if the user press  ###
### exit button as well as destorying the window calls the func. ###
my $already_exited = 0;

############################################################################
# exit SQGNL by disconnecting from the database and saving the parser
sub exit_sq_hal
############################################################################
{
    ### do not repeat this subroutine twice ###
    if ($already_exited) { return }
    $already_exited = 1;

    ### change the mouse icon to be busy icon ###
    $win_sq_hal->Busy;

    ### disconnect the current database connection ###
    disconnect_from_db();

    ### if required, save the parser to a file ###
    if ($save_parser)
    {
        ### update statusbar text
        $status_text = "Saving the parser to a file.  Please wait...";
        $win_sq_hal->update;
        save_parser();
    }

    ### save database structure to a file ###
    #save_db_info();

    ### exit to the system ###
    exit;
}
