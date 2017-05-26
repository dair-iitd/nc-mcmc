This Code is for NC-MCMC algorithm described in ""Non-Count Symmetries in Boolean & Multi-Valued Prob. Graphical Models".
Ankit Anand, Ritesh Noothigattu, Parag Singla, Mausam. International Conference on Artificial Intelligence and Statistics (AISTATS). Fort Lauderdale, Florida. April 2017. The code is built on base code of orbital-MCMC given by Mathias Niepert for paper "Markov Chain on Orbits of Permutation Groups", Mathias Niepert, UAI'12. We thank Mathias Niepert for providing us base code.

The code directory has 3 sub-directories: 
1. Source Files: It contains the base source code for various algorithms viz. Vanilla-Gibbs, Orbital-MCMC, NC-MCMC, Dom-Reduced MCMC and code to generate marginals ( This is same as Vanilla-Gibbs but more samples taken). Each file is explained in corresponding directory.
2. Utils: It includes various utlility files to generate different formats for input to algorithms. Also, Domain code and weights used is specified in Random_Domain_Generator subdirectory.
3. Domains: It includes two domains along with all results illustrated in AISTATS'17 "Non-Count Symmetries in Boolean & Multi-Valued Prob. Graphical Models".
Ankit Anand, Ritesh Noothigattu, Parag Singla, Mausam.

A typical process to run any new domain instance. All these steps are already done 

Go through README_Ring.txt and ReadMe_SC.txt for Ring and SC domains respectively 

Notes: 

For All Orbital Algorithms: Saucy executable (present in Utils) should be copied to respective directory(Domain Instance). All algorithms assume this is present in present working directory.

TO BE UPDATED: 
1.Arguments for each file (Although it is trivial looking at source code to understand arguments, this section will be updated soon)
2. Domain description as per code.

Credits: If you use any of these source codes, Please cite our paper "Non-Count Symmetries in Boolean & Multi-Valued Prob. Graphical Models".
Ankit Anand, Ritesh Noothigattu, Parag Singla, Mausam. International Conference on Artificial Intelligence and Statistics (AISTATS). Fort Lauderdale, Florida. April 2017.
