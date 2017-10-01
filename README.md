# HaT

**Warning: unmaintained since 2005!**

**HaT** is a script intended for adding diacritic marks to (Czech) text. It is based on statistical methods. Statistics are gathered from training data, stored in a database, and then used. The error rate if test database is used is around 5%.

## Running

Requirements:

* Perl 5.x or higher (tested with v5.8.2)
* [Cz::Cstocs](http://search.cpan.org/~janpaz/Cstools-3.42/Cz/Cstocs.pm) (tested with version 3.4)

Generation (training) of database:

  `./hat.pl -b hat.db il2 < train.txt`

  - creates database hat.db from training data train.txt, which are in
    encoding iso-8859-2 (encoding names are according to Cz::Cstocs)

Adding diacritic marks:

  `./hat.pl -h hat.db il2 < ascii.txt > czech.txt`

  - using database hat.db adds diacritic marks to ascii.txt and saves it as
    czech.txt in encoding iso-8859-2

## Test database

Test database was generated from these sources:

* CZLUG's statutes (http://www.linux.cz/czlug/stanovy.html)
* GNU LGPL (CZ) (http://www.gnu.cz/article.php?id_art=34)
* Linux Documentation Project (CZ, 2nd ed.) (http://www.cpress.cz/knihy/ldp2/)
* Selected laws of Czech Republic (http://portal.gov.cz)
* Texts from various Czech periodicals and newspapers
* Few Czech and translated to Czech books

Exact form of used texts can not be reconstructed from test database (it
does not contain all the information from original source) so I consider
this to be fair use.
