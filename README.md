[![Stories in Ready](https://badge.waffle.io/amitkumarj441/SQGNL.png?label=ready&title=Ready)](https://waffle.io/amitkumarj441/SQGNL?utm_source=badge)
# SQGNL

SQGNL stands for SQL Query generator for Natural Language

SQGNL has been written in Perl and in order to run this application we need to have perl installed in the system including relevant Perl modules needed to run this application 

## Perl Modules

- Parser::RecDescent
- DBI
- Tk
- Data::Manip
- Lingua::En::Inflect

## Perl Installation

For OS X and Linux users, building from source is simple enough once you have the necessary build tools installed. Apple offers a free download of their 'xtools', which includes a compiler and full set of tools (this may also be on a second disk which came with your computer.) Debian and Ubuntu have a package called 'build-essential' for this. In any case, your computer needs 'gcc', 'make', and various other components to be able to build perl from source.

Download the perl source code from http://www.cpan.org/src/perl-5.10.1.tar.gz, save it in your home directory (which should be your current working directory), then unpack and build it with the shell commands below. 
      
    tar -xzf perl-5.10.1.tar.gz
    cd perl-5.10.1
    ./Configure -des -Dprefix=/usr/local
    make
    make test
    sudo make install
    
Now you have installed perl as /usr/local/bin/perl, which should become the first perl in your $PATH. Make sure you get the desired answer from perl --version.

You may not have the necessary permissions to install into /usr/local. In such a case, configure with the appropriate prefix and set $PATH accordingly (e.g. PATH=$HOME/perl/:$PATH) or use an absolute filename to call perl. The following would install your new perl under ~/perl/ and the perl executable would be ~/perl/bin/perl. 

    tar -xzf perl-5.10.1.tar.gz
    cd perl-5.10.1
    ./Configure -des -Dprefix=$HOME/perl
    make
    make test
    make install
    
## [Research Paper](http://www.academia.edu/32188868/SQL_Query_Generator_For_Natural_Language) 

Find **Presentation** [here](https://github.com/amitkumarj441/SQGNL/blob/master/Presentation/SQGNL.pptx).

[GPLv3 LICENSE](https://github.com/amitkumarj441/SQGNL/blob/master/LICENSE)
