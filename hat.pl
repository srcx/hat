#!/usr/bin/perl -w

# HAckovani Textu
# (c)2004,2005 Stepan Roh

# $Id: hat.pl,v 1.15 2005/03/12 20:49:11 stepan Exp $

$prog_name = 'HaT';
$cvs_version = '$Revision: 1.15 $';
$prog_cvs_version = ($cvs_version =~ /:\s*(\S*)\s*\$/)[0];
$prog_version = '0.3';

# Q: Why do we use Cz::Cstocs?
# A: Perl's Unicode support is not mature enough to use it and czech encodings are not yet
#    available. Using locale support is (sadly) less portable than Cz::Cstocs (not all
#    platforms have czech locale or encodings).

use Cz::Cstocs;

if (@ARGV < 2) {
  print <<END;
$prog_name $prog_version (rev. $prog_cvs_version) (c)2004,2005 Stepan Roh

usage:
  $0 -b words_database training_data_encoding < training_data
      creates or overwrites words database
  $0 -h words_database output_encoding < ascii_input > accented_output
      processes ascii input into accented output
END
  exit 0;
}

# must be the same as encoding of this script file
# determines also encoding of words database file
# must be one-byte per character encoding (no UTF-8 or UCS-2)
# and must be extended ASCII
$inner_enc = 'il2';

# dbfile (in iso-8859-2):
#   orig_word num
#   prev_ascii_word_1 num_1 ...
#   next_ascii_word_1 num_1 ...
# %words_db:
#   (ascii_word -> (orig_word -> (
#                    'num'  -> num,
#                    'prev' -> (prev_ascii_word -> num)),
#                    'next' -> (next_ascii_word -> num)),
#                  )))
# everything is (must be) lowercased
%words_db = ();

# constructs %words_db from words database file
# in: $words database file name
sub load_words_db ($) {
  my ($fname) = @_;

  print STDERR "Loading words database $fname...\n";
  
  my $to_ascii = new Cz::Cstocs ($inner_enc, 'ascii');
  open (F, $fname) || die "Unable to open $fname : $!\n";
  my $counter = 0;
  while (<F>) {
    my ($orig_word, $num) = split (/\s+/, $_);
    my $ascii_word = &$to_ascii ($orig_word);
    $words_db{$ascii_word}{$orig_word}{'num'} = $num;
    $_ = <F>;
    my @prev_words = split (/\s+/, $_);
    for (my $i = 0; $i < @prev_words; $i++) {
      my $prev_ascii_word = $prev_words[$i];
      $i++;
      my $prev_num = $prev_words[$i];
      $words_db{$ascii_word}{$orig_word}{'prev'}{$prev_ascii_word} = $prev_num;
    }
    $_ = <F>;
    my @next_words = split (/\s+/, $_);
    for (my $i = 0; $i < @next_words; $i++) {
      my $next_ascii_word = $next_words[$i];
      $i++;
      my $next_num = $next_words[$i];
      $words_db{$ascii_word}{$orig_word}{'next'}{$next_ascii_word} = $next_num;
    }
    $counter++;
    if ($counter % 1000 == 0) {
      print STDERR "...$counter words read\n";
    }
  }
  close (F);

  print STDERR "...success ($counter words read)\n";
}

# iso-8859-2 (see $inner_enc)
# special czech characters
$cz_chars = 'éìÉÌøØ»«¾®úÚùÙíÍóÓáÁ¹©ïÏýÝèÈòÒ';
# mapping (czech character in uppercase -> lowercase)
%cz_to_lower = (
  'É' => 'é',
  'Ì' => 'ì',
  'Ø' => 'ø',
  '«' => '»',
  '®' => '¾',
  'Ú' => 'ú',
  'Ù' => 'ù',
  'Í' => 'í',
  'Ó' => 'ó',
  'Á' => 'á',
  '©' => '¹',
  'Ï' => 'ï',
  'Ý' => 'ý',
  'È' => 'è',
  'Ò' => 'ò',
);
# mapping (czech character in lowercase -> uppercase)
%cz_to_upper = ();
foreach $c (keys %cz_to_lower) {
  $cz_to_upper{$cz_to_lower{$c}} = $c;
}

# FIX: following subs should be written more efficiently

# returns lowercased string (works with czech letters)
sub cz_lc ($) {
  my ($w) = @_;
  return undef if (!defined $w);
  my @w = map { $cz_to_lower{$_} || lc ($_); } split ('', $w);
  return join ('', @w);
}

# returns uppercased string (works with czech letters)
sub cz_uc ($) {
  my ($w) = @_;
  return undef if (!defined $w);
  my @w = map { $cz_to_upper{$_} || uc ($_); } split ('', $w);
  return join ('', @w);
}

# returns czech string with same letter cases as in pattern
# in: $pattern (ascii string), $text (must be the same length as pattern)
sub cz_recase ($$) {
  my ($pattern, $w) = @_;
  my @pattern = split ('', $pattern);
  my @w = split ('', $w);
  my @ret = ();
  for (my $i = 0; $i < @pattern; $i++) {
    my $pc = $pattern[$i];
    my $wc = $w[$i];
    if ($pc =~ /^[a-z]$/) {
      $wc = cz_lc ($wc);
    } else {
      $wc = cz_uc ($wc);
    }
    push (@ret, $wc);
  }
  return join ('', @ret);
}

# updates %words_db with statistics of text from stdin
# in: $input encoding
sub update_words_db_from_stdin ($) {
  my ($input_enc) = @_;
  
  print STDERR "Updating words database from standard input ($input_enc)...\n";
  
  my $counter = 0;
  
  my $to_inner = new Cz::Cstocs ($input_enc, $inner_enc);
  my $to_ascii = new Cz::Cstocs ($inner_enc, 'ascii');
  
  my $prev_orig = '';
  my $prev_ascii = '';
  while (<STDIN>) {
    $_ = &$to_inner ($_);
    # word consists of letters
    my @words = map { cz_lc ($_) } split (/[^a-zA-Z${cz_chars}]+/);
    foreach $orig_word (@words) {
      next if (!$orig_word);
      my $ascii_word = &$to_ascii ($orig_word);
      $words_db{$ascii_word}{$orig_word}{'num'}++;
      $words_db{$ascii_word}{$orig_word}{'prev'}{$prev_ascii}++ if ($prev_ascii);
      $words_db{$prev_ascii}{$prev_orig}{'next'}{$ascii_word}++ if ($prev_ascii);
      $prev_orig = $orig_word;
      $prev_ascii = $ascii_word;
    }
    $counter++;
    if ($counter % 1000 == 0) {
      print STDERR "...$counter lines read\n";
    }
  }

  print STDERR "...success ($counter lines read)\n";
}

# save %words_db into the given file
# input: $output file name
sub save_words_db ($) {
  my ($fname) = @_;
  
  print STDERR "Saving words database $fname...\n";

  open (F, '>'.$fname) || die "Unable to open $fname : $!\n";
  
  my $counter = 0;
  my $reduced_cnt = 0;
  
  # words database size reducing hacks
  # - we omit words which have only one variant and this variant is the same as original word
  # - we omit prev and next words if we have only one variant

  L: foreach $ascii_word (sort keys %words_db) {
    my $one_variant = (keys %{$words_db{$ascii_word}} == 1);
    foreach $orig_word (sort keys %{$words_db{$ascii_word}}) {
      if (($ascii_word eq $orig_word) && $one_variant) {
        $reduced_cnt++;
        next L;
      }
      my $num = $words_db{$ascii_word}{$orig_word}{'num'};
      print F "$orig_word $num\n";
      if (!$one_variant) {
        my %prev = %{$words_db{$ascii_word}{$orig_word}{'prev'}};
        foreach $prev_ascii (sort keys %prev) {
          print F $prev_ascii, ' ', $prev{$prev_ascii}, ' ';
        }
      }
      print F "\n";
      if (!$one_variant) {
        my %next = %{$words_db{$ascii_word}{$orig_word}{'next'}};
        foreach $next_ascii (sort keys %next) {
          print F $next_ascii, ' ', $next{$next_ascii}, ' ';
        }
      }
      print F "\n";
      $counter++;
      if ($counter % 1000 == 0) {
        print STDERR "...$counter words written\n";
      }
    }
  }

  print STDERR "...success ($reduced_cnt words reduced, $counter words written)\n";
}

# process (hackovani) standard input and write it to standard output (in given encoding)
# input: $output encoding
sub process_stdin ($) {
  my ($output_enc) = @_;

  print STDERR "Processing standard input ($output_enc)...\n";
  
  my $counter = 0;
  
  my $to_inner = new Cz::Cstocs ($output_enc, $inner_enc);
  my $to_ascii = new Cz::Cstocs ($inner_enc, 'ascii');
  my $to_input = new Cz::Cstocs ($inner_enc, $output_enc);

  my $prev = '';
  # input text is divided into "real" words and the rest
  my @text = map { split (/([a-zA-Z]+)/, &$to_inner ($_)) } <STDIN>;
  for (my $i = 0; $i < @text; $i++) {
    my $w = $text[$i];
    # first char is sufficient for detection of real word
    if ($w =~ /^[a-zA-Z]/) {
      my $ascii_word = lc ($w);
      if (exists $words_db{$ascii_word}) {
        my $orig_word;
        # only one variant - use it
        if (keys %{$words_db{$ascii_word}} == 1) {
          $orig_word = (keys %{$words_db{$ascii_word}})[0];
        } else {
          my $next;
          # find next "real" word
          for (my $j = $i + 1; $j < @text; $j++) {
            $next = $text[$j];
            last if ($next =~ /^[a-zA-Z]/);
          }
          $next = lc ($next);
          my $orig_num = 0;
          my $in_context = 0;
          # search between variants
          foreach $cur_orig (keys %{$words_db{$ascii_word}}) {
            # we have a proper context (previous word)
            if ($prev && exists $words_db{$ascii_word}{$cur_orig}{'prev'}{$prev}) {
              if (!$in_context || ($words_db{$ascii_word}{$cur_orig}{'prev'}{$prev} > $orig_num)) {
                $in_context = 1;
                $orig_word = $cur_orig;
                $orig_num = $words_db{$ascii_word}{$cur_orig}{'prev'}{$prev};
              }
            }
            # we have a proper context (next word)
            if ($next && exists $words_db{$ascii_word}{$cur_orig}{'next'}{$next}) {
              if (!$in_context || ($words_db{$ascii_word}{$cur_orig}{'next'}{$next} > $orig_num)) {
                $in_context = 1;
                $orig_word = $cur_orig;
                $orig_num = $words_db{$ascii_word}{$cur_orig}{'next'}{$next};
              }
            }
            # use variant with higher frequency
            if (!$in_context && ($words_db{$ascii_word}{$cur_orig}{'num'} > $orig_num)) {
              $orig_word = $cur_orig;
              $orig_num = $words_db{$ascii_word}{$cur_orig}{'num'};
            }
          }
        }
        $w = cz_recase ($w, $orig_word);
      }
      $prev = $ascii_word;
      $counter++;
      if ($counter % 1000 == 0) {
        print STDERR "...$counter words read\n";
      }
    }
    print &$to_input ($w);
  }

  print STDERR "...success ($counter words read)\n";
}

$cmd = shift @ARGV;
$dbfile = shift @ARGV;
$input_enc = shift @ARGV;

if ($cmd eq '-b') {
  update_words_db_from_stdin ($input_enc);
  save_words_db ($dbfile);
} else {
  load_words_db ($dbfile);
  process_stdin ($input_enc);
}

1;
