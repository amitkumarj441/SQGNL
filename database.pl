use strict;

use Tk;
use DBI;

# Modular level variables
my $dbh;      # database handle
my $parent;   # parent window

# try to establish a connection to the database
sub connect_to_db
{
    my ($dbType, $dbSource, $dbUser, $dbPwd) = @_;

    if ( $win_splash ) {
        $parent = $win_splash;
    }
    else  {
        $parent = $win_config;
    }

    ### if database type is known then try connect  ###
    ### to the database using theinformation given. ###
    if (($dbType ne "Don't know") && ($dbType ne "Other"))
    {
        print "Establishing connection to DBI:$dbType:$dbSource ...\n";

        eval ### try connecting to the database ###
        {
            $dbh = DBI->connect( "DBI:$dbType:$dbSource", $dbUser, $dbPwd, { PrintError => 1, RaiseError => 1 } )
        };
        if ( $@ )   ### connection failed ###
        {
            ### display the error message to the user ###
            $parent->messageBox( -title => "Connection ERROR",
                                  -message => "Can not connect to the ${dbType} database '${dbSource}'.\n\n$@\n",
                                  -type => "OK");
            return 0;
        };
    }

    ### if the user does not know what type of database    ###
    ### s/he using, then try all available drivers until   ###
    ### a suitable driver is found.    ### i.e. connection ###
    ### with out error                                     ###
    elsif ($dbType eq "Don't know")
    {
        print "Searching for a valid database driver...\n";

        my $valid_db_driver = 0;

        ### try all the available drivers until a valid database connection is established ###
        my @db_drivers = get_db_drivers();
        foreach ( @db_drivers )
        {
            $dbType = $_;
            eval
            {
                print "Trying the connection \"DBI:${dbType}:${dbSource}\" ...\n";
                $dbh=DBI->connect( "DBI:${dbType}:${dbSource}", $dbUser, $dbPwd, { PrintError => 1, RaiseError => 1 });
            };
            if (! $@ )    ### if not an error then valid dbType ###
            {
                $valid_db_driver = 1;
                last;    ### exit the foreach loop ###
            }
        }
        if (! $valid_db_driver)  ### valid database driver is not found ###
        {
            ### display the error message to the user ###
            $parent->messageBox( -title => "Connection ERROR!",
                                 -message => "Can not connect to the database '${dbSource}'\n\nNo matching database driver is found or invalid password.\n",
                                 -type => "OK");
            return 0;
        }
    }

    else   # for case "Other"
    {
        ### display the error message to the user ###
        $parent->messageBox( -title => "Connection ERROR!",
                             -message => "Can not connect to the database '${dbSource}'\n\nYou don't have the proper database drivers installed.\n",
                             -type => "OK");
            return 0;
    }

    ### successful connection ###
    return 1;
}


# disconnect the current database connection
sub disconnect_from_db
{
    print "Disconnecting from the database...\n";
    eval
    {
        ### try to disconnect from the database ###
        $dbh->disconnect
            or warn "Disconnection Failed: $DBI::errstr\n";
    };
}

# execute the SQL statement and display the results in the main window
sub execute_sql
{
    my $sSQL = $_[0];   ### SQL statment to be executed ###

    eval   ### trap any errors ###
    {
        ### only execute SELECT statements ###
        unless ( $sSQL =~ m/select/i )  ### not a SELECT statement ###
        {
            ### print error message ###
            $win_sq_hal->messageBox( -title => "Invalid SELECT query!",
                                     -message => "Can not execute any queries other than \"SELECT\" queries",
                                     -type => "OK");
            return 0;
        }

        ### prepare the sql statement for execution ###
        my $sth = $dbh->prepare( $sSQL );

        ### execute the sql statement ###
        $sth->execute();

        ### update the status bar text ###
        $status_text = "Formatting data to be displayed...";
        $win_sq_hal->update();

        my @rows;     ### returned row containing number of columns ###
        my $i = 1;

        ### count number of columns in the results ###
        my $columns_count = $sth->{NUM_OF_FIELDS};

        my @col_type;     ### type of column data ###

        ### clear the existing results table (in the SQGNL main window ###
        for (my $i = 0; $i < $results_table->totalRows; $i++)
        {
            for (my $j = 0; $j < $results_table->totalColumns; $j++)
            {
                $results_table->put($i, $j, "");
            }
        }
        $win_sq_hal->update();

        ### add column names to the array ###
        for (my $j = 0; $j < $columns_count; $j++)
        {
            ### create headings for the results table              ###
            ### these headings are the column names in the results ###
            $results_table->put(0, $j,
                          $results_table->Label( -text => $sth->{NAME}->[$j] ,
                                                 -anchor => "nw",
                                                 -relief => "groove",
                                                 -borderwidth => 5));

            ### get the data type of the current column ###
            $col_type[++$#col_type] = $sth->{TYPE}->[$j];
        }

        ### read each row from the table ###
        while (@rows = $sth->fetchrow_array())
        {
            my $j = 0;
            my $align;  ### data alignment in the table ###

            ### read each column in the row ###
            foreach( @rows )
            {
               if ($col_type[$j] == 1)  ### data type is string ###
               {
                   $align = "nw";       ### align left ###
               }
               else                     ### data type is not string ###
               {
                   $align = "ne";       ### align right ###
               }
               ### insert data to the results table ###
               ### in the row i and coloum j        ###
               $results_table->put($i, $j++,
                         $results_table->Label( -text => "  $_  " ,
                                                -anchor => $align,
                                                -relief => "groove",
                                                -borderwidth => 2));
            }
            $i++;
            if ( $i > $rows_displayed )   ### maximum number or rows reached ###
            {
                last;   ### exit this while loop ###
            }
        }
    };
    if ( $@ )   ### execution failed ###
    {
        ### display an error message ###
        $win_sq_hal->messageBox( -title => "SQL ERROR!",
                                 -message => "Can not execute the SQL statement.\n\n$@.\n",
                                 -type => "OK");
    }
}

# get all the table names in the database
sub get_table_names
{
    my @table_names;

    eval
    {
        ### Create a statement handle to fetch table information ###
        my $tabsth = $dbh->table_info();

        ### read only the table names to the table names array ###
        while ( my ($qual, $owner, $name, $type, $remarks) =
            $tabsth->fetchrow_array() )
        {
            $table_names[++$#table_names] = $name;
        }
    };
    if ( $@ )  ### error reading table names ###
    {
        ### print a warning message ###
        warn "Can not read table information.\n";
    }

    ### retun the array containing table names ###
    return @table_names;
}

# Get column names for a particular table
sub get_column_names
{
    my $table = $_[0];    ### table name for which the column names to be found ###
    my @column_names;

    eval
    {
        ### create sql statement to fecth data from the table ###
        my $statement = "SELECT * FROM $table";

        ### prepare and execute the statement ###
        my $sth = $dbh->prepare( $statement );
        $sth->execute();

        ### count number of columns belongs to the table ###
        my $columns_count = $sth->{NUM_OF_FIELDS};

        ### add column names to the array ###
        for (my $i =0; $i < $columns_count; $i++)
        {
            $column_names[++$#column_names] = $sth->{NAME}->[$i];
        }
    };
    if ( $@ )  ### error reading column names ###
    {
        ### print a warning message ###
        warn "Can not read column names for the table ${table}\n";
    }

    ### retun the array containing column names ###
    return @column_names;
}


# Get all the available database drivers
sub get_db_drivers
{
    ### retrive and return all the available database drivers ###
    ### installed in the current system                       ###
    return DBI->available_drivers();
}

# return the data sources for a given database driver
sub get_db_sources
{
    eval
    {
        return DBI->data_sources( $_[0] )
            or warn "No data sources found!\n";
    };
}

1;    ### so the 'do' command succeeds ###
