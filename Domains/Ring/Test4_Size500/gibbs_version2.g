LoadPackage("orb");;

runtimeSum := function()
	local t;;
	t := Runtimes();;
	return t.user_time + t.user_time_children;;
end;;
iterations := 20;;  # Number of Iterations
num_sample := 450000;;
inter_sz := 4500;	# Interval size when kl is computed
take_all_till := 1;;	# Computes marginal for all samples till ___

dom_size := [];;	# Domain size of each variable
num := -1;;			# Number of variables
feat := [];;		# A list of features. Each feature is given as (w, clause) where clause is a list of var-val pair indices
var_to_feat := [];;	# For each variable, has list of features containing that variable

state := Set([]);;	# Set of vv-pair indices that are on in the state

counts := [];;		# We have the count for each vv-pair
marginals := [];;	# For each variable we have the marginal for each value in it's domain

max_size := 0;;		# Maximum index of vv-pairs

# smoothing constant for computing KL-divergence is 0.000000001
smooth := 0.000000001;;

vv_to_ind := [];;	# Map from var-val pair to index in permutation/state
ind_to_vv := [];;	# Map from index in permutation to var-val pair
start_inds := [];;	# The beginning index of each variable in bit-vector

start_time := runtimeSum();;

# load the random source
rs1 := RandomSource(IsMersenneTwister);;#, runtimeSum());;

Read("marginals.g");


# Running saucy to get symmetry group
Exec( "./saucy test_orbital.saucy | sed '$s/,$//' > sym.tmp" );;
# read the Saucy-generated file with the group generators
inputg := InputTextFile("sym.tmp");;
symStr := ReadAll(inputg);;

# write the group definition with the generators in a GAP file
PrintTo("sym.g", "g := Group(", symStr, ");;");;
# read and interpret this GAP file (so as to load the group)
# g is then the permutation group
sym_found :=1;;
prpl := [];;
if symStr = fail then
	Print("No Generators found...");;
	sym_found :=0;;	
else
	Read("sym.g");;
	prpl := ProductReplacer(g);;
	Next(prpl);;
fi;;

# Initializes the Product Replacement Algorithm

sym_discovery_time := (runtimeSum() -start_time)/1000.0;;

read_file := function(file_name)
	local inp, file_str, file_lines, i, f, temp, var, sz, w, cl, l, temp2, this_feat, include, d, index;;

	inp := InputTextFile(file_name);;
	file_str := ReadAll(inp);;
	file_lines := SplitString(file_str, "\n");;

	num := Int(file_lines[1]);;

	for i in [3..(3+num-1)] do
		temp := SplitString(file_lines[i], ":");;
		var := Int(temp[1]);;
		sz := Int(temp[2]);;
		dom_size[var] := sz;;
	od;;

	max_size := num;;
	for i in [1..num] do
		max_size := max_size + dom_size[i];;
	od;;

	ind_to_vv := NewDictionary(false, true, [(num+1)..max_size]);;
	vv_to_ind := NewDictionary([1,0], true);;
	start_inds := [];;

	index := num+1;;
	
	for var in [1..num] do
		Add(start_inds, index);;
		for d in [0..(dom_size[var]-1)] do
			#Print("Var", var," ", d," ",index+num*d," ",[var,d],"\n");;
			AddDictionary(ind_to_vv,index+num*d,[var,d]);;
			AddDictionary(vv_to_ind, [var,d], index+num*d);;
		od;;
		index := index +1;;
	od;;

	

	# for i in [1..num] do
	# 	Add(start_inds, index);;

	# 	for d in [0..(dom_size[i]-1)] do
	# 		AddDictionary(ind_to_vv, index, [i,d]);;
	# 		AddDictionary(vv_to_ind, [i,d], index);;
	# 		index := index + 1;;
	# 	od;;
	# od;;

	# Read features and convert vv-pairs to indices
	for f in [(4+num)..Length(file_lines)] do

		if file_lines[f] = "" then
			continue;;
		fi;;

		temp := SplitString(file_lines[f], "\t");;

		w := Float(temp[1]);;
		temp := SplitString(temp[2], ",");;

		cl := [];;

		for l in temp do
			temp2 := SplitString(l, " ");;
			AddSet(cl, LookupDictionary(vv_to_ind, [Int(temp2[1]), Int(temp2[2])]));;
		od;;

		Add(feat, [w, cl]);;
	od;;

	# Fill var_to_feat for each variable
	for i in [1..num] do
		this_feat := [];;

		for f in feat do
			include := false;;
			cl := f[2];;
			for index in cl do
				l := LookupDictionary(ind_to_vv, index);;
				if l[1] = i then
					include := true;;
					break;;
				fi;;
			od;;

			if include then
				Add(this_feat, f);;
			fi;;
		od;;

		Add(var_to_feat, this_feat);;
	od;;
end;;


init_state := function()
	local i, r;;

	state := Set([]);;
	for i in [1..num] do
		r := Random(rs1, 0, dom_size[i]-1);;
		AddSet(state, LookupDictionary(vv_to_ind, [i,r]));;
	od;;
end;;

init_counts := function()
	local i, j;;

	counts := [];;
	marginals := [];;

	for i in [1..max_size] do
		Add(counts, 0);;
	od;;

	# Initialize marginals
	for i in [1..num] do
		marginals[i] := [];;
		for j in [1..dom_size[i]] do
			Add(marginals[i], 0.0);;
		od;;
	od;;
end;;

# Caution! sample_var changes the value of var_to_sample in state
sample_var := function(var_to_sample)
	local up, sum_worlds, beg_ind, end_ind, index, d, tot_w, f, w, cl, satisfied, l, r, Sum;;

	up := [];;	# Unnormalized probability for each assignment of var_to_sample
	sum_worlds := 0.0;;	# This is the sum of the exponentials of each assignment possible

	beg_ind := start_inds[var_to_sample];;
	
	# Clearing value of var_to_sample from state
	for d in [0..(dom_size[var_to_sample]-1)] do
		index := beg_ind+d*num;;
		if index in state then
			RemoveSet(state, index);;
			break;;
		fi;;
	od;;

	index := beg_ind;;

	for d in [0..(dom_size[var_to_sample]-1)] do
		AddSet(state, index);;

		tot_w := 0.0;;	# Will hold the sum of weights of satisfied features in this assignment

		for f in var_to_feat[var_to_sample] do
			w := f[1];;
			cl := f[2];;

			satisfied := false;;

			for l in cl do
				if l in state then
					satisfied := true;;
					break;;
				fi;;
			od;;

			if satisfied then
				tot_w := tot_w + w;;
			fi;;
		od;;

		Add(up, Exp(tot_w));;
		sum_worlds := sum_worlds + up[d+1];;
		
		RemoveSet(state, index);;

		index := index + num;;
	od;;

	r := Random(rs1, 0, 100000000000) / 100000000000.0 * sum_worlds;;
	Sum := 0;;
	for d in [0..(dom_size[var_to_sample]-1)] do
		Sum := Sum + up[d+1];;
		if r <= Sum then
			AddSet(state, beg_ind+d*num);;
			return;;
		fi;;
	od;;
end;;


update_counts := function()
	local index;;

	for index in state do
		counts[index] := counts[index] + 1;;
	od;;
end;;


update_marginals := function(n)
	local index, i, d;;

	index := num + 1;;
	for i in [1..num] do
		for d in [0..(dom_size[i]-1)] do
			marginals[i][d+1] := counts[index+d*num]/Float(n);;
		od;;
		index := index + 1;;
	od;;
end;;


jump_in_orbit := function()
	#Print("State-",state,"\n");;
	state := OnSets(state, Next(prpl));;
	#Print("state",state,"\n");;
end;;


kullback := function(m1, m2, type)	# m1 is current marginals, m2 is true marginals
	local sum1, sum2, i, d;;

	sum1 := 0.0;;
	sum2 := 0.0;;

	for i in [1..num] do
		for d in [0..(dom_size[i]-1)] do
			if(m1[i][d+1] > 0.0) then
				if(m2[i][d+1] > 0.0) then
					
					sum1 := sum1 + (m1[i][d+1] * Log(m1[i][d+1]/m2[i][d+1]));;
				else
					sum1 := sum1 + (m1[i][d+1] * Log(m1[i][d+1]/smooth));;
				fi;;
			fi;;
		od;;
	od;;


	for i in [1..num] do
		for d in [0..(dom_size[i]-1)] do
			if(m2[i][d+1] > 0.0) then
				if(m1[i][d+1] > 0.0) then
					sum2 := sum2 + (m2[i][d+1] * Log(m2[i][d+1]/m1[i][d+1]));;
				else
					sum2 := sum2 + (m2[i][d+1] * Log(m2[i][d+1]/smooth));;
				fi;;
			fi;;
		od;;
	od;;

	if type = 1 then
		return sum1 + sum2;;
	elif type = 2 then
		return sum1 / Float(Length(m1));;
	elif type = 3 then
		return sum1 / Float(num);;
	else
		return sum2 / Float(Length(m2));;
	fi;;
end;;


gibbs := function(num_sample,iterations)
	local n, var_to_sample, new_val, start_time, klPerInterval, entries_per_iter, timeArr, kl_vals, i, iter, variance, current_kl, standard_error, timeTaken;;
	entries_per_iter := num_sample/inter_sz;;
	klPerInterval := [];;
	timeArr := [];;
	kl_vals := [];;

	for i in [1..entries_per_iter] do
		timeArr[i] := 0 ;;
		klPerInterval[i] :=0;;
	od;;

	for iter in [1.. iterations] do 
		start_time := runtimeSum();;

		init_state();;
		init_counts();;
		PrintTo("gibbs_kl.csv", "");;

		for n in [1..num_sample] do
		
			# Gibbs Step: Move from x to y'
			var_to_sample := Random(rs1, 1, num);;
			sample_var(var_to_sample);;

			# Orbital Step
			# if sym_found=1 then
			# 	jump_in_orbit();;
			# fi;;

			# Update counts
			update_counts();;

			# Compute KL-Divergence every inter_sz samples
			if (RemInt(n,inter_sz) = 0) then #or (n<=take_all_till) then
				update_marginals(n);;
				current_kl := kullback(marginals, true_marginals, 3);
				
				timeArr[n/inter_sz] := timeArr[n/inter_sz] + (runtimeSum()-start_time)/1000.0 ;;
				kl_vals[iter*entries_per_iter+n/inter_sz] := current_kl;;
				klPerInterval[n/inter_sz]:= klPerInterval[n/inter_sz] + current_kl;;
				if iter = iterations then
					timeArr[n/inter_sz] := timeArr[n/inter_sz]/iterations;;
					klPerInterval[n/inter_sz] := klPerInterval[n/inter_sz]/iterations;;
					variance := 0;
					for i in [1..iterations] do
						variance := variance + (kl_vals[i*entries_per_iter+n/inter_sz] - klPerInterval [n/inter_sz])*(kl_vals[i*entries_per_iter+n/inter_sz] - klPerInterval [n/inter_sz]);
					od;;
					standard_error := 2*Sqrt(variance)/iterations;;
					timeTaken := timeArr[n/inter_sz] ;;##+ sym_discovery_time;;
					AppendTo("gibbs_kl.csv", String(timeTaken),",",String(klPerInterval[n/inter_sz]),",",String(n),",",String(standard_error),"\n");;
				fi;;
			fi;;
		od;;	
	od;;
end;;


read_file("test.num");;

gibbs(num_sample,iterations);;

PrintTo("orbitals_marginals.txt", "nc_marginals := [");;

update_marginals(num_sample);;
for i in [1..num] do
	AppendTo("orbitals_marginals.txt", "\n[");;
	for d in [0..(dom_size[i]-1)] do
		AppendTo("orbitals_marginals.txt", marginals[i][d+1], ",");;
	od;;
	AppendTo("orbitals_marginals.txt", "],");;
od;;

AppendTo("orbitals_marginals.txt", "\n];;\n");;
