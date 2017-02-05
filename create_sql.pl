use strict;

use Tk;
use Tk::Balloon;

# Modular level variables
my $lst_tables;                # list of all the table names
my $lst_columns;               # list of all the column names for selected tables
my $txt_sql;                   # SQL statment created
my $win_create_sql;            # this window for creating SQL
my $selected_table = '';       # selected table name(s)
my $selected_columns = '*';    # selected column name(s)
my $tbl_conditions;            # SQL condition(s)


# Create and show the window for creating SQL statements
sub show_create_sql
{
    ### create the window ###
    $win_create_sql = $win_sq_hal->Toplevel;

    $win_create_sql->title("Create SQL - SQGNL");

    ### center the window in the screen ###
    my $h = 350;
    my $w = 700;
    my $x = int(($win_create_sql->screenwidth()-$w)/2);
    my $y = int(($win_create_sql->screenheight()-100-$h)/2);
    $win_create_sql->geometry("${w}x${h}+${x}+${y}");

    ### Set the minimu and maximum sizes to be the same ###
    ### so that the user can not resize the window      ###
    $win_create_sql->minsize( $w, $h );
    $win_create_sql->maxsize( $w, $h );

    ### define and place window controls ###

    my $tooltip = $win_create_sql->Balloon;

    my $frame1 = $win_create_sql->Frame->pack( -side => "top",
                                           -fill => "x",
                                           -expand => 1);

    my $fra_tables = $frame1->Frame->pack( -side => "left",
                                           -fill => "x",
                                           -expand => 1);

    my $fra_columns = $frame1->Frame->pack( -side => "left",
                                           -fill => "x",
                                           -expand => 1);

    $fra_tables->Label( -text => "Select the table(s)\n from the list:",
                            -anchor => "nw")
                    ->pack( -side => "top",
                            -fill => "x",
                            -expand => 0 );

   ### list of all the table names -----------------------------------------
   $lst_tables = $fra_tables->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "multiple",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "left",
                                              -padx => 5,
                                              -fill => "y",
                                              -expand => 1);

    $lst_tables->insert("end", get_table_names());

    $tooltip->attach($lst_tables,
                     -msg => "Select one or more tables from this list.");

    $fra_columns->Label( -text => "Select what columns\nyou want to see:",
                            -anchor => "nw")
                    ->pack( -side => "top",
                            -fill => "x",
                            -expand => 0 );

    ### list of all the column names for selected table(s) -----------------
    $lst_columns = $fra_columns->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "multiple",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "left",
                                              -padx => 5,
                                              -fill => "y",
                                              -expand => 1);

    $tooltip->attach($lst_columns,
                     -msg => "Select one or more column names from this list.");

    ### table use to display various SQL conditions ------------------------
    $tbl_conditions = $fra_columns->Table( -rows => 7,
                                           -scrollbars => "se",
                                           -columns => 2)
                                   ->pack( -side => "right",
                                           -fill => "both",
                                           -expand => 1);

    ### when selecting column names, update the string for the selected ###
    ### column and the new SQL statement                                ###
    $lst_columns->bind("<ButtonPress>", \&update_selected_columns);

    ### when table name is selected, update the column names list ###
    ### and conditions list                                       ###
    $lst_tables->bind("<ButtonPress>",
          sub
          {
              update_column_names();
              ### clear the conditions table ###
              for (my $i = 0; $i < $tbl_conditions->totalRows; $i++)
              {
                  for (my $j = 0; $j < $tbl_conditions->totalColumns; $j++)
                  {
                      $tbl_conditions->put($i, $j, "");
                  }
              }
              ### fill the conditons table with new values ###
              for (my $i = 1; $i < $lst_columns->size; $i++)
              {
                  my @txt_conditions;
                  ### insert the column name label to the conditions table ###
                  $tbl_conditions->put($i, 0, $tbl_conditions->Label( -text => $lst_columns->get($i), -anchor => "e"));

                  ### create entry field to enter the condition ###
                  $txt_conditions[$i] = $tbl_conditions->Text( -height => 1, -width => 15);

                  ### insert the condition entry field table ###
                  $tbl_conditions->put($i, 1, $txt_conditions[$i]);

                  ### update the SQL statement every time user type ###
                  ### something in this condition field             ###
                  $txt_conditions[$i]->bind("<KeyPress>", \&create_sql);

                  ### tooltip for the condition entry fields ###
                  $tooltip->attach($txt_conditions[$i],
                                   -msg => "Type the condition here.\ne.g. \"\> 100\" or \"= 'Abc'\"");
              }
          });

    $win_create_sql->Label( -text => "SQL statement (or type your own):",
                            -anchor => "nw")
                    ->pack( -side => "top",
                            -fill => "x",
                            -expand => 0 );

    ### SQL statement created ----------------------------------------------
    $txt_sql = $win_create_sql->Text( -height => 5)
                                 ->pack( -side => "top",
                                         -fill => "x",
                                         -expand => 0 );

    $tooltip->attach($txt_sql,
                     -msg => "SQL statement created.  You can edit this or type your own SQL statements.");

    my $fra_buttons = $win_create_sql->Frame->pack( -side => "top" );

    ### OK and Cancel buttons ----------------------------------------------
    my $cmd_ok = $fra_buttons->Button( -text => "OK",
                                       -underline => 0,
                                       -command => \&Update_SQL )
                                ->pack( -fill => "x",
                                        -side => "left",
                                        -ipadx => 30,
                                        -padx => 10,
                                        -pady => 10,
                                        -expand => 0);

    $tooltip->attach($cmd_ok,
                     -msg => "Accept the SQL statement created and close this window.");

    my $cmd_cancel = $fra_buttons->Button( -text => "Cancel",
                                           -underline => 0,
                                           -command => sub { $win_create_sql->destroy(); } )
                                        ->pack( -fill => "x",
                                           -side => "left",
                                           -ipadx => 20,
                                           -padx => 10,
                                           -pady => 10,
                                           -expand => 0);

    $tooltip->attach($cmd_cancel,
                     -msg => "Close this window.");

    ### make the SQGNL main window visible when this window get closed ###
    $win_create_sql->bind('<Destroy>', sub{ $win_sq_hal->MapWindow; $win_sq_hal->deiconify; } );

    ### update winodw controls before displaying the window ###
    $win_create_sql->update();

    ### show this window ###
    $win_create_sql->raise();

    ### hide the SQGNL main window ###
    $win_sq_hal->UnmapWindow;
}

# Update the SQL statement are in the main window and close this window
sub Update_SQL
{
    ### make this window busy by changing the mouse icon ###
    $win_create_sql->Busy;

    ### update the SQL statment area in the main window ###
    $results = $txt_sql->get("1.0", "end");
    $txt_output->delete("1.0", "end");
    $txt_output->insert("end", $results);

    ### execute the newly created SQL statement and ###
    ### update the SQL results table                ###
    show_data();

    ### close this window ###
    $win_create_sql->destroy();
}

# Update the column names list with the column names for the selected table(s)
# and update the SQL statement created
sub update_column_names
{
    eval    ### ignore any errors ###
    {
        ### get the indexes of the currently selected tables ###
        my @table_indexes = $lst_tables->curselection;

        $lst_columns->delete(0, "end");
        $lst_columns->insert("end", "All columns");

        $selected_table = "";

        ### for each of the index in the table names selection ... ###
        foreach (@table_indexes)
        {
            ### get the table name ###
            my $table = $lst_tables->get($_);

            ### update the string for the selected table names in the SQL ###
            $selected_table .= "${table}, ";

            if ($#table_indexes == 0) ### if there is only one table selected ###
            {
                ### get the column names for the selected table ###
                ### and insert to the column names list         ###
                $lst_columns->insert("end", &get_column_names($table));
            }
            else  ### if more than one table is selected ###
            {
                ### get the column names for the selected tables ###
                ### and insert to the column names list          ###
                ### the column name need to be updated to        ###
                ### <table_name>.<column_name> format            ###
                $lst_columns->insert("end", split(":", "${table}.".(join(":${table}.", (&get_column_names($table))))));
            }
        }

        ### remove the last "' " characters from selected_tables string ###
        chop($selected_table);
        chop($selected_table);

        ### default selected columns is "*" - all columns ###
        $selected_columns = "*";

        ### create the SQL statement using the new values ###
        create_sql();
    };
}

# Get the selected column names and update the SQL statement created
sub update_selected_columns

{
    eval    ### ignore any errors ###
    {
        ### if the list item "All columns" is selected ###
        if ($lst_columns->selectionIncludes(0))
        {
            $selected_columns = "*";
            create_sql();
        }
        else  ### not all the columns, only the selected column names ###
        {
            ### get the indexes of the current selection ###
            my @columns = $lst_columns->curselection;
            my @column_names;

            foreach ( @columns )
            {
                ### Get the column names of the selection ###
                $column_names[++$#column_names] = $lst_columns->get($_);
            }

            ### update the column names string
            $selected_columns = join( ", ", @column_names);

            ### create the SQL statement using the new values ###
            create_sql();
        }
    };
}

sub create_sql
{
    ### insert the SQL statement to the statement display area ###
    $txt_sql->delete("1.0", "end");
    $txt_sql->insert("end", "SELECT $selected_columns\nFROM $selected_table\n");

    ### create and append SQL conditions ###
    my $condition = "";

    ### get the selected table names to an array ###
    my @tbls = split(", ", $selected_table);

    ### append all the table relationships between each pair of tables ###
    ### to the SQL conditions                                          ###
    if ($#tbls)
    {
        for (my $i= 0; $i < $#tbls; $i++)
        {
            for (my $j = $i+1; $j <= $#tbls; $j++)
            {
                ### if table relationship is defined between the selected tables ###
                ### append it the SQL condtions string                           ###
                if ( my $relationship = $table_relationships{$tbls[$i]}{$tbls[$j]} )
                {
                    if ($condition)  ### the condition string already contains some condtions ###
                    {
                        $condition .= "\n\tAND $relationship";
                    }
                    else  ### the conditions string is empty ###
                    {
                        $condition .= $relationship;
                    }
                }
            }
        }
    }

    ### add other user entered conditions ###
    for (my $i = 1; $i < $tbl_conditions->totalRows; $i++)
    {
       ### get the entered condition for each entry ###
       my $entry = $tbl_conditions->get($i, 1)->get("1.0", "end");
       chomp($entry);

       ### if the condition entry is not empty then ###
       ###  append it to the condtions string       ###
       if ($entry)
       {
            if ($condition)
            {
                $condition .= "\n\tAND "
            }
            $condition .=  $tbl_conditions->get($i, 0)->cget( '-text' ) . " ${entry}";
       }
    }

    ### append the condition to the end of the SQL statement ###
    if ($condition)
    {
        $txt_sql->insert("end", "WHERE $condition\n");
    }

    ### update the SQL statment field ###
    $win_create_sql->update();
}

1;    ### so the 'do' command succeeds ###
