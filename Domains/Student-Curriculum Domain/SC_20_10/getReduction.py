# THIS PROGRAM ASSUMES THAT THERE ARE NO DUPLICATE EDGES (DUE TO VAR TWICE IN CLAUSE, OR, DUPLICATE CLAUSE)
from sys import argv
from os import system

num = -1 # Number of variables
dom_size = [] # Domain size of each variable

feat = []	# A list of features. Each feature is given as (w, clause) where clause is a list of var-val pairs

mapping = []	# Stores the vertex index to variable name mapping
vv_map = {}		# Stores map from vv-pair to vertex index
splits = []		# Splits for colours
vertex_count = 0	# Number of vertices
feat_begin = 0		# Index where the vv-pairs finish

edges = []

num_parts = []	# For each variable, it is the no. of eq classes that are not singleton
asgn = []		# For each variable, it is a vector that has the index of the eq class of each dom value
parts = []		# For each variable, it is a vector of non-singleton eq classes (given by the set of values in that eq class)

weight_map = {}	# Map from weight of feature, to list of features that have that weight

def read_file(file_name):
	global num, dom_size, feat

	inp = open(file_name, 'r')

	num = int(inp.readline())
	dom_size = [0]*(num+1)

	inp.readline()

	for i in range(1,num+1):
		temp = inp.readline().split(':')
		dom_size[int(temp[0])] = int(temp[1])

	inp.readline()

	temp = inp.readline()

	while(temp != ''):
		[w, cl] = temp.split('\t')
		w = float(w)
		cl = cl.split(',')[:-1]
		cl = [(int(l.split()[0]), int(l.split()[1])) for l in cl]
		feat.append((w,cl))

		temp = inp.readline()


def construct_graph():
	global mapping, vv_map, splits, edges, vertex_count, feat_begin

	mapping = []
	vv_map = {}
	splits = []
	edges = []
	vertex_count = 0
	
	for i in range(1,num+1):
		mapping.append(i)

	splits.append(num)	# One colour for the hub nodes
	vertex_count = num

	for i in range(1, num+1):
		for d in range(dom_size[i]):
			mapping.append((i,d))
			vv_map[(i,d)] = vertex_count
			edges.append((i-1, vertex_count))
			vertex_count += 1
		splits.append(vertex_count)	# One colour for all var-val pairs of a variable

	feat_begin = vertex_count

	for f in feat:
		mapping.append(f)

		for l in f[1]:
			edges.append((vertex_count, vv_map[l]))

		vertex_count += 1
		splits.append(vertex_count)

	# splits.append(vertex_count)

def write_graph(file_name):
	out = open(file_name, 'w')

	num_col = len(splits)
	out.write(str(vertex_count) + ' ' + str(len(edges)) + ' ' + str(num_col))

	for c in range(num_col-1):
		out.write(' ' + str(splits[c]))

	out.write('\n')

	for e in edges:
		out.write(str(e[0]) + ' '  + str(e[1]) + '\n')

def compute_reduction(file_name):
	global num_parts, asgn, parts

	num_parts = [0]*(num+1)
	asgn = [0]*(num+1)
	parts = [0]*(num+1)

	for i in range(1, num+1):
		asgn[i] = [-1]*(dom_size[i])
		parts[i] = []

	inp = open(file_name, 'r')

	for line in inp:
		line = line.replace("(", "")
		tmp = line.split(")")
		for part in tmp[:-1]:
			tmp2 = part.split(",")

			if(len(tmp2) != 2):
				print "WARNING: Code does not handle permutations of size bigger than 2 !!!"

			ind1 = int(tmp2[0]) - 1
			ind2 = int(tmp2[1]) - 1

			if((ind1 >= feat_begin) or (ind2 >= feat_begin)):
				continue

			[var1, val1] = mapping[ind1]
			[var2, val2] = mapping[ind2]

			if(var1 != var2):
				print "ERROR: Cannot map nodes corresponding to different variables"

			asgn1 = asgn[var1][val1]
			asgn2 = asgn[var2][val2]

			if(asgn1 == -1):
				if(asgn2 == -1):
					# Create a new equivalence class
					new_class = num_parts[var1]
					num_parts[var1] += 1
					asgn[var1][val1] = new_class
					asgn[var2][val2] = new_class
					parts[var1].append([val1, val2])

				else:
					# Merge val1 into val2's equivalence class
					asgn[var1][val1] = asgn2
					parts[var2][asgn2].append(val1)

			else:
				if(asgn2 == -1):
					# Merge val2 into val1's equivalence class
					asgn[var2][val2] = asgn1
					parts[var1][asgn1].append(val2)

				else:
					if(asgn1 == asgn2):
						# Both values are already in the same equivalence class
						continue

					# Merge smaller equivalence of the two with the larger one
					l1 = len(parts[var1][asgn1])
					l2 = len(parts[var2][asgn2])

					if(l1 < l2):
						# Merge eq class of val1 with val2's
						for val in parts[var1][asgn1]:
							asgn[var1][val] = asgn2
							parts[var2][asgn2].append(val)
						parts[var1][asgn1] = []

					else:
						# Merge eq class of val2 with val1's
						for val in parts[var2][asgn2]:
							asgn[var2][val] = asgn1
							parts[var1][asgn1].append(val)
						parts[var2][asgn2] = []


def write_reduc_file(file_name):
	out = open(file_name, 'w')

	out.write(str(num) + '\n\n')

	for i in range(1, num+1):
		out.write(str(i) + ':' + str(dom_size[i]) + ':')

		d = 0
		for eqc_ind in asgn[i]:
			if(eqc_ind == -1):
				out.write(str(d) + '|')
			d += 1

		for eqc in parts[i]:
			if not eqc:
				continue	# Empty equivalence class

			out.write('.'.join([str(val) for val in eqc]) + '|')

		out.write('\n')

	out.write('\n')

	for f in feat:
		w = f[0]
		cl = f[1]

		out.write(str(w) + '\t')

		for l in cl:
			out.write(str(l[0]) + ' ' + str(l[1]) + ',')

		out.write('\n')

	out.close()


def construct_reduced_graph():
	global mapping, vv_map, splits, edges, vertex_count, weight_map

	mapping = []	# Destroys old mapping, but, doesn't use this
	vv_map = {}
	splits = []
	edges = []
	vertex_count = 0
	
	# for i in range(1,num+1):
	# 	mapping.append(i)

	splits.append(num)	# One colour for the hub nodes
	vertex_count = num

	for i in range(1, num+1):
		d = 0
		for eqc_ind in asgn[i]:
			if(eqc_ind == -1):	# The domain value forms a singleton equivalence class
				# mapping.append((i,d))
				vv_map[(i,d)] = vertex_count
				edges.append((i-1, vertex_count))
				vertex_count += 1
			d += 1

		for eqc in parts[i]:
			if not eqc:
				continue	# Empty equivalence class

			# mapping.append((i, eqc))
			vv_map[(i, tuple(eqc))] = vertex_count
			edges.append((i-1, vertex_count))
			vertex_count += 1

	splits.append(vertex_count)	# One colour for all var-val pairs

	weight_map = {}

	for (w, cl) in feat:
		if(weight_map.get(w) == None):
			weight_map[w] = [cl]
		else:
			weight_map[w].append(cl)

	for w in weight_map:
		for cl in weight_map[w]:
			# mapping.append([w,cl])

			this_adjList = []

			for l in cl:
				[var, val] = l
				this_asgn = asgn[var][val]
				if(this_asgn == -1):
					this_adjList.append(vv_map[l])
				else:
					this_ind = vv_map[(var, tuple(parts[var][this_asgn]))]
					if(this_ind not in this_adjList):
						this_adjList.append(this_ind)

			for this_ind in this_adjList:
				edges.append((vertex_count, this_ind))

			vertex_count += 1

		splits.append(vertex_count)


def main():
	read_file(argv[1])

	construct_graph()

	write_graph(argv[2])

	system('./saucy ' + argv[2] + ' > perm.tmp')

	compute_reduction("perm.tmp")

	write_reduc_file(argv[3])

	construct_reduced_graph()

	write_graph(argv[4])
main()