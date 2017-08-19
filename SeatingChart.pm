package SeatingChart;
# -
# # SC Puzzle
# # Tyler Normile
# # github.com/ityler
#
# This module is written without any dependencies or using any perl object frameworks.
# - 

# Initialize seating chart for venue
#  @PARAM: 
#  (INT) NUmber of total rows
#  (INT) NUmber of total columns
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
#  Data structure is constructed as:
#   {rows}     # Number of predefined rows
#   {cols}     # Number of predefined columns
#   {best}     # Front-center seat key (row,col) identifier
# -
sub new {
  my($class, $args) = @_;
  my $self = {
    rows => $args->{rows},                  # Number of rows    
    cols => $args->{cols},                  # Number of columns
    best => "1,".(int($args->{cols}/2)+1)   # Set 'best' seat key(row,col) 'front-center seat'
  };
  my $object = bless $self, $class;         # Create $object of type $class
  $object->_set_seats_data;                 # Build initial seating data and each seats score (finish implementation)
  return $object;
}

# - 
# Retrieve reserved/available status of seat position
# @PARAMS:
#   $sk   -> Seat key (row,col)
sub get_seat_status {
  my($self,$sk) = @_;
  return $self->{seats}{$sk}{STATUS};
}

# - 
# Retrieve score of seat position
# @PARAMS:
#   $sk   -> Seat key (row,col)
sub get_seat_score {
  my($self,$sk) = @_;
  return $self->{seats}{$sk}{SCORE};
}

# -
# Find best seat/block of seats available 
# (best => based on Manhattan Distance from front-center seat)
# @PARAMS:
#   $rsc -> Requested seats count
# Returns best available group of seats for requested count | false
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
#   @blockRange  -> Range of seat columns to try and build a sufficient 
#                   block of seats from using request count
#   %validBlocks -> Starting seat keys of each valid block (that satisfy 
#                   numer of requested seats and available)
#   $blockScore  -> Total block score for starting seat key thru 
#                   number of requested seats
# -
sub get_avail_seats {
  my($self,$rsc) = @_;
  my($scoredKeys) = $self->{sorted_seats};                              # Get current array of sorted available seat keys
  my($mxCls) = $self->{cols};                                           # Get instance column count (used as a maximum)
  foreach my $sk (@$scoredKeys){                                        # Iterate over available seats from best->notsogood score
    my($keyRow,$keyCol) = split(",",$sk);                               # Split out row/column key
    my($bkr) =  ($keyCol-($rsc-1)) > 0                                  # Beginning key range
              ? ($keyCol-($rsc-1)) : 1;                                 # Column can not be less than 1
    my($ekr) =  ($keyCol+($rsc-1)) < $mxCls 
              ? ($keyCol+($rsc-1)) : $mxCls;                            # Column can not be more than defined columns
    my(@blockRange) = ($bkr .. $ekr);                                   # Start range  .. End range of possible seat block
    my(%validBlocks);                                                   # Final valid blocks->scores to be sorted and choose best
    my($blockScore);                                                    # Total block score for each possible group of seats/seat
    for(my $i = 0; $i <= $#blockRange; $i++){                           # Each seat in block range from starting seat key
      $blockScore = 0;                                                  # Reset block score for new attempt
      # Don't check remainder of seats in potential block
      # if the last potential seat in the block isnt available
      if(defined($blockRange[$i+($rsc-1)])){                            # Check that last possible seat in block is not outside scope of array range
        my($tk) = $blockRange[$i];                                      # Starting column key of possible block of seats
        for(my $j = 0; $j <= $rsc-1; $j++){                             # Build possible block of seats using $tk
          my($tmpCol) = $tk+$j;                                         # Column for next seat in potential block
          if($self->get_seat_status($keyRow.",".$tmpCol) ne "X"){       # Seat is available
            $blockScore += $self->get_seat_score($keyRow.",".$tmpCol);  # Add seat score to block total
            if($j == ($rsc-1)){                                         # Last iteration (full block found)
              $validBlocks{$keyRow.",".$tk} = $blockScore;              # Set possible block total score
            }
          } else { last; }                                              # Break out of loop early on unavailable (save cycles)
        }
      } 
    }
    # Determine best block if any valid blocks 
    # of seats were found matching requested number
    if(%validBlocks){                                                   # A valid seat block/s were found 
      my(@scores) = sort { 
        $validBlocks{$a} <=> $validBlocks{$b} 
      } keys %validBlocks;                                              # Sort possible blocks by best value (lowest score)
      my($bk) = $scores[0];                                             # Get top rated starting seat key (build remaining seats from here)
      my($row,$col) = split(",",$bk);                                   # Split out row/column key
      my(@res);                                                         # Result array of seat keys
      for(my $c = 0; $c <= $rsc-1; $c++){                               # Each seat from selected block
        my $pk = $row.",".($col+$c);                                    # Build seat key
        push(@res,$pk);                                                 # Add block of seat keys to return array
      }
      return \@res;
    }
  }
  return 0;                                                             # Return false when request can not be fulfilled
}

# - 
# Change status of passed seat(key) to reserved/taken
# @PARAMS:
#   $sk -> Seat key (row,col)
sub set_seat_reserved {
  my($self,$sk) = @_;
  $self->{seats}{$sk}{STATUS} = "X";  # Set seat as reserved
}

# -
# Creates initial 'seats' structure 
#  -> Initializes each seat in venue as key (row,col)
#  -> Sets 'score' for each seat as key is initialized
#  -> Assigns $self->{seats} to data hash 
#     $self->{seats}{row,col} = ({
#        "STATUS" => Available/reserved
#        "SCORE"  => Manhattan distance value from $self->{best}
#     })
#  -> $self->{sorted_seats} - Stores an array of keys(row,col) sorted on 'SCORE' 
# -
sub _set_seats_data {
  my $self = shift;
  my(@r) = (1..$self->{rows});
  my(@c) = (1..$self->{cols});                                # Array of columns
  my($fc) = $self->{best};                                    # Get front-center seat key
  my(%data);                                                  # Seat hash
  foreach(@r){                                                # Each defined row
    my($row) = $_;
    foreach(@c){                                              # Each defined column
      my($col) = $_;
      $data{"$row,$col"} = ({                                 # Hash key for each seat in venue (row,col)
        "STATUS" => "O",                                      # Init status of 'open' chnage to " " later
        "SCORE"  => calcScore($fc,$row.",".$col)              # Set seats score in relation to front-center seat
      });
    }
  }
  $self->{seats} = \%data;                                    # Assign seat data ref to object->seats
  # Perform single sort of seat keys
  # and use for remainder of runtime
  my @scored = sort { $data{$a}{SCORE} <=> $data{$b}{SCORE}   # Compare numerical scores
                      or $a cmp $b                            # Secondary compare keys
                    }  keys %data;                            # Keys sorted on 'SCORE' from best->worst
  $self->{sorted_seats} = \@scored;                           # Sorted hash keys ref
}

# -
# Calculates score for seat
# -> Uses manhattan distance algorithm to determine value 
#    based on relation to front-center seat
# @PARAMS:
#   $fc -> Front Center seat #,#
#   $ss -> Selected seat for value #,#
# -
sub calcScore {
  my($fc,$ss) = @_;
  my($fcr,$fcc) = split(",",$fc);                     # Front-center (row,col)
  my($ssr,$ssc) = split(",",$ss);                     # Seat to score (row,col)
  my($result) = abs($fcr - $ssr) + abs($fcc - $ssc);  # Distance formula
  return $result;                                     # Return numeric seat score
}

# -
# Return total count of available seats
# -
sub remaining_seat_count {
  my($self) = shift;
  my($cnt) = 0;                               # Return count
  my($seatsRef) = $self->{seats};             # seats{} reference from object
  foreach my $key (keys %$seatsRef){          # Each defined seat in object instance
    if($self->get_seat_status($key) ne "X"){  # Seat is not reserved 
      $cnt++;                                 # Increment counter
    }
  }
  return $cnt;                                # Return remaining seat count
}

1;