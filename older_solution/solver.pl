#!/usr/local/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Benchmark qw(:all) ;        # :hireswallclock -> for hi-res timing (microseconds)

my($t0) = Benchmark->new;
my %hash;
my @bits = ();

my($rows,$cols,$rsvdLine);
$rows = 3;
$cols = 11;
$rsvdLine = "R1C4 R1C6 R2C3 R2C7 R3C9 R3C10";     # First line of file (optional)

initSeatingChart(3,11);       # Create and build data strcuture
my(@scored) = rankSeats();    # Get sorted array of best->worst 'SCORE'

my($reqFlg) = 0;              # Request data flag
while(<>){                    # Each line of input until EOF
  chomp($_);                  # Strip crlf
  if(!$reqFlg){               # 1st line of file (potentially reserved seats)
    setReserved($_);          # Process reserved seats
    $reqFlg = 1;              # Set request data flags
  } else {
    findSeats($_);            # Process # Seat request
  }
}
print "\nRemaining Available Seats: ".getRemSeats()."\n\n";

my($t1) = Benchmark->new;
my($td) = timediff($t1, $t0);
print "the code took:",timestr($td),"\n";

# -
# Check all possible combinations of requested block using key
# -
sub chkCombos {
  my($key,$cnt) = @_;                                       # Key in common, number of requested seats
  my($keyRow,$keyCol) = split(",",$key);                    # Split out row/column key
  my(%combos) = ();                                         # store key combos and total score
  my($bkr) =  ($keyCol-($cnt-1)) > 0 
                ? ($keyCol-($cnt-1)) : "0";                 # Column can not be less than 0
  my($ekr) =  ($keyCol+($cnt-1)) < 11 
                ? ($keyCol+($cnt-1)) : "11";                # Column can not be more than highest column
  my(@dataArr) = ($bkr .. $ekr);                            # Start range  .. End range of possible seat block
  my(%seatOptions) = ();
  my($blockScore);
  for(my $i = 0; $i <= $#dataArr; $i++){
    $blockScore = 0;                                        # Total block score
    if(defined($dataArr[$i+($cnt-1)])){                     # Last possible element in block is not outside scope of array range
      my($sk) = $dataArr[$i];                               # Starting column key of possible block of seats
      for(my $j = 0; $j <= $cnt-1; $j++){
        my($tmpCol) = $sk+$j;
        print "TMPCOL: ".$tmpCol."\n";
        if(defined($hash{$keyRow.",".$tmpCol})){            # Seat exists
          print "seat exists: ".$keyRow.",".$tmpCol."\n";
          if($hash{$keyRow.",".$tmpCol}{STATUS} ne "X"){      # Seat is available
            $blockScore += $hash{$keyRow.",".$tmpCol}{SCORE}; # Add total score to block total
            if($j == ($cnt-1)){                               # Last iteration (full block found)
              $seatOptions{$keyRow.",".$sk} = $blockScore;    # Set possible block total score
            }
          } else { last; }
        } else { last; }
      }
    }
  }
  print "SEAT OPTIONS\n";
  print Dumper(\%seatOptions);
  print "\n\n";
  my($bk) = 0;
  my(@res);
  if(%seatOptions){
    print "seatOptions true\n";
    my(@scores) = sort { $seatOptions{$a} <=> $seatOptions{$b} } keys %seatOptions; # Sort possible blocks by lowest value
    print "SCORES:\n";
    foreach(@scores){
      print $_."\n";
    }
    print "\n\n";
    if(@scores){
      $bk = $scores[0];  
      print "BK: $bk\n";
      # Create block of keys
      my($row,$col) = split(",",$bk);              # Split out row/column key
      for(my $c = 0; $c <= $cnt-1; $c++){          # Find requested number of seats in a row
        my $pk = $row.",".($col+$c);
        print "Found seat: ".$pk."\n";
        push(@res,$pk);
      }
    }
    return \@res;     # Starting hash key
  } else {
    return 0;
  }
  
}

# -
# @PARAM:
#  Row, col, # of requested seats
# -
sub lookDir {
  my($row,$col,$cnt) = @_;
  my($cc) = int(($cols/2)+1);                  # Center column
  my(@res);                                    # Resulting seat keys
  my($pk) = $row.",".$col;
  my($sk) = chkCombos($pk,$cnt);
  if($sk){
    @res = @$sk;                              # De-referenced result list
  } else {
    print "Unavailble seat: $pk\n";
    return 0;
  }
  return \@res;                                 # Return reference to resul seat key list
}

# - 
#
# -
sub findSeats {
  my($sc) = shift;                            # count asking for
  my($chosen);                                # Result list scalar
  print "-- Requested Seats: $sc --\n";
  # Start searching at best available seat
  foreach my $k (@scored){                    # Each available seat by best 'SCORE'
    print "Trying ".$k." --> SCORE: ".$hash{$k}{SCORE}."\n";
    my($row,$col) = split(",",$k);            # Split key into row and column parts
    $chosen = lookDir($row,$col,$sc);         # Try to find available seats for current key
    if($chosen){                              # Found number of requested seats available
      print "Done: Found match for $sc\n";
      foreach(@$chosen){                      # De-referenced result list
        my($key) = $_;
        $hash{$key}{'STATUS'} = "X";          # Mark seat as reserved
        @scored = grep {!/$key/} @scored;     # Remove newly taken seat from sorted score array
        print $key."\n";
      }
      print "---------------------\n\n"; 
      last; 
    }
  }
  if(!$chosen){                               # No available seats found
    print "Not Available\n";
    print "---------------------\n\n"; 
  }
}

# -
# @PARAM:
#  Row, col, # of requested seats
# -
sub lookDir_old {
  my($row,$col,$cnt) = @_;
  my($cc) = int(($cols/2)+1);                  # Center column
  my(@res);                                    # Resulting seat keys
  if($col == $cc){                             # Key column is the center column
    # Side step issue with assigning block that is not best
    # if key seat isnt a start/end seat, this is possible
    # - Switch between lookleft and lookright - track current iteration each time, compare values 
    print "LookingBothWays($row,$col)\n";
    my($pk) = $row.",".$col;
    my($sk) = chkCombos($pk,$cnt);
    if($sk){
      @res = @$sk;                              # De-referenced result list
    } else {
      print "Unavailble seat: $pk\n";
      return 0;
    }
  } elsif($col > $cc){                              # Seat is right of center
    # - Looking right direction - #
    print "LookingRight($row,$col)\n";
    for(my $c = 0; $c <= $cnt-1; $c++){        # Find requested number of seats in a row
      if(($col+$c) < $cols){
        my $pk = $row.",".($col+$c);
        if($hash{$pk}{'STATUS'} eq "X"){
          print "Unavailble seat: $pk\n";
          return 0;
        } else {
          print "Available seat: $pk\n";
          push(@res,$pk);  
        }
      } else {
        print "End of row encountered: Not enough space for $cnt seats\n";
        return 0;
      }
    }
  } else {                                     # Seat is left of center
    # Looking left direction
    print "LookingLeft($row,$col)\n";
    for(my $c = 0; $c <= $cnt-1; $c++){        # Find requested number of seats in a row
      if(($col-$c) > 0){
        my $pk = $row.",".($col-$c);
        if($hash{$pk}{'STATUS'} eq "X"){
          print "Unavailble seat encountered: $pk\n";
          return 0;
        } else {
          print "Available seat: $pk\n";
          push(@res,$pk);  
        }
      } else {
        print "End of row encountered: Not enough space for $cnt seats\n";
        return 0;
      }
    }
  }
  return \@res;                                 # Return reference to resul seat key list
}

# -
# Count number of remaining available seats
# -
sub getRemSeats {
  return scalar @scored;
}

# -
# Initialize seating chart
# @PARAM: 
#   Row count
#   Column count
# -
sub initSeatingChart {
  my($rows,$cols) = @_;
  my(@r) = (1...$rows);
  my(@c) = (1...$cols);
  my($fc) = "1,".int(($cols/2)+1);                  # Create front-center seat pair
  print "\nFront Center: ".$fc."\n\n";
  foreach(@r){                                      # Each defined row
    my($row) = $_;
    foreach(@c){                                    # Each defined column
      my($col) = $_;
      $hash{$row.",".$col} = ({                     # Hash element for each seat in venue
        "STATUS" => "O",                            # Init status of 'open' chnage to " " later
        "SCORE"  => getSeatValue($fc,$row.",".$col)
      });
    }
  }
}

# -
# Takes a string (space separated R#C#)
# - 
sub setReserved {
  my(@reserved) = split(' ',shift);         # Split seats on space separator
  foreach(@reserved){                       # Each reserved seat (R#C#)
    $_ =~ /R(\d+)C(\d+)/;                   # Capture group to split row and col integers
    my($row,$col) = ($1,$2);                # First,Second capture
    $hash{$row.",".$col}
         {"STATUS"} = "X";                  # Indicate reserved
    @scored = grep {!/$row,$col/} @scored;  # Remove reserved seat key from sorted array 
  }
}

# -
# Return array of keys sorted from best->worst
# -
sub rankSeats {
  my @scored = sort { $hash{$a}{SCORE} <=> $hash{$b}{SCORE} or $a cmp $b}  keys %hash; # keys sorted on 'SCORE' from best->worst
  return @scored;
}

# -
# Returns Manhattan Distance for seat pairing 
# in relation to front center seat
# @PARAMS:
#   $fc -> Front Center seat #,#
#   $ss -> Selected seat for value #,#
# -
sub getSeatValue {
  my($fc,$ss) = @_;
  my($fcx,$fcy) = split(",",$fc);
  my($ssx,$ssy) = split(",",$ss);
  my($result) = abs($fcx - $ssx) + abs($fcy - $ssy);
  return $result;
}