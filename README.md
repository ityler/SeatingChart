# SeatingChart.pm
+ Seating Chart should be initialized with (# of rows, # of cols) to simulate a venues seating.
+ Given request for a number of seats, the seating chart will return the best seats in oder to satisfy the number of seats requested.
+ If no seats are available to satisfy the number provided, driver will indicate the result as 'Not Available' (false is returned)

## Usage
#### Create instance of SeatingChart
```perl
my $sc = SeatingChart->new({    
  rows => 3,                    # Define number of rows
  cols => 11                    # Define number of columns
});
```

#### Get request for available seats
```perl
my($result) = $sc->get_avail_seats(4);        # Requesting a block of 4 seats
if($result){                                  # Requested block was found
  foreach(@$result){ print "seat: $_\n"; }    # Print out each seat in returned block
}
```
Returns best rated available block of seats (array reference)

#### Get remaining number of available seats
```perl
print $sc->remaining_seat_count();
```
Returns the numeric representation of available seats

#### Set seat as reserved
```perl
my($seat) = "1,6";               # Seat key (row,col)
$sc->set_seat_reserved($seat);   # Reserve seat call
```
Sets seat(row,col) a status of reserved ('X')

### Data Structure
```perl
# Seating Chart = ({
#   {rows}                # Number of predefined rows
#   {cols}                # Number of predefined columns
#   {best}                # Front-center seat key (row,col) identifier
#   {seats} = ({          # Seats hash
#     {$row,$col} = ({    # Unique seat key
#       "STATUS",         # Reserved/Available ('O'|'X')
#       "SCORE"           # Manhattan distance score from 'best'
#     })
#   })
# })
```

## Requirements
+ Perl v.5+
+ No external package dependencies used.
