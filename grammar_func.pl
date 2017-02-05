use strict;

package Parse::RecDescent;

### messages to display if SQGNL do not understand grammar ###
my @messages = (
    "Could you rephrase that?",
    "What do you mean by that?",
    "What are your trying to say?",
    "I don't understand what you saying?",
);

### month numbers into month string ###
my %month  =
(
    "01"    =>    "Jan",
    "02"    =>    "Feb",
    "03"    =>    "Mar",
    "04"    =>    "Apr",
    "05"    =>    "May",
    "06"    =>    "Jun",
    "07"    =>    "Jul",
    "08"    =>    "Aug",
    "09"    =>    "Sep",
    "10"    =>    "Oct",
    "11"    =>    "Nov",
    "12"    =>    "Dec"
);


# return random message to be outputed for unmactched grammer
sub unknown_msg
{
    ### return a random message from the messages list ###
    return "${messages[int(rand (1+$#messages))]}\n";

}   ## unknown_msg


# check whether the given field name exist in the table
# arguments arg0 = field, arg1 = table
sub check_field
{
    ### return 1 if the field belongs to the specified table ###
    ### otherwise retrun undef                               ###
    return $main::table_columns {$_[1]} {$_[0]};

}   ## check_field


# convert the string into the date format
# return the date in the "#DD-MMM-YYYY#" format
sub parse_date
{
    use Date::Manip;

    eval
    {
        ### convert date string to a proper date ###
        my $date = &ParseDate($_[0]) || return;

        ### return the date as US format date ###
        ### i.e. in the form of DD-MMM-YYYY   ###
        return substr($date,6,2)."-".$month{substr($date,4,2)}."-".substr($date,0,4);
    };
}   ## parse_date

# check the relationship between two tables and if there is a relationship
# then return the corresponding relationship
# arguments - arg0 - table1, arg1 - table 2
sub check_relationship
{
    ### return the relationship between the two tables ###
    return ($main::table_relationships{$_[0]}{$_[1]} || $main::table_relationships{$_[1]}{$_[0]});

}   ## check_relationship

# check for the type of the data and put appropriate quotes or
# hash (#) around it
sub format_val
{
    my $val = $_[0];

    ### remove fornt and end spaces from the input ###
    $val =~ s/^ //;
    $val =~ s/ $//;

    ### remove any quotation marks ###
    $val =~ s/^"//;
    $val =~ s/"$//;

    ### remove the dollar size - these will be interpreted as numbers ###
    $val =~ s/^\$//;

    ### check if the input is a value ###
    if($val =~ m/^(-?)\d+\.*\d*$/)   ### value is a number ###
    {
        return $val;
    }
    elsif ($val =~ m/^\d{1,2}-[A-Z|a-z]{3}-\d{4}$/)    ### date string ###
    {
        ### put hashes around the value ###
        return "#${val}#";
    }
    else    ### string value ###
    {
        ### put quotes around the value ###
        return "\"${val}\"";
    }
}


### various subroutines to define SQL statments ###
###=========================================================================
# SELECT QUERIES

sub Select_T1_F0_C0 { return "SELECT *\nFROM ${_[0]}\n"; }

sub Select_T1_F1_C0 { return "SELECT DISTINCT ${_[0]}\nFROM ${_[1]}\n"; }

sub Select_T1_F2_C0 { return "SELECT DISTINCT ${_[0]}, ${_[1]}\nFROM ${_[2]}\n"; }

sub Select_T1_F0_C1 { return "SELECT *\nFROM ${_[0]}\n${_[1]}\n"; }

sub Select_T1_F1_C1 { return "SELECT DISTINCT ${_[0]}\nFROM ${_[1]}\n${_[2]}\n"; }

sub Select_T1_F2_C1 { return "SELECT DISTINCT ${_[0]}, ${_[1]}\nFROM ${_[2]}\n${_[3]}\n"; }

sub Select_T2_F0_C0 {
    my $relationship = check_relationship($_[0], $_[1]);
    return "SELECT ${_[0]}.*, ${_[1]}.*\nFROM ${_[0]}, ${_[1]} WHERE $relationship\n";
}

sub Select_T2_F1_C0 {
    my $relationship = check_relationship($_[2], $_[3]);
    return "SELECT DISTINCT $_[0].$_[1]\nFROM $_[2], $_[3]\nWHERE $relationship\n";
}

sub Select_T2_F2_C0 {
    my $relationship = check_relationship($_[4], $_[5]);
    return "SELECT DISTINCT $_[0].$_[1], $_[2].$_[3]\nFROM $_[4], $_[5]\nWHERE $relationship\n";
}

sub Select_T2_F0_C1 {
    my $relationship = check_relationship($_[0], $_[1]);
    return "SELECT ${_[0]}.*, ${_[1]}.*\nFROM ${_[0]}, ${_[1]} WHERE $relationship AND $_[2].$_[3]=$_[4]\n";
}

sub Select_T2_F1_C1 {
    my $relationship = check_relationship($_[2], $_[3]);
    return "SELECT DISTINCT $_[0].$_[1]\nFROM $_[2], $_[3]\nWHERE $relationship AND $_[4].$_[5]=$_[6]\n";
}

sub Select_T2_F2_C1 {
    my $relationship = check_relationship($_[4], $_[5]);
    return "SELECT DISTINCT $_[0].$_[1], $_[2].$_[3]\nFROM $_[4], $_[5]\nWHERE $relationship AND $_[6].$_[7]=$_[8]\n";
}

###=========================================================================
# COUNT QUERIES
sub Count_T1_F0_C0 { return "SELECT COUNT(*) AS number_of_$_[0]\nFROM $_[0]\n"; }

sub Count_T1_F1_C0 { return "SELECT DISTINCT COUNT($_[0]) AS number_of_$_[0]\nFROM $_[1]\n"; }

sub Count_T1_F0_C1 { return "SELECT COUNT(*) AS number_of_$_[0]\nFROM $_[0]\n$_[1]\n"; }

sub Count_T1_F1_C1 { return "SELECT COUNT($_[0]) AS number_of_$_[0]\nFROM $_[1]\n$_[2]\n"; }

###=========================================================================
# SUM QUERIES
sub Sum_T1_F1_C0 { return "SELECT SUM($_[0]) AS total_$_[0]\nFROM $_[1]\n"; }

sub Sum_T1_F1_C1 { return "SELECT SUM($_[0]) AS total_$_[0]\nFROM $_[1]\n$_[2]\n"; }

###=========================================================================
# AVERAGE QUERIES
sub Average_T1_F1_C0 { return "SELECT AVG($_[0]) AS average_$_[0]\nFROM $_[1]\n"; }

sub Average_T1_F1_C1 { return "SELECT AVG($_[0]) AS average_$_[0]\nFROM $_[1]\n$_[2]\n";}

1;    ### so the 'do' command succeeds ###
