# INSTALLATION

Windows users should install [Strawberry Perl](http://strawberryperl.com/). 

Unix, Linux, macOS and similar operating systems should have perl installed.
Should you wish to avoid using the system perl [perlbrew](https://perlbrew.pl)
makes it easy to install and manage perl.

For more information about perl and installing perl visit
https://www.perl.org/get.html.

## Install Perl Modules

Download and unpack SQGNL and install prerequsites using
[cpanm](https://metacpan.org/pod/cpanm) by running the following  
`cpanm --installdeps .`

If using your system perl use your OS package manager to install modules.

Manual installation:

- Tk Module : `cpanm Tk`
- DBI : `cpanm DBI`
- DBD : `cpanm DBD::mysql`
- Parse::RecDescent : `cpanm Parse::RecDescent`
- Lingua::EN::Inflect : `cpanm Lingua::EN::Inflect`
