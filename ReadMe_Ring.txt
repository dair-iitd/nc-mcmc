To run vv-symmetry orbital gibbs :-

1. Run "python generate_ringGraph.py 1000 test"
This generates the ring graphical model of size 1000 and stores it in file "test"

2. Run "python construct_graph.py test test.saucy"
This takes the graphical model "test" and generates the graph "test.saucy" over which saucy is run so that we get vv-symmetries

3. Run python construct_graph_orbital.py test test_orbital.saucy
This takes the graphical model "test" and generates the graph "test_orbital.saucy" as per orbital Symmetry(Variable Symmetry) over which saucy is run so that we get variable-symmetries

4. Run "python simplify_graph.py test test.num"
This takes the graphical model "test" and simiplifies it, i.e. it discards variable names and make them 1,2,3,....,(#var) and it discards domain values of each variable and makes them 0,1,2,....(domain_size-1)

5. Run "$GAP_DIR/gap4r7/bin/gap.sh -q < marginals_generator.g"
This runs the marginals generator that takes the file "test.num" and gives us true marginals. The gap.sh file could be found in gap installation.

6. Run "$GAP_DIR/gap4r7/bin/gap.sh -q < gibbs.g"
This runs vanilla gibbs and takes test.num as input graphical model. It finally gives us the KL-div values (across iterations) and the final marginals obtained by gibbs

7. Run "$GAP_DIR/gap4r7/bin/gap.sh -q < nc_gibbs.g"
This runs vv-symmetry orbital gibbs and takes test.num as input graphical model & test.saucy as graph to run saucy over. It finally gives us the KL-div values (across iterations) and the final marginals obtained by vv-symmetry orbital gibbs



File formats

test: First has names of all variables, then domain values of each variable. Finally it has a list of features. Each feature is given by a weight and a clause [The clause is simply a list of vv-pairs] that are tab-separated

test.num: Has the # of variables, then the domain size of each variable. Finally, it has the list of features

test.saucy: Format of graph taken in by saucy to run graph isomorphism with colours

