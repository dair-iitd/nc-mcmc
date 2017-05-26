LoadPackage("orb");;

runtimeSum := function()
	local t;;
	t := Runtimes();;
	return t.user_time + t.user_time_children;;
end;;
iterations := 20;;  # Number of Iterations
num_sample := 450000;;
inter_sz := 4500;;	# Interval size when kl is computed
take_all_till := 20;;	# Computes marginal for all samples till ___

dom_size := [];;	# Domain size of each variable
num := -1;;			# Number of variables
feat := [];;		# A list of features. Each feature is given as (w, clause) where clause is a list of var-val pairs (var,val)
var_to_feat := [];;	# For each variable, has list of features containing that variable

state := [];;	# A list containing assignment of each variable

counts := [];;	# For each variable we have the count for each value in it's domain
marginals := [];;	# For each variable we have the count for each value in it's domain

# smoothing constant for computing KL-divergence is 0.000000001
smooth := 0.000000001;;

# load the random source
rs1 := RandomSource(IsMersenneTwister);;#, runtimeSum());;

Read("marginals.g");


read_file := function(file_name)
	local inp, file_str, file_lines, i, f, temp, var, sz, w, cl, l, temp2, this_feat, include;;

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
			Add(cl, [Int(temp2[1]), Int(temp2[2])]);;
		od;;

		Add(feat, [w, cl]);;
	od;;

	for i in [1..num] do
		this_feat := [];;

		for f in feat do
			include := false;;
			cl := f[2];;
			for l in cl do
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

	state := [];;
	for i in [1..num] do
		r := Random(rs1, 0, dom_size[i]-1);;
		Add(state, r);;
	od;;
end;;

init_counts := function()
	local i, j;;

	for i in [1..num] do
		counts[i] := [];;
		marginals[i] := [];;
		for j in [1..dom_size[i]] do
			Add(counts[i], 0);;
			Add(marginals[i], 0.0);;
		od;;
	od;;
end;;


sample_var := function(var_to_sample)
	local up, sum_worlds, old_val, d, tot_w, f, w, cl, satisfied, l, r, Sum;;

	up := [];;	# Unnormalized probability for each assignment of var
	sum_worlds := 0.0;;	# This is the sum of the exponentials of each assignment possible

	old_val := state[var_to_sample];;

	for d in [0..(dom_size[var_to_sample]-1)] do
		state[var_to_sample] := d;;

		tot_w := 0.0;;	# Will hold the sum of weights of satisfied features in this assignment

		for f in var_to_feat[var_to_sample] do
			w := f[1];;
			cl := f[2];;

			satisfied := false;;

			for l in cl do
				if state[l[1]] = l[2] then
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
	od;;

	state[var_to_sample] := old_val;;

	r := Random(rs1, 0, 100000000000) / 100000000000.0 * sum_worlds;;
	Sum := 0;;
	for d in [0..(dom_size[var_to_sample]-1)] do
		Sum := Sum + up[d+1];;
		if r <= Sum then
			return d;;
		fi;;
	od;;
end;;


update_counts := function()
	local i;;

	for i in [1..num] do
		counts[i][state[i]+1] := counts[i][state[i]+1] + 1;;
	od;;
end;;


update_marginals := function(n)
	local i, d;;

	for i in [1..num] do
		for d in [0..(dom_size[i]-1)] do
			marginals[i][d+1] := counts[i][d+1]/Float(n);;
		od;;
	od;;
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
		PrintTo("kl_gibbs.csv", "");;

		for n in [1..num_sample] do

			# Gibbs Step
			var_to_sample := Random(rs1, 1, num);;
			new_val := sample_var(var_to_sample);;
			state[var_to_sample] := new_val;;

			# Update counts
			update_counts();;

			# Compute KL-Divergence every inter_sz samples
			if (RemInt(n,inter_sz) = 0)  then
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
					timeTaken := timeArr[n/inter_sz];;
					AppendTo("kl_gibbs.csv",String(timeTaken),",",String(klPerInterval[n/inter_sz]),",",String(n),",",String(standard_error),"\n");;
				fi;;

				
			fi;;

		od;;
	od;;
end;;


read_file("test.num");;

gibbs(num_sample,iterations);;

PrintTo("gibbs_marginals.txt", "gibbs_marginals := [");;

for i in [1..num] do
	AppendTo("gibbs_marginals.txt", "\n[");;
	for d in [0..(dom_size[i]-1)] do
		AppendTo("gibbs_marginals.txt", counts[i][d+1]/Float(num_sample), ",");;
	od;;
	AppendTo("gibbs_marginals.txt", "],");;
od;;

AppendTo("gibbs_marginals.txt", "\n];;\n");;
