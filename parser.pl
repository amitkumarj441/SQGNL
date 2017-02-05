use strict;

############################################################################
# Global variables
use vars qw( %table_columns );
use vars qw( %table_relationships );

############################################################################
# Modular level variables

### Following variables used to test this parser only ###
my $dataFile    = "data1.txt";      ### Input Data file (for testing)     ###
my $outputFile  = "output.txt";    ### Output results file (for testing) ###
my $debug_on = 0;                  ### Enable testing of this parser     ###
my $trace_on = 0;                  ### Enable tracing the parser output  ###
my $grammar;                       ### SQGNL parser grammar             ###
my $parser_file;                   ### name of the file which contains parser object ###

############################################################################
# combine table names into parser accepted string
sub load_parser
############################################################################
{
    $parser_file = "sq_hal_${db_type}_${db_source}_${user}";

    ### replace invalid names in the file name ###
    $parser_file =~ s/[\\\/:*?<>|]//g;

    ### if parser file not found then load grammar ###
    if (!eval{require "${parser_file}.pm"})
    {
        print "Creating the parser...\n";

        ### Create the grammar ###
        $grammar = do "grammar.pl" or warn "Bad Grammar!";

        ### Replace table_names ###
        my $tables_str = table_names_to_parser_str();
        $grammar =~ s/TABLES/$tables_str/;

        ### Replace column names ###
        my $columns_str = column_names_to_parser_str();
        $grammar =~ s/FIELDS/$columns_str/;
    }
    else
    {
        print "Loading the parser from the file '${parser_file}.pm'...\n";
        do "grammar_func.pl";
    }

    ### initialize variables such as database structure, etc. ###
    initialize_vars();

    use Parse::RecDescent;

    ## Enable tracing of the parser ###
    if ($trace_on)  { $RD_TRACE = 1; }

    ### Load the parser from the file or               ###
    ### create the parser if the file is not available ###
    $parser = eval{require "${parser_file}.pm"}
        ? $parser_file->new()
        : Parse::RecDescent->new($grammar)
        or warn "Bad Parser!";

    ### if the parser file is not found, then the parser need to be saved ###
    if (!eval{require "${parser_file}.pm"})
    {
        $save_parser = 1;
    }

    ### if testing this parser only then do the following code ###
    if ($debug_on)
    {
        ### Open the input data file
        open(DATA, "< $dataFile")  || die $!;
        open(OUT, "> $outputFile")  || die $!;

        $| = 1;

        ### Parse each line of data ###
        while (<DATA>)
        {
            if (!/^#/ && !/^[\s]*\n/)    ### Ignore commented or empty lines ###
            {
                print "> ";
                #sleep 1;
                print;

                ### Translate the grammar ###
                my $SQL = $parser->translate("\L$_");

                ### Print the translated output to the screen and output file ###
                print "$_$SQL\n";
                print OUT "> $_$SQL\n";
            }
            else
            {
                print OUT "$_";
            }
        }

        ### Close files ##
        close(DATA);
        close(OUT);

        ### Exit to the system ###
        exit;
    }
}


############################################################################
# save the parser to a file
sub save_parser()
############################################################################
{
    print "Saving the parser to the file '${parser_file}.pm'...";

    ### if exist, then delete the parser file ###
    if (eval{require "${parser_file}.pm"})
    {
        eval { unlink "${parser_file}.pm"; };
    }

    ### save the parser to file ###
    eval { $parser->Save($parser_file); };

    ### do not need to save the parser in the neer future again ###
    $save_parser = 0;
}


############################################################################
# learn new rule by the parser
sub extend_parser
############################################################################
{
    my ($rule, $str) = ($_[0], $_[1]);  ### parser rule and the new learn string ###

    my $grammar = qq{ $rule : $str };   ### new grammar to be learn ###

    $parser->Extend($grammar);          ### extend the parser grammar ###

    #$save_parser = 1;   ### parser has been changed and therefore need to save ###

    ### print the newly learn grammar ###
    print "Learn grammar:\n$grammar\n";
}


############################################################################
# initialize table relationships and table-column relationships
sub initialize_vars
############################################################################
{
    @table_columns{get_table_names()} = ();

    foreach my $table (keys(%table_columns))
    {
        my %tmp;

        @tmp{get_column_names($table)} = ();
        foreach (keys(%tmp))
        {
            $tmp{$_} = "1";
        }

        $table_columns{$table} = { %tmp };
    }

    ### load the table relationships from the file ###
    if (open(DB, "${parser_file}.db"))
    {
        ### read each of the table relationship ###
        while (<DB>)
        {
            chomp($_);
            next unless s/^(.*?):\s*//;

            my $tbl1 = qq{$1};

            for my $field ( split /;/ )
            {
                my ($tbl2, $val) = split(",", $field);
                $table_relationships{ qq{$tbl1} }{ qq{$tbl2} } = qq{$val};
            }
        }

        close(DB);  ### close the file ###
    }
}


############################################################################
# combine table names into parser accepted string
sub save_db_info()
############################################################################
{
    open(DB, "> ${parser_file}.db");

    ### save each table relationship to a file
    foreach my $tbl1 (keys(%table_relationships))
    {
        print DB "$tbl1:";

        foreach (keys(%{$table_relationships{$tbl1}}))
        {
            print DB "$_,", $table_relationships{$tbl1}{$_},";" ;
        }
        print DB "\n";
    }

    close(DB);   ### close the file ###
}


############################################################################
# combine table names into parser accepted string
sub table_names_to_parser_str()
############################################################################
{
    print "Reading table names...\n";

    ### Get table names for the current database ###
    %table_columns = ();
    @table_columns{get_table_names()} = ();

    print "    Table names: ", join(", ", keys(%table_columns)), "\n\n";

    ### Create the parser recognised string ###
    my $tables_str = "";
    foreach my $table ( keys(%table_columns) )
    {
        ### table words need to be lower case ###
        my $table_words = "\L${table}?";
        $tables_str .= "/${table_words}/{'${table}'}|";
    }
    chop($tables_str);  ### Remove the last '|' character ###

    return $tables_str;
}


############################################################################
# combine all table columns into parser accepted string
sub column_names_to_parser_str()
############################################################################
{
    use Lingua::EN::Inflect ':ALL';

    ### read column names for each table ###
    my $columns_str = "";
    foreach ( keys(%table_columns) )
    {
        if ( $_ )
        {
            print "Read column names for '$_'...\n";

            my $current_table = $_;

            ### Get the column names for the given table ###
            my @columns = get_column_names($_);

            print "    Column names: ", join(", ", @columns), "\n\n";

            ### Create parser recognised string ###
            foreach my $column (@columns)
            {
                ### column words need to be lower case ###
                my $column_words =  "\L" . PL_N($column) . "|$column";
                $columns_str .= "/${column_words}/{'${column}'}|";
            }
         }
    }
    chop($columns_str);   ### Remove the last "|" character ###

    return $columns_str;
}

1;    ### so the 'do' command succeeds ###
