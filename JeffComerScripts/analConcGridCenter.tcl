# Author: jcomer2@illinois.edu

if {$argc < 8} {
    puts "$argv0 name moiety structPrefix outputDir dcdFreq stride startFrame gridFile dcdFile0 \[dcdFile1...\]"
    exit
}
set name [lindex $argv 0]
set moiety [lindex $argv 1]
set structPrefix [lindex $argv 2]
set outputDir [lindex $argv 3]
set dcdFreq [lindex $argv 4]
set stride [lindex $argv 5]
set startFrame [lindex $argv 6]
set gridFile [lindex $argv 7]
set dcdList [lrange $argv 8 end]

source $env(HOME)/scripts/vector.tcl
source $env(HOME)/scripts/gridForce.tcl

proc gridIncr {gridVar pos} {
    upvar $gridVar grid

    set ind [worldToIndex grid [wrap grid $pos]]
    set val [lindex $grid(data) $ind]
    lset grid(data) $ind [expr {$val + 1.0}]
}

proc compute {name moiety structPrefix outputDir dcdFreq stride startFrame gridFile dcdList} {
    set centerText "nucleic"
    set displayPeriod 1000
    set timestep 1.0
    set selText "name $moiety"
    if {$stride <= 0} {set stride 1}
    if {$startFrame < 1} {set startFrame 1}
    set bootNum 3

    # Read the grid.
    # Make the main bin.
    readDx main $gridFile
    zeroGrid main
    set bins $main(size)

    # Make the boot bins.
    for {set i 0} {$i < $bootNum} {incr i} {
	copyGridDim main boot${i}
	set bootSteps($i) 0
    }

    # Input:
    set pdb $structPrefix.pdb
    
    # Get the time change between frames in nanoseconds.
    set dt [expr {1.0e-6*$timestep*$dcdFreq*$stride}]

    # Load the system.
    mol load pdb $pdb
    set sel [atomselect top "$selText"]
    set centerSel [atomselect top "$centerText"]

    # Loop over the dcd files.
    set steps 0
    foreach dcd $dcdList {
	# Load the trajectory.
	animate delete all
	mol addfile $dcd type dcd step $stride waitfor all
	set nFrames [molinfo top get numframes]
	puts [format "Reading %i frames." $nFrames]

	# Move forward computing at every step.
	for {set f $startFrame} {$f < $nFrames} {incr f} {
	    molinfo top set frame $f
	    set center [measure center $centerSel weight mass]

	    # The index of the boot for this frame.
	    set bootInd [expr {int(floor(rand()*$bootNum))}]

	    # Get the positions at this step.
	    set posList [$sel get {x y z}]

	    # Add the data from each ion.
	    foreach pos $posList {
		# Shift by the center.
		set r [vecsub $pos $center]

		# Add the data to the main bin set.
		gridIncr main $r
	
		# Add the data to the randomly chosen boot bin set.
		gridIncr boot${bootInd} $r
	    }
	    
	    # Write the status.
	    if {$f % $displayPeriod == 0} {
		puts -nonewline [format "FRAME %i: " $f]
		puts "$steps"
	    }

	    # Count the valid frames in each bin set.
	    incr steps
	    incr bootSteps($bootInd)
	}; # End frame loop.

	
	# Count the valid frames in each bin set.
	incr steps
	incr bootSteps($bootInd)
    }

    if {$steps <= 1} {
	puts "NO DATA!"
	return
    }

    # Get the mean number and concentration.
    computeConc main mainNum mainConc $steps
    for {set b 0} {$b < $bootNum} {incr b} {
	computeConc boot${b} boot${b}Num boot${b}Conc $bootSteps($b)
    }
    
    # Use the greatest deviation in the boot results to get the error.
    copyGridDim main errNum
    copyGridDim main errConc
    for {set b 0} {$b < $bootNum} {incr b} {
	greatestDeviation errNum mainNum boot${b}Num
	greatestDeviation errConc mainConc boot${b}Conc
    }

    # Write the results.
    writeDx mainNum $outputDir/num_${moiety}_${name}.dx
    writeDx mainConc $outputDir/conc_${moiety}_${name}.dx
    writeDx errNum $outputDir/errNum_${moiety}_${name}.dx
    writeDx errConc $outputDir/errConc_${moiety}_${name}.dx

    $sel delete
    $centerSel delete
    mol delete top
    return
}

proc greatestDeviation {errGridVar meanGridVar bootGridVar} {
    upvar $errGridVar errGrid
    upvar $meanGridVar meanGrid
    upvar $bootGridVar bootGrid

    set j 0
    # Insert the error into the error grid if it is larger than 
    # the value already stored there.
    foreach e $errGrid(data) m $meanGrid(data) b $bootGrid(data) {
	set d [expr {abs($m-$b)}]
	if {$d > $e} {
	    lset errGrid(data) $j $d
	}

	incr j
    }
    return
}

proc computeConc {inGridVar numGridVar concGridVar steps} {
    upvar $inGridVar inGrid
    upvar $numGridVar numGrid
    upvar $concGridVar concGrid

    # Important constants.
    set concConvert 1660.5387; # particles/AA^3 -> mol/l
    set vol [getVolume inGrid]

    copyGridDim inGrid numGrid
    copyGridDim inGrid concGrid

    set num {}
    set conc {}
    foreach v $inGrid(data) {
	set n [expr {$v/$steps}]
	set c [expr {$concConvert*$n/$vol}]
	lappend num $n
	lappend conc $c
    }
    set numGrid(data) $num
    set concGrid(data) $conc

    return
}

compute $name $moiety $structPrefix $outputDir $dcdFreq $stride $startFrame $gridFile $dcdList
exit
