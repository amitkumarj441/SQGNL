use strict;

use Tk;
use Tk::Table;

# Modular level variables
my $win_learn;
my $learn_table;
my @selected;

# create and display learn grammar window
sub show_learn
{
    ### create the learn grammar window ###
    $win_learn = $win_sq_hal->Toplevel;

    $win_learn->title("Learn Grammar - SQGNL");

    ### center the window in the screen ###
    my $h = 350;
    my $w = 600;
    my $x = int(($win_learn->screenwidth()-$w)/2);
    my $y = int(($win_learn->screenheight()-100-$h)/2);
    $win_learn->geometry("${w}x${h}+${x}+${y}");

    ### define and place window controls ###

    my $tooltip = $win_learn->Balloon;

    $win_learn->Label( -text => "Select which items to be learned:",
                       -anchor => "nw")
               ->pack( -side => "top",
                       -fill => "x");

    my $fra_buttons = $win_learn->Frame->pack( -side => "bottom");

    ### label to display the grammar understood by the SQGNL --------------
    my $lbl_input = $win_learn->Label( -textvariable => \$user_input,
                                       -wraplength => ($w - 50),
                                       -anchor => "nw")
                               ->pack( -side => "bottom",
                                       -fill => "x");

    $win_learn->Label( -text => "which have the same meaning as:",
                       -anchor => "nw")
               ->pack( -side => "bottom",
                       -fill => "x");

    $tooltip->attach($lbl_input,
                     -msg => "Valid grammar understood by SQGNL.");

    ### table to display list of new grammars to be learn ------------------
    $learn_table = $win_learn->Table( -rows => 15,
                                         -scrollbars => "se",
                                         -columns => 1)
                                 ->pack( -side => "top",
                                         -fill => "x");

    $tooltip->attach($learn_table,
                     -msg => "Select what grammars you want SQGNL to learn and press \"Learn\" button.");

    ### add each of the new grammar to the table ###
    my $i = 0;
    foreach ( @learn_strs )
    {
        $selected[++$#selected] = 0;
        ### check button so that user can select what new grammar to be learn ###
        $learn_table->put($i++, 0, $learn_table->Checkbutton( - text => $_ ,
                                                              -wraplength => ($w-50),
                                                              -anchor => "nw",
                                                              -variable => \${selected[$#selected]})
                                                      ->pack( -fill => "x" ) );
        #$tooltip->attach($chk_grammar[i-1],
        #                 -msg => "Select this grammar if you want SQGNL to learn it.");
    }

    ### button to activate learning the selected grammar ###
    my $cmd_learn = $fra_buttons->Button( -text => "Learn",
                                          -command => \&learn_strs)
                                  ->pack( -side => "left",
                                          -padx => 10,
                                          -pady => 10,
                                          -ipadx => 10);

     $tooltip->attach($cmd_learn,
                      -msg => "Learn selected grammars and close this window.");

    ### button to close this window ###
    my $cmd_close = $fra_buttons->Button( -text => "Cancel",
                                          -default => "active",
                                          -command => sub{ $win_learn->destroy; })
                                  ->pack( -side => "right",
                                          -padx => 10,
                                          -pady => 10,
                                          -ipadx => 10);

     $tooltip->attach($cmd_close,
                      -msg => "Close this window with out learning new grammar.");

    ### make the SQGNL main window visible when this window get closed ###
    $win_learn->bind('<Destroy>', sub{ $win_sq_hal->MapWindow; $win_sq_hal->deiconify; } );

    ### update windows controls ###
    $win_learn->update;

    ### display he window ###
    $win_learn->raise;

    ### hide the SQGNL main window ###
    $win_sq_hal->UnmapWindow;
}


############################################################################
# learn the selected grammar and close this window
sub learn_strs
############################################################################
{
    ### change the mouse icon to be busy ###
    $win_learn->Busy;

    my $i = 0;

    ### learn each of the selected grammar ###
    foreach my $selected (@selected)
    {
        if ($selected)
        {
            extend_parser( "learned", create_learn_str($learn_strs[$i]) );
        }
        $i++;
    }

    ### clear the learn strings array ###
    @learn_strs = ();

    ### close this window ###
    $win_learn->destroy;
}


############################################################################
# create the parser grammar by analying the user input
sub create_learn_str
############################################################################
{
    my $str = $_[0];            ### grammar to be learn ###
    my $learn_out = $results;   ### SQL statement for the coresponding grammar ###
    my $learn_query = "";       ### the learn string ###
    my $i = 1;

    ### break the learn string into words and analyse each word ###
    foreach my $word ( split(" ", $str) )
    {
        ### check if the word is a table name ###
        if ( my $table = $parser->table($word) )
        {
            $learn_query .= " table";

            ### replace the table word with the item number ###
            $learn_out =~ s/$table/\$item\[$i\]/;
        }
        ### check if the word is a column name ###
        elsif (  my $field = $parser->field($word) )
        {
            $learn_query .= " field";

            ### replace the column word with the item number ###
            $learn_out =~ s/$field/\$item\[$i\]/;
        }
        else  ### not a table name or field name ###
        {
            $learn_query .= " /$word/";
        }
        $i++;
    }
    $learn_query .= " eol";

    ### return the query to be learn ###
    return "$learn_query { qq($learn_out) }";
}

1;    ### so the 'do' command succeeds ###
