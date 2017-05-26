LoadPackage("orb");;

runtimeSum := function()
	local t;;
	t := Runtimes();;
	return t.user_time + t.user_time_children;;
end;;
iterations :=20;;  # Number of Iterations
num_sample := 100000;;
inter_sz := 1000;;	# Interval size when kl is computed
take_all_till := 1;; #putes marginal for all samples till ___

dom_size := [];;	# Domain size of each variable
num := -1;;			# Number of variables
feat := [];;		# A list of features. Each feature is given as (w, clause) where clause is a list of var-partition pair indices
var_to_feat := [];;	# For each variable, has list of features containing that variable
dom_parts := [];;	# The partition of the domain for each variable

macro_st := Set([]);;	# Set of vpart that are on in the macro state

counts := [];;		# We have the count of each var-part pair
marginals := [];;	# For each variable we have the marginal for each value in it's domain

max_size := 0;;		# Maximum index in macro state

# smoothing constant for computing KL-divergence is 0.000000001
smooth := 0.000000001;;

vv_to_ind := [];;	# Map from var-val pair to index in permutation
ind_to_vpart := [];;	# Map from index in permutation to var-partition pair
ind_to_partsz := [];;	# Map/Array from index to partition-size
start_inds := [];;	# The beginning index of each variable in the macro state vector

# load the random source
rs1 := RandomSource(IsMersenneTwister);;#, runtimeSum());;

# Measuring times for profiling
gibbs_time := 0;;
# expand_time := 0;;
pra_time := 0;;
macrosz_time := 0;;
# sampling_time := 0;;
start2 := 0;;	# To measure the start of time of segment

macroSt_to_sz := [];;		# Map (cache) from macro state to it's size

Read("marginals.g");
start_time := runtimeSum();;

# Running saucy to get symmetry group
Exec( "./saucy test_reduc.saucy | sed '$s/,$//' > sym.tmp" );;
# read the Saucy-generated file with the group generators
inputg := InputTextFile("sym.tmp");;
symStr := ReadAll(inputg);;

# write the group definition with the generators in a GAP file
PrintTo("sym.g", "g := Group(", symStr, ");;");;
# read and interpret this GAP file (so as to load the group)
# g is then the permutation group
Read("sym.g");

# Initializes the Product Replacement Algorithm
prpl := ProductReplacer(g);;
Next(prpl);;
sym_discovery_time := (runtimeSum()-start_time)/1000.0;;

read_file := function(file_name)
	local inp, file_str, file_lines, i, f, temp, var, sz, parts, part, temp_part, w, cl, l, temp2, this_feat, include, d, index, part_sz, val;;

	inp := InputTextFile(file_name);;
	file_str := ReadAll(inp);;
	file_lines := SplitString(file_str, "\n");;

	num := Int(file_lines[1]);;

	for i in [3..(3+num-1)] do
		temp := SplitString(file_lines[i], ":");;
		var := Int(temp[1]);;
		sz := Int(temp[2]);;
		dom_size[var] := sz;;

		temp := SplitString(temp[3], "|");;
		parts := [];;
		for part in temp do
			temp_part := List(SplitString(part, "."), Int);;
			Add(parts, temp_part);;
		od;;

		dom_parts[var] := parts;;
	od;;

	max_size := num;;
	for i in [1..num] do
		max_size := max_size + Length(dom_parts[i]);;
	od;;

	ind_to_vpart := NewDictionary(false, true, [(num+1)..max_size]);;
	ind_to_partsz := [];;
	vv_to_ind := NewDictionary([1,0], true);;
	start_inds := [];;

	index := num+1;;

	for i in [1..num] do
		Add(start_inds, index);;

		for part in dom_parts[i] do
			for val in part do
				AddDictionary(vv_to_ind, [i,val], index);;
			od;;

			AddDictionary(ind_to_vpart, index, [i,part]);;
			ind_to_partsz[index] := Length(part);;
			index := index + 1;;
		od;;
	od;;

	# Read features and convert vv pairs to vpart indices
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
				l := LookupDictionary(ind_to_vpart, index);;
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

	#macroSt_to_sz := NewDictionary(Set([1,2,3]), true);;
end;;


init_state := function()
	local i, r;;

	macro_st := Set([]);;
	for i in [1..num] do
		r := Random(rs1, 0, dom_size[i]-1);;
		AddSet(macro_st, LookupDictionary(vv_to_ind, [i,r]));;
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

# Caution! sample_var changes the value of var_to_sample in macro_st
sample_var := function(var_to_sample)
	local up, sum_worlds, parts_num, beg_ind, end_ind, index, part, tot_w, f, w, cl, satisfied, l, this_up, r, d, Sum;;

	up := [];;	# Unnormalized probability for each assignment of var_to_sample
	sum_worlds := 0.0;;	# This is the sum of the exponentials of each assignment possible

	parts_num := Length(dom_parts[var_to_sample]);;

	beg_ind := start_inds[var_to_sample];;
	end_ind := beg_ind + parts_num - 1;;

	# Clearing value of var_to_sample from macro_st
	for index in [beg_ind..end_ind] do
		if index in macro_st then
			RemoveSet(macro_st, index);;
			break;;
		fi;;
	od;;

	index := beg_ind;;

	for part in dom_parts[var_to_sample] do
		AddSet(macro_st, index);;

		# Compute up for a state in macro_st
		tot_w := 0.0;;	# Will hold the sum of weights of satisfied features in this assignment

		for f in var_to_feat[var_to_sample] do
			w := f[1];;
			cl := f[2];;

			satisfied := false;;

			for l in cl do
				if l in macro_st then
					satisfied := true;;
					break;;
				fi;;
			od;;

			if satisfied then
				tot_w := tot_w + w;;
			fi;;
		od;;

		this_up := Exp(tot_w)*Length(part);;

		Add(up, this_up);;	# e^{tot_w} is the up of a value in part & e^{tot_w}*length is up of the vpart 
		sum_worlds := sum_worlds + this_up;;

		RemoveSet(macro_st, index);;

		index := index + 1;;
	od;;

	r := Random(rs1, 0, 100000000000) / 100000000000.0 * sum_worlds;;
	Sum := 0;;
	for d in [1..parts_num] do
		Sum := Sum + up[d];;
		if r <= Sum then
			AddSet(macro_st, beg_ind+d-1);;
			return;;
		fi;;
	od;;
end;;


update_counts := function()
	local index;;

	for index in macro_st do
		counts[index] := counts[index] + 1;;
	od;;
end;;


update_marginals := function(n)
	local i, part, index, prob, val;;

	index := num + 1;;
	for i in [1..num] do
		for part in dom_parts[i] do
			prob := counts[index]/(Length(part)*Float(n));;
			for val in part do
				marginals[i][val+1] := prob;;
			od;;
			index := index + 1;;
		od;;
	od;;
end;;


jump_in_orbit := function()
	local macro_sz, index, macro_new, new_macro_sz, r;;

	# start2 := runtimeSum();;
	#macro_sz := LookupDictionary(macroSt_to_sz, macro_st);;

	# if(macro_sz = fail) then
		macro_sz := 1;;

		# Computing the size of M[y']
		for index in macro_st do
			macro_sz := macro_sz * ind_to_partsz[index];;
		od;;

		#AddDictionary(macroSt_to_sz, macro_st, macro_sz);;
	# fi;;
	# macrosz_time := macrosz_time + (runtimeSum() - start2);;

	
	# start2 := runtimeSum();;
	macro_new := OnSets(macro_st, Next(prpl));;	# New macro state M[y]
	# pra_time := pra_time + (runtimeSum() - start2);;

	# start2 := runtimeSum();;
	#new_macro_sz := LookupDictionary(macroSt_to_sz, macro_new);;	# Has the size of macro state M[y]

	#if(new_macro_sz = fail) then
		new_macro_sz := 1;;

		for index in macro_new do
			new_macro_sz := new_macro_sz * ind_to_partsz[index];;
		od;;

		#AddDictionary(macroSt_to_sz, macro_new, new_macro_sz);;
	#fi;;
	# macrosz_time := macrosz_time + (runtimeSum() - start2);;

	if(new_macro_sz >= macro_sz) then	# Accept
		# Jump to the new macro state M[y]
		macro_st := macro_new;;
	else	# toss coin
		r := Random(rs1, 0, 100000000000) / 100000000000.0;;
		if r <= Float(new_macro_sz/macro_sz) then	# Accept
			# Jump to the new macro state M[y]
			macro_st := macro_new;;
		# else remain in M[y'] on rejection
		fi;;
	fi;;
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


gibbs := function(num_sample)
	local n, var_to_sample, start_time, klPerInterval, entries_per_iter, timeArr, kl_vals, i, iter, variance, current_kl, standard_error, timeTaken;;
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
		PrintTo("domred_kl.csv", "");;
		
		for n in [1..num_sample] do

		# start2 := runtimeSum();;
		# Gibbs Step: Move from x to y'
			var_to_sample := Random(rs1, 1, num);;
			sample_var(var_to_sample);;
			# gibbs_time := gibbs_time + (runtimeSum() - start2);;


			# MH-Step (equivalent to orbital step): Move from M[y'] to M[y] (if accept)
			jump_in_orbit();;

			# Update counts
			update_counts();;

			# Compute KL-Divergence every inter_sz samples
			if (RemInt(n,inter_sz) = 0) then
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
						timeTaken := timeArr[n/inter_sz]+sym_discovery_time;;
						AppendTo("domred_kl.csv",String(timeTaken),",",String(klPerInterval[n/inter_sz]),",",String(n),",",String(standard_error),"\n");;
				fi;;
			fi;;
		od;;

	od;;
end;;


read_file("test.reduc");;

gibbs(num_sample);;

PrintTo("domred_marginals.txt", "domred_marginals := [");;

update_marginals(num_sample);;
for i in [1..num] do
	AppendTo("domred_marginals.txt", "\n[");;
	for d in [0..(dom_size[i]-1)] do
		AppendTo("domred_marginals.txt", marginals[i][d+1], ",");;
	od;;
	AppendTo("domred_marginals.txt", "],");;
od;;

AppendTo("domred_marginals.txt", "\n];;\n");;


# Print("\nGibbs time: ", gibbs_time/1000.0);;
# Print("\nPRA time: ", pra_time/1000.0);;
# Print("\nMacro size time: ", macrosz_time/1000.0, "\n\n");;


# Print("\nDomain Size\n");;
# Print(dom_size);;

# Print("\n\nFeatures\n");;
# Print(feat);;

# Print("\n\nVar to Feat\n");;
# Print(var_to_feat);;

# Print("\n\nDomain Partitions\n");;
# Print(dom_parts);;

# Print("\n\nIndex to Part\n");;
# for k in [3..6] do
# 	Print(k, ":", LookupDictionary(ind_to_vpart,k), "\n");;
# od;;

# Print("\n\nIndex to part_sz\n");;
# for k in [3..6] do
# 	Print(k, ":", ind_to_partsz[k], "\n");;
# od;;

# Print("\n\nVV to index\n");;
# for i in [1..num] do
# 	for d in [0..dom_size[i]-1] do
# 		Print("[", i, ",", d, "]", ":");;
# 		Print(LookupDictionary(vv_to_ind,[i,d]));;
# 		Print("\n");;
# 	od;;
# od;;

# Print("\n\nCounts\n");;
# Print(counts);;

# Print("\n\n");;
