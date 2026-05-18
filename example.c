/* Adapted from the GSL manual
 *  compile with: gcc -Wall -std=c99 example.c -lgsl -lgslcblas -lm
 *  The GSL has been installed to the system directories, so no -I or -L flags are required.
 *  This is because the header and library files are located at a path that is searched by default.
 *  You can use the find command to locate these files for your self.
*/
#include <stdio.h>
#include "gsl/gsl_linalg.h"

int
main (void)
{
  double a_data[] = { 0.18, 0.60, 0.57, 0.96,
                      0.41, 0.24, 0.99, 0.58,
                      0.14, 0.30, 0.97, 0.66,
                      0.51, 0.13, 0.19, 0.85 };

  double b_data[] = { 1.0, 2.0, 3.0, 4.0 };

  gsl_matrix_view m
    = gsl_matrix_view_array (a_data, 4, 4);

  gsl_vector_view b
    = gsl_vector_view_array (b_data, 4);

  gsl_vector *x = gsl_vector_alloc (4);

  int s;

  gsl_permutation * p = gsl_permutation_alloc (4);

  gsl_linalg_LU_decomp (&m.matrix, p, &s);

  gsl_linalg_LU_solve (&m.matrix, p, &b.vector, x);

  printf ("x = \n");
  gsl_vector_fprintf (stdout, x, "%g");

  double x0 = gsl_vector_get(x, 0);
  double x1 = gsl_vector_get(x, 1);
  double x2 = gsl_vector_get(x, 2);
  double x3 = gsl_vector_get(x, 3);

  printf("Solution:\n\tx0 = %lf\n\tx1 = %lf\n\tx2 = %lf\n\tx3 = %lf\n", x0, x1, x2, x3);

  gsl_permutation_free (p);
  gsl_vector_free (x);
  return 0;
}

//End of program.
