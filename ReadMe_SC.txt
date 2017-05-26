Please see the readme.txt in Ring domain folder to better understand this one. Files with same names as in  that have the same meaning in this folder

To run Gibbs-MH hybrid with Domain Reduction :-

1. Run "python generate_dep_domain.py 10 5 test"
This generates the student curriculum domain graph with 10 students and 5 courses

2. Run "python simplify_graph.py test test.num"
This takes the graphical model "test" and simiplifies it, i.e. it discards variable names and make them 1,2,3,....,(#var) and it discards domain values of each variable and makes them 0,1,2,....(domain_size-1)

3. Need to run "python getReduction.py test.num test_getdr.saucy test.reduc test_reduc.saucy"


4. Run "$GAP_DIR/gap4r7/bin/gap.sh -q < marginals_generator.g"
This runs the marginals generator that takes the file "test.num" and gives us true marginals

5. Run "$GAP_DIR/gap4r7/bin/gap.sh -q < gibbs.g"
This runs vanilla gibbs and takes test.num as input graphical model. It finally gives us the KL-div values (across iterations) and the final marginals obtained by gibbs

6. Run "python construct_graph.py test test.saucy" and then "$GAP_DIR/gap4r7/bin/gap.sh -q < nc_gibbs.g"
First generates the graph "test.saucy" to find vv-symmetry for nc_gibbs.g (no domain reduction) and then runs vv-symmetry orbital gibbs (to compare against the domain reduction one)

7. Run "$GAP_DIR/gap4r7/bin/gap.sh -q < domred_gibbs.g"
This runs the Gibbs-MH hybrid with domain reduction. It takes the file "test.reduc" as the graphical model (which also has the domain reduction) and "test_reduc.saucy" as the reduced graph to run saucy over (to get vv-symmetry over reduced domain). It finally gives us KL-div values (across iterations) and the final marginals obtained by this algorithm




File formats

test: First has names of all variables, then domain values of each variable. Finally it has a list of features. Each feature is given by a weight and a clause [The clause is simply a list of vv-pairs] that are tab-separated

test.num: Has the # of variables, then the domain size of each variable. Finally, it has the list of features

test.reduc: Same as test.num, except that it has the domain reduction specified for each variable (while mentioning it's domain size). 0|1|2.3| means that the partition is {{0},{1},{2,3}}

test.saucy, test_getdr.saucy, test_reduc.saucy: Format of graph taken in by saucy to run graph isomorphism with colours
