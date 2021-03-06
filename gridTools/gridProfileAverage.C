// Author: Jeff Comer <jcomer2@illinois.edu>
#include <cmath>
#include <cstdlib>
#include <cstdio>

#include "useful.H"
#include "Grid.H"

using namespace std;

///////////////////////////////////////////////////////////////////////
// Driver
int main(int argc, char* argv[]) {
  if (!(argc == 5 || argc == 4)) {
    printf("Extract a profile of the grid along a given axis.\n");
    printf("Usage: %s srcGrid direction(x|y|z) [maskGrid] outFile\n", argv[0]);
    return 0;
  }

  const char* inFile = argv[1];
  const char dir = argv[2][0];
  const char* maskFile = argv[3];
  const char* outFile = argv[argc-1];

  int direct = -1;
  if (dir == 'X' || dir == 'x') direct = 0;
  if (dir == 'Y' || dir == 'y') direct = 1;
  if (dir == 'Z' || dir == 'z') direct = 2;
  
  if (direct < 0) {
    printf("Error: Direction must be x, y, or z!\n");
    return 0;
  }

  // Load the first grid.
  Grid src(inFile);
  printf("Loaded `%s'.\n", inFile); 

  // Load or make a mask grid.
  Grid* mask;
  if (argc == 5) {
    mask = new Grid(maskFile);
  } else {
    mask = new Grid(src);
    mask->zero();
    mask->shift(1.0);
  }
  
  printf("direction: %d\n", direct);
  src.profileAverage(direct, *mask, outFile);

  delete mask;
  return 0;
}
