use strict;

use Tk;
use Tk::DialogBox;
use Tk::Balloon;

# Modular level variables
my $lst_tables;         # list of table names
my $lst_columns;        # list of column names
use vars qw{ $win_db }; # database structure window


# Display the database structure window
sub show_database
{
    ### create the database structure window ###
    $win_db = $win_sq_hal->Toplevel();

    $win_db->title("Database view - SQGNL");

    ### center the window in the screen ###
    my $h = 220;      ### window height ###
    my $w = 400;      ### window width  ###
    my $x =  int(($win_db->screenwidth()-$w)/2);       ### x position ###
    my $y =  int(($win_db->screenheight()-100-$h)/2);  ### y position ###
    $win_db->geometry("${w}x${h}+${x}+${y}");

    ### Set the minimu and maximum sizes to be the same ###
    ### so that the user can not resize the window      ###
    $win_db->minsize( $w, $h );
    $win_db->maxsize( $w, $h );

    ### define and plce window controls ###

    my $tooltip = $win_db->Balloon;

    my $fra_labels = $win_db->Frame->pack( -side => 'top',
                                           -fill => "x",
                                           -expand => 0);

    $fra_labels->Label( -text => "Tables:")
                ->pack( -side => "left",
                        -padx => 5,
                        -fill => "x",
                        -expand => 0,
                        -anchor => "w");

    $fra_labels->Label( -text => "Columns:")
                ->pack( -side => "right",
                        -padx => 5,
                        -fill => "x",
                        -expand => 0,
                        -anchor => "w");

    my $fra_lists = $win_db->Frame->pack( -side => 'top',
                                           -fill => "x",
                                           -expand => 0);

    ### list of all the tables in the database -----------------------------
    $lst_tables = $fra_lists->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "single",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "left",
                                              -padx => 5,
                                              -fill => "both",
                                              -expand => 1);

    ### populate the list with all the table names ###
    $lst_tables->insert("end", &get_table_names());

    ### call the column list update routine when the user ###
    ### select one of the table names from this list      ###
    $lst_tables->bind("<ButtonPress>", \&update_column_names_);

    $tooltip->attach($lst_tables,
                     -msg => "List of all the table names in the database.");

    ### list of all the columns in the selected table ---------------------
    $lst_columns = $fra_lists->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "single",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "right",
                                              -padx => 5,
                                              -fill => "both",
                                              -expand => 1);

    ### populate the list with column names for the first table name ###
    ### in the table names list                                      ###
    eval { $lst_columns->insert("end", &get_column_names($lst_tables->get(0))); };

    my $fra_buttons = $win_db->Frame->pack( -side => "top",
                                            -fill => "x");

    $tooltip->attach($lst_columns,
                     -msg => "List of all the column names for the selected table.");

    ### button to enter related words for table and column names -----------
    my $cmd_table_related = $fra_buttons->Button( -text => "Related words",
                                                  -command => \&get_table_words)
                                          ->pack( -side => "left",
                                                  -ipadx => 10,
                                                  -padx => 10);

    $tooltip->attach($cmd_table_related,
                     -msg => "Enter related words for the selected table.");

    my $cmd_column_related = $fra_buttons->Button( -text => "Related words",
                                                   -command => \&get_column_words)
                                           ->pack( -side => "right",
                                                   -ipadx => 10,
                                                   -padx => 10);

    $tooltip->attach($cmd_column_related,
                     -msg => "Enter related words for the selected column.");

    my $fra_buttons2 = $win_db->Frame->pack( -side => "top");

    ### buton to bring up the table joins window ---------------------------
    my $cmd_relationships = $fra_buttons2->Button( -text => "Table Relationships",
                                                   -command => \&show_table_joins)
                                           ->pack( -side => "left",
                                                   -padx => 10);

    $tooltip->attach($cmd_relationships,
                     -msg => "Bring up the window where you can enter the table relationships.");

    ### button to close this window ----------------------------------------
    my $cmd_close = $fra_buttons2->Button( -text => "Close",
                                           -command => sub { $win_db->destroy(); })
                                   ->pack( -side => "top",
                                           -ipadx => 30,
                                           -pady => 10 );

    $tooltip->attach($cmd_close,
                     -msg => "Close this window and bring up the main SQGNL window to the front.");

    ### make the SQGNL main window visible when this window get closed ###
    $win_db->bind('<Destroy>', sub{ $win_sq_hal->MapWindow; $win_sq_hal->deiconify; } );

    ### show this database window and hide the SQGNL main window ###
    $win_db->update();

    $win_sq_hal->UnmapWindow;    ### hide the main window ###

    $win_db->raise();            ### show this window     ###
}


# Update the column names list with the column names of the selected table
sub update_column_names_
{
    eval   ### ignore any errors ###
    {
        ### get the currently selected table name ###
        my $table = $lst_tables->get($lst_tables->curselection);

        ### clear the column names list and insert new column names ###
        if ($table)
        {
            $lst_columns->delete(0, "end");
            $lst_columns->insert("end", &get_column_names($table));
        }
    };
}


# Get the related words for the selected table name
sub get_table_words
{
    my $table = "";
    eval
    {
        ### get the selected table name ###
        $table = $lst_tables->get($lst_tables->curselection);
    };

    ### if any table name is selected then... ###
    if ($table)
    {
        ### create a dialog box to get the related words ###
        my $dlg = $win_db->DialogBox( -title => "Related words for: $table",
                                      -buttons => ["OK", "Cancel"]);

        my $tooltip = $dlg->add("Balloon");

        $dlg->add("Label", -text => "Enter related words for the word '$table': (comma seperated)",
                           -anchor => "nw")->pack( -fill => "x" );

        ### text area to enter related words -------------------------------
        my $txt_words = $dlg->add("Text", -height => 3)->pack;

        $tooltip->attach($txt_words,
                         -msg => "Enter related words for the table name.  Words needs be comma sepearted.");

        my $response  = $dlg->Show;

        if ($response eq "OK")
        {
            ### add each new table word to the SQGNL parser ###
            my @new_words = split(",", $txt_words->get("1.0", "end"));
            chomp(@new_words);

            foreach (@new_words)
            {
                $save_parser = 1;
                extend_parser("table", "/$_/{'$table'}");
            }
        }
    }
    else  ### no table name is selected ###
    {
        ### display inforative error message ###
        $win_db->messageBox( -title => "No table name is selected",
                             -message => "Please select the table name\nfrom the table names list first.\n",
                             -type => "OK");
    }
}


# Get the related words for the selected column name
sub get_column_words
{
    my $column = "";
    eval
    {
        ### get the selected column name ###
        $column = $lst_columns->get($lst_columns->curselection);
    };

    ### if any column name is selected then... ###
    if ($column)
    {
        ### create a dialog box to get the related words ###
        my $dlg = $win_db->DialogBox( -title => "Related words for: $column",
                                      -buttons => ["OK", "Cancel"]);
        my $tooltip = $dlg->add("Balloon");

        $dlg->add("Label", -text => "Enter related words for the word '$column': (comma seperated)",
                           -anchor => "nw")->pack( -fill => "x" );

        ### text area to enter related words -------------------------------
        my $txt_words = $dlg->add("Text", -height => 3)->pack;

        $tooltip->attach($txt_words,
                         -msg => "Enter related words for the column name.  Words needs be comma sepearted.");

        my $response  = $dlg->Show;

        if ($response eq "OK")
        {
            ### add each new column word to the SQGNL parser ###
            my @new_words = split(",", $txt_words->get("1.0", "end"));
            chomp(@new_words);

            foreach (@new_words)
            {
                $save_parser = 1;
                extend_parser("field", "/$_/{'$column'}");
            }
        }
    }
    else       ### no column name is selected ###
    {
        ### display inforative error message ###
        $win_db->messageBox( -title => "No column name is selected",
                             -message => "Please select the column name\nfrom the column names list first.\n",
                             -type => "OK");
    }
}

1;   # so the 'do' command succeeds
