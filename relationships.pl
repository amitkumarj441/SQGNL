use strict;

use Tk::Dialog;
use Tk::Balloon;

############################################################################
# Modular level variable
my $lst_tables;        # list of table names
my $lst_columns1;      # list of column names for the first table
my $lst_columns2;      # list of column names for the second table
my $lbl_columns1;      # label displaying the table name for the columns list 1
my $lbl_columns2;      # label displaying the table name for the columns list 2
my $win_join_tables;   # this window where table relationships are defined
my $cmd_add;           # button to add the current relationship to the relationships list
my $join_str;          # table relationship two tables
my $table1;            # selected table name 1
my $table2;            # selected table name 2
my $column1;           # selected column name 1
my $column2;           # selected column name 2
my %table_joins;       # hash of all the table relationships
my $lbl_current_joins; # all the table relationships


############################################################################
# Create and display the table relationships window
sub show_table_joins
############################################################################
{
    ### create the table relationships window ###
    $win_join_tables = $win_sq_hal->Toplevel();

    $win_join_tables->title("Table Relationships - SQ-HAL");

    ### Center the window in the screen ###
    my $h = 350;    ### window height ###
    my $w = 600;    ### window width  ###
    my $x =  int(($win_join_tables->screenwidth()-$w)/2);        ### x position ###
    my $y =  int(($win_join_tables->screenheight()-100-$h)/2);   ### y position ###
    $win_join_tables->geometry("${w}x${h}+${x}+${y}");

    ### Set the minimu and maximum sizes to be the same ###
    ### so that the user can not resize the window      ###
    $win_join_tables->minsize( $w, $h );
    $win_join_tables->maxsize( $w, $h );

    ########################################################################
    ### define and plce window controls ###

    my $tooltip = $win_db->Balloon;

    my $fra_lists = $win_join_tables->Frame->pack( -side => 'top',
                                           -fill => "x",
                                           -expand => 0);

    my $fra_list1 = $fra_lists->Frame->pack( -side => 'left',
                                           -fill => "x",
                                           -expand => 1);
    my $fra_list2 = $fra_lists->Frame->pack( -side => 'left',
                                           -fill => "x",
                                           -expand => 1);
    my $fra_list3 = $fra_lists->Frame->pack( -side => 'right',
                                           -fill => "x",
                                           -expand => 1);

    $fra_list1->Label( -text => "Select the two tables\nto be joined form the following list:")
                ->pack( -side => "top",
                        -padx => 5,
                        -fill => "x",
                        -anchor => "nw",
                        -expand => 0);

    $lbl_columns1 = $fra_list2->Label( -text => "Select the joining column\nfor the table '':")
                ->pack( -side => "top",
                        -padx => 5,
                        -fill => "x",
                        -expand => 0,
                        -anchor => "nw");

     $lbl_columns2 = $fra_list3->Label( -text => "Select the joining column\nfor the table '':")
                ->pack( -side => "top",
                        -padx => 5,
                        -fill => "x",
                        -expand => 0,
                        -anchor => "nw");

    ### list of all the table names ----------------------------------------
    $lst_tables = $fra_list1->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "multiple",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "left",
                                              -padx => 5,
                                              -fill => "both",
                                              -expand => 1);
    $tooltip->attach($lst_tables,
                     -msg => "Select the two table names which involves in the relationsip.");

    ### populate the list with table names ###
    $lst_tables->insert("end", &get_table_names());

    ### update the column names lists when table names are selected ###
    $lst_tables->bind("<ButtonPress>", \&update_column_names_3);

    ### column names list for the first table ------------------------------
    $lst_columns1 = $fra_list2->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "single",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "left",
                                              -padx => 5,
                                              -fill => "both",
                                              -expand => 1);

    ### update the relationship string when the user select the column name ###
    $lst_columns1->bind("<ButtonPress>",
                         sub
                         {
                             $column1 = $lst_columns1->get($lst_columns1->curselection);
                             create_join_str();
                         }
                        );

    $tooltip->attach($lst_columns1,
                     -msg => "Select the column name that involves in the relationship.");


    ### column names list for the second table -----------------------------
    $lst_columns2 = $fra_list3->Scrolled( 'Listbox', -scrollbars => "oe",
                                              -selectmode => "single",
                                              -border => 3,
                                              -height => 7)
                                      ->pack( -side => "right",
                                              -padx => 5,
                                              -fill => "both",
                                              -expand => 1);

    ### update the relationship string when the user select the column name ###
    $lst_columns2->bind("<ButtonPress>",
                         sub
                         {
                             $column2 = $lst_columns2->get($lst_columns2->curselection);
                             create_join_str();
                         }
                        );

    $tooltip->attach($lst_columns2,
                     -msg => "Select the column name that involves in the relationship.");

    my $fra_join_str = $win_join_tables->Frame->pack( -side => "top", -fill => "x");

    ### label to display the current relationship --------------------------
    my $lbl_join_str = $fra_join_str->Label( -textvariable => \$join_str)
                                     ->pack( -side => "left",
                                             -fill => "x");

    $tooltip->attach($lbl_join_str,
                     -msg => "the current table relationship.");

    ### button to add the current relationship to the list of --------------
    ### all the relationsihips
    $cmd_add = $fra_join_str->Button( -text => "Add",
                           -state => "disabled",
                           -command =>
                           sub
                           {
                               ### add the current relationship to the list ###

                               ### if the table relationship is already defined ###
                               if ($table_joins{"$table1, $table2"})
                               {
                                   ### confirm that the user wants to overwrite the existing relationship ###
                                   my $response = $win_join_tables->Dialog( -text => "Do you want to overwrite the existing relationship?\n",
                                                             -title => "Overwrite?",
                                                             -buttons => ["Yes", "No"])->Show;

                                   if ($response eq "Yes")
                                   {
                                       ### overwrite the existing relationship ###
                                       $table_joins{"$table1, $table2"} = "$table1.$column1 = $table2.$column2";

                                       ### update the relationship display on the window ###
                                       update_joins();
                                   }
                               }
                               else    ### table relationship does not exist ###
                               {
                                   ### add the new relationship for the hash ###
                                   $table_joins{"$table1, $table2"} = "$table1.$column1 = $table2.$column2";

                                   ### update the relationship display on the window ###
                                   update_joins();
                               }
                            }
                         )
                   ->pack( -side => "right",
                           -ipadx => 20);

    $tooltip->attach($cmd_add,
                     -msg => "add the current relationship to the list of all the relationships.");

    ### label to display all the table relationships defined ---------------
    $lbl_current_joins = $win_join_tables->Label( -text => "Current table joins:\n",
                                                  -anchor => "nw")
                                          ->pack( -side => "top",
                                                  -fill => "both",
                                                  -expand => 1);

    $tooltip->attach($lbl_current_joins,
                     -msg => "all the table relationships.");

    my $fra_buttons = $win_join_tables->Frame->pack( -side => "bottom" );

    ### button to accept changes to the table relationships ----------------
    my $cmd_accept_all = $fra_buttons->Button( -text => "Accept all",
                                          -command => \&ok_pressed_for_join )
                                  ->pack( -side => "left",
                                          -padx => 10,
                                          -ipadx => 15,
                                          -pady => 10 );

    $tooltip->attach($cmd_accept_all,
                     -msg => "accept all the changes to the table relationships and close this window.");

    ### button to close this window ----------------------------------------
    my $cmd_close = $fra_buttons->Button( -text => "Cancel",
                                     -command =>
                                     sub
                                     {
                                         $win_join_tables->destroy();
                                     } )
                             ->pack( -side => "right",
                                     -padx => 10,
                                     -ipadx => 15,
                                     -pady => 10 );

    $tooltip->attach($cmd_close,
                     -msg => "ignore all the changes to the table relationships and close this window.");

    ### copy existing table joins to a hash variable ###
    %table_joins = ();
    foreach my $table (keys(%table_relationships))
    {
        foreach (keys(%{$table_relationships{$table}}))
        {
            $table_joins{"$table, $_"} = $table_relationships{$table}{$_};
        }
    }

    ### make the database structure window visible when this window get closed ###
    $win_join_tables->bind('<Destroy>', sub{ $win_db->MapWindow; $win_db->deiconify; } );

    ### update table joins display area ###
    update_joins();

    $win_join_tables->update();

    ### display this window ###
    $win_join_tables->raise();

    ### hide the database structure window ###
    $win_db->UnmapWindow;
}

############################################################################
# updata the two column names list with the column names for the
# two selected tables
sub update_column_names_3
############################################################################
{
    eval
    {
        ### get the indexes of the selected table names
        my @tables = $lst_tables->curselection;
        my @table_names;

        ### get the selected table names ###
        foreach ( @tables )
        {
            $table_names[++$#table_names] = $lst_tables->get($_);
        }

        ### only the first two table names are used in the table relationship ###
        ### the other table names are ignored                                 ###
        $table1 = $table_names[0];

        if ( $table_names[1] ) {
            $table2 = $table_names[1];
        }
        else {
            $table2 =  "";
        }



        ### update the labels above column names lists to display ###
        ### the coresponding table name for each list             ###
        $lbl_columns1->configure( -text => "Select the joining column\nfor the table '$table1':");
        $lbl_columns2->configure( -text => "Select the joining column\nfor the table '$table2':");

        $column1 = "";
        $column2 = "";

        ### clear column names lists ###
        $lst_columns1->delete(0, "end");
        $lst_columns2->delete(0, "end");

        ### if the first table name is defined,     ###
        ### then update the first column names list ###
        if ($table1)
        {
            eval { $lst_columns1->insert("end", &get_column_names($table1)); };
        }

        ### if the second table name is defined,     ###
        ### then update the second column names list ###
        if ($table2)
        {
            eval { $lst_columns2->insert("end", &get_column_names($table2)); };
        }

        ### create the current table relationship ###
        create_join_str();
    };
}


############################################################################
# create the current tables relationship using the select table names
# and column names
sub create_join_str
############################################################################
{
    ### define the current table relationship and display on the window ###
    $join_str = "Join tables  [ $table1, $table2 ]  on  [ $table1.$column1 = $table2.$column2 ]";

    ### all the table names and column names are defined ###
    if ($table1 && $table2 && $column1 && $column2)
    {
        ### enable the 'Add' button ###
        $cmd_add->configure( -state => "normal" );
    }
    else ### not all the table names and column names are defined ###
    {
        $cmd_add->configure( -state => "disabled" );

    }

    ### update window controls with new values ###
    $win_join_tables->update;
}

############################################################################
# update the label which display all the defined relationships
sub update_joins
############################################################################
{
    my $str = "Current table joins:\n";

    ### create a string which contains formatted table relationships
    foreach (keys(%table_joins))
    {
        $str .= "Join tables [ $_ ] on [ ${table_joins{$_}} ]\n";
    }

    ### display the table relationships sting ###
    $lbl_current_joins->configure( -text => $str );
}

############################################################################
# save the relationships and close this window
sub ok_pressed_for_join
############################################################################
{
    ### empth the table relationships hash ###
    %table_relationships = ();

    ### copy existing relationships to table relationships ###
    ### i.e. save changes to the table relationships
    foreach my $tables (keys(%table_joins))
    {
        my ($tb1, $tb2) = split(", ", $tables);

        $table_relationships{$tb1}{$tb2} = $table_joins{$tables};
    }

    ### save database structure to a file ###
    save_db_info();

    ### close this window ###
    $win_join_tables->destroy();
 }

1;    ### so the 'do' command succeeds ###
