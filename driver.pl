#!/usr/local/bin/perl
use strict;
use warnings;
use SeatingChart;
# -
# # SC Puzzle
# # Tyler Normile
# # github.com/ityler
# -

##### Seating Chart #####
# - Seating Chart should be initialized with (# of rows, # of cols) to simulate a venues seating.
# - Given request for a number of seats, the seating chart will return the best seats in oder to satisfy the number of seats requested.
# - If no seats are available to satisfy the number provided, driver will indicate the result as 'Not Available'
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##### Observations #####
# The example uses an odd number of columns (11) which makes the middle fron-center an obvious seat: (row,col) (1,6). 
#   In the event of an even number of columns (e.g. 10), the front-center seat will be (row,col) (1,5). Technically
#   from a 'front-center' perspective, the seats (1,5) and (1,6) could both be a front-center seat. Using my choice of 
#   numerically labeling the score of each seat, this would give (1,5) and (1,6) both a score of 0 indicating the best seat.
#   I made the choice not to venture down the path of having two seats as front-center as the example didn't sepcifically 
#   mention it as an obstacle to overcome. 
# Originally I used a different approach for finding the seats more 'efficiently' than is being done in my final submission. I
#   noticed that if the highest scored available seat was 'left' of front-center I could cut the amount of iterations in a loop 
#   by 50% by only needing to look at the smaller range of seats to build a block from the left. Similarly this logic also 
#   applied to the right side of front-center. If the highest scored available seat was found in the same column as 
#   front-center (from example, column 6), then a larger range would need to be iterated over for the best block to be found
#   (this can be seen on the 3rd request for 3 seats from the example). I ultimately chose to not go this route as I believed 
#   the optimization benefits didn't outweigh the 'maintainable' part of the solution (needing to have 3 different methods 
#   for finding the best block).

# - 
# Create instance of SeatingChart 
#  Set venue attributes:
#   Number of rows
#   Number of cols
# -
my $sc = SeatingChart->new({                    # Create instance of SeatingChart
  rows => 3,                                    # Initialize number of rows
  cols => 11                                    # Initialize number of columns
});

my($sorted) = $sc->{sorted_seats};              # (Slight optimization) Sorted seat keys(row,col) on score from good->notsogood

# Program reads data from STDIN (expects CRLF delimited)
my($reqFlg) = 0;                                # Request data flag (reservation/request line)
while(<>){                                      # Read in input data until EOF
  chomp($_);                                    # Strip crlf from line
  if(!$reqFlg){                                 # 1st line of file (potentially reserved seats)
    procRsvdLine($_);                           # Process reserved seats (handles if null line => no pre reservations)
    $reqFlg = 1;                                # Set request data flag (stop expecting possile reservations line)
  } else {                                      # Seat/block requests
    if($_ <= 10 && $_ > 0){                     # Maximum & Minimum seat block requested per instructions
      my($stsFnd) = $sc->get_avail_seats($_);   # Find requested size block of seats
      if($stsFnd){                              # Available seat/s were found
        my($resOut) = fmtOutput($stsFnd);       # Create output string of seat request response
        foreach(@$stsFnd){                      # Each seat returned from request
          my($sk) = $_;                         # Seat key
          $sc->set_seat_reserved($sk);          # Reserve seat
          @$sorted = grep { !/$sk/ } @$sorted;  # Remove seat from sorted list of seat keys
        }
        print "${resOut}\n";                    # Output reservation seat/range of seats
      } else {                                  # Unable to satisfy request for seats
        print "Not Available\n";
      }
    } else { print "Warn: Requested seats ${_} is out of allowable range\n"; }
  }
}

print $sc->remaining_seat_count();              # Output remaining seat count


# -
# Process reserved seat line (can be empty)
#  @PARAM:
#    $rsvd    -> Reserved input string (space separated R#C#)
# - 
sub procRsvdLine {
  my(@rsvd) = split(' ',shift);               # Split seats on space separator
  foreach(@rsvd){                             # Each seat in reserved line (R#C#)
    $_ =~ /R(\d+)C(\d+)/;                     # Capture group to split row and col integers
    my($row,$col) = ($1,$2);                  # First,Second capture group
    $sc->set_seat_reserved("$row,$col");      # Reserve seat in seating chart (row,col)
    my($sorted) = $sc->{sorted_seats};        # Get sorted list of available seats
    @$sorted = grep {!/$row,$col/} @$sorted;  # Remove seat from sorted list of seat keys
  }
}

# -
# Format result output
# @PARAM:
#   $res     -> Reference to array of seat keys
# -
sub fmtOutput {
  my($res) = shift;                       # Reference of seats
  my($sr,$sc) = split(",",@$res[0]);      # Staring range seat (first element of array)
  my($er,$ec) = split(",",@$res[-1]);     # Ending range seat (last element of array)
  my($out) = "";                          # Output string init
  if(@$res[0] ne @$res[-1]){              # Range of seats (first and last are different)
    $out = "R${sr}C${sc} - R${er}C${ec}"; # Output string
  } else {                                # Single seat (first and last are the same)
    $out = "R${sr}C${sc}";                # Output string
  }
  return $out;                            # Return output string
}