LoadPackage("orb");;

num_sample := 10000000;;

dom_size := [];;	# Domain size of each variable
num := -1;;			# Number of variables
feat := [];;		# A list of features. Each feature is given as (w, clause) where clause is a list of var-val pairs (var,val)
var_to_feat := [];;	# For each variable, has list of features containing that variable

state := [];;	# A list containing assignment of each variable

marginal := [];;	# For each variable we have the count for each value in it's domain

# load the random source
rs1 := RandomSource(IsMersenneTwister);;#, runtimeSum());;


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

init_marginal := function()
	local i, j;;

	for i in [1..num] do
		marginal[i] := [];;
		for j in [1..dom_size[i]] do
			Add(marginal[i], 0);;
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


update_marginal := function()
	local i;;

	for i in [1..num] do
		marginal[i][state[i]+1] := marginal[i][state[i]+1] + 1;;
	od;;
end;;


gibbs := function(num_sample)
	local n, var_to_sample, new_val;;

	init_state();;
	init_marginal();;

	for n in [1..num_sample] do
		var_to_sample := Random(rs1, 1, num);;

		new_val := sample_var(var_to_sample);;
		state[var_to_sample] := new_val;;

		update_marginal();;

		# if RemInt(n,1000) = 0 then
		# 	Print(state, "\n");;
		# fi;;
	od;;
end;;


read_file("test.num");;

gibbs(num_sample);;

PrintTo("marginals.g", "true_marginals := [");;

for i in [1..num] do
	AppendTo("marginals.g", "\n[");;
	for d in [0..(dom_size[i]-1)] do
		AppendTo("marginals.g", marginal[i][d+1]/Float(num_sample), ",");;
	od;;
	AppendTo("marginals.g", "],");;
od;;

AppendTo("marginals.g", "\n];;\n");;
