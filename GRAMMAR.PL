use strict;

my $grammar = q{

translate   :    learned | count | sum | average | select | { unknown_msg() }

select  :    (ask|question) qualifier(?) /(our)?/ table eol
                 { Select_T1_F0_C0($item[4]) }

        |    (ask|question) qualifier(?) field /of/ qualifier(?) table eol check[$item[3],$item[6]]
                 { Select_T1_F1_C0($item[3],$item[6]) }

        |    (ask|question) qualifier(?) /(our)?/ table /'?/ qualifier(?) field eol check[$item[7],$item[4]]
                 { Select_T1_F1_C0($item[7],$item[4]) }

        |    (ask|question) qualifier(?) field /and/ field /of/ qualifier(?) table eol check[$item[3],$item[8]] check[$item[5],$item[8]]
                 { Select_T1_F2_C0($item[3],$item[5],$item[8]) }

        |    (ask|question) qualifier(?) /(our)?/ table /'?/ qualifier(?) field /and/ field eol check[$item[7],$item[4]] check[$item[9],$item[4]]
                 { Select_T1_F2_C0($item[7],$item[9],$item[4]) }

        |    (ask|question) qualifier(?) /(our)?/table ignore_words condition eol
                 { Select_T1_F0_C1($item[4], $item[6]) }

        |    (ask|question) qualifier(?) field /of/ qualifier(?) table ignore_words condition eol check[$item[3],$item[6]]
                 { Select_T1_F1_C1($item[3],$item[6],$item[8]) }

        |    (ask|question) qualifier(?) /(our)?/ table /'?/ qualifier(?) field ignore_words condition eol check[$item[7],$item[4]]
                 { Select_T1_F1_C1($item[7],$item[4],$item[9]) }

        |    (ask|question) qualifier(?) field /and/ field /of/ qualifier(?) table ignore_words condition  eol check[$item[3],$item[8]] check[$item[5],$item[8]]
                 { Select_T1_F2_C1($item[3],$item[5],$item[8],$item[10]) }

        |    (ask|question) qualifier(?) /(our)?/ table /'?/ qualifier(?) field /and/ field ignore_words condition  eol check[$item[7],$item[4]] check[$item[9],$item[4]]
                 { Select_T1_F2_C1($item[7],$item[9],$item[4],$item[11]) }

        |    (ask|question) qualifier(?) /(our)?/ table /and/ table eol related[$item[4],$item[6]]
                 { Select_T2_F0_C0($item[4], $item[6]) }

        |    (ask|question) ignore_words table ignore_words table ignore_words eol related[$item[3],$item[5]]
                 { Select_T2_F0_C0($item[3], $item[5]) }

learned : {}


count   :    ask_count table /((is|are) there)|((do)? we have)/ eol
                 { Count_T1_F0_C0( $item[2] ) }

        |    ask qualifier(?) table /count/ eol
                 { Count_T1_F0_C0( $item[3] ) }

        |    ask_count table prep /(the)?/ field (prep)(?) value /((is|are) there)|((do )?we have)/ eol
                 { Count_T1_F0_C1( $item[2], "WHERE $item[5] = " . format_val($item[7])) }

        |    ask_count table ignore_words condition ignore_words eol
                 { Count_T1_F0_C1( $item[2], $item[4]) }


sum     :    (ask|whats) qualifier(?) total field ignore_words table ignore_words eol check[$item[4],$item[6]]
                 { Sum_T1_F1_C0( $item[4], $item[6] ) }

        |    (ask|whats) qualifier(?) total field ignore_words table ignore_words condition ignore_words eol check[$item[4],$item[6]]
                 { Sum_T1_F1_C1( $item[4], $item[6], $item[8] ) }


average :    (ask|whats) qualifier(?) /average/ field ignore_words table ignore_words eol check[$item[4],$item[6]]
                 { Average_T1_F1_C0($ item[4], $item[6] ) }

        |    (ask|whats) qualifier(?) /average/ field ignore_words table ignore_words condition ignore_words eol check[$item[4],$item[6]]
                 { Average_T1_F1_C1( $item[4], $item[6], $item[8] ) }

field   :    FIELDS     ### column names ###

table   :    TABLES     ### table names  ###


qualifier   :    /the|every|all( the)?|any|our/

ask         :    reply to_me

ask_count   :    ask(?) /how (many|much)/|/what number of|count the number of/

total       :    /total|sum of( all)( the)/

pre_val     :    /(by|of|for|to|from|with|is|are)*/

reply       :    /tell|show|list|display/

value       :    date|number|word

number      :    /(\$?)(-?)\d+(\.?)\d*/

word        :    /\w+|\"[\S\s]*\"/               { qq{ $item[1] } }

to_me       :    /((to )?(me|us))?/

question    :    whats|whos

whats       :    /what's|what're|what (is|are)?/

whos        :    /who's|who're|who (is|are)|who/

prep        :    /for|of|with|by/

table_verb  :    table|field

ignore_words :   junk(s?)

junk        :    ...!table_verb /\S+/

eol         :    /\s*/ /[.?]?/ /\s*/ /\z/

### date strings ###

date        :    /today|tomorrow|yesterday/              { parse_date($item[1]) }
            |    day                                     { parse_date($item[1]) }
            |    /(last|previous|next) /(date_period)    { parse_date($item[1].' '.$item[2]) }
            |    (date_format)

date_period :    /week|month/|month|day|/(financial )?year/

month       :    long_month|short_month

long_month  :    /january|february|march|april|may|june|july|august|september|october|november|december/

short_month :    /jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec/

day         :    long_day|short_day

long_day    :    /sunday|monday|tuesday|wednesday|thursday|friday|saturday/

short_day   :    /sun|mon|tue|wed|thu|fri|sat/

date_format :    DD date_sep (MM|month) date_sep (YYYY|YY)   { parse_date($item[3].'/'.$item[1].'/'.$item[5]) }
            |    (MM|month) date_sep DD date_sep (YYYY|YY)   { parse_date($item[1].'/'.$item[3].'/'.$item[5]) }
            |    month DD /,?/(YYYY|YY)                      { parse_date($item[1].'/'.$item[2].'/'.$item[4]) }
            |    (YYYY|YY) date_sep (MM|month) date_sep DD   { parse_date($item[3].'/'.$item[5].'/'.$item[1]) }
            |    DD date_sep (MM|month)                      { parse_date($item[3].'/'.$item[1]) }
            |    (MM|month) date_sep DD                      { parse_date($item[1].'/'.$item[3]) }
            |    month DD                                    { parse_date($item[1].'/'.$item[2]) }

date_sep    :    /-|\//

DD          :    /\d{1,2}/  #<reject:do{$item[1] > 31 || $item[1] < 1}>

MM          :    /\d{1,2}/  #<reject:do{$item[1] > 12 || $item[1] < 1}>

YYYY        :    /\d{4}/

YY          :    /\d{2}/

### Conditions ###
condition   :    greater_than|less_than|between|like|equal

equal       :    field pre_equal value
                     { "WHERE $item[1] = " . format_val($item[3]) }

pre_equal   :    /by|of|for|to|from|with|is|are|equal( to)/

greater_than:    field pre_greater value
                     { "WHERE $item[1] > " . format_val($item[3]) }

pre_greater :    /(is |are )?/ /more|greater|higher|expensive|taller|bigger/ /than/

less_than   :    field pre_less value
                     { "WHERE $item[1] < " . format_val($item[3]) }

pre_less    :    /(is |are )?/ /less|lower|cheaper|shorter|smaller/ /than/

between     :    field pre_between value /and/ value
                     { "WHERE $item[1] >= " . format_val($item[3]) . "\n\tAND $item[1] <= " . format_val($item[5]) }

pre_between :    /(is |are )?/ /between/

like        :    field /starts?/ /with/ value
                     { $item[4] =~ s/ //g;"WHERE $item[1] LIKE \"$item[4]%\"" }

            |    field /ends?|ended/ /in/ value
                     { $item[4] =~ s/ //g;"WHERE $item[1] LIKE \"%$item[4]\"" }

            |    field /contains?/ value
                     { $item[3] =~ s/ //g; "WHERE $item[1] LIKE \"%$item[3]%\"" }


### check if the given field ($arg[0]) is found in the given table ($arg[1]) ###
check       :    <reject: !check_field($arg[0], $arg[1]) >

### check if there is any relationship between two given tables ($arg[0] and $arg[1] ###
related     :    <reject: !check_relationship($arg[0], $arg[1]) >

};   ### end of pre-defined grammar ###

do "grammar_func.pl";   ### append various grammar functions to this grammar ###

$grammar;   ### return the grammar ###
