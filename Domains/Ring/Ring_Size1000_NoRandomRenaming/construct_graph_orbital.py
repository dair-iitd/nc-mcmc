# THIS PROGRAM ASSUMES THAT THERE ARE NO DUPLICATE EDGES (DUE TO VAR TWICE IN CLAUSE, OR, DUPLICATE CLAUSE)

from sys import argv

Vars = []	# Contains list of variables
Doms = {}	# Hash-table for domain of each variable
num = -1	# Number of variables
feat = []	# A list of features. Each feature is given as (w, clause) where clause is a list of var-val pairs (a,v)

mapping = {}	# A map storing the variable name for each vertex index
var_map = {}	# A map storing the vertex index for each variable name	
splits = []		# Splits for colours
vertex_count = 0	# Number of vertices

edges = []

weight_map = {}	# A map storing list of features for each weight

def read_file(file_name):
	global Vars, Doms, num

	inp = open(file_name, 'r')

	temp = inp.readline().strip()
	if(temp == ''):
		temp = inp.readline().strip()

	temp = temp.split(':')[1]
	Vars = temp.split(',')

	num = len(Vars)

	temp = inp.readline().strip()
	if(temp == ''):
		temp = inp.readline().strip()

	for a in range(num):
		[var, dom] = temp.split('=')

		if not(var in Vars):
			raise Exception(var + " does not exist!")

		dom = dom.split(',')
		Doms[var] = dom

		temp = inp.readline().strip()

	if(temp == ''):
		temp = inp.readline().strip()
	
	while(temp != ''):
		[w, cl] = temp.split('\t')
		w = float(w)
		cl = cl.split(',')
		cl = [(l.split()[0], l.split()[1]) for l in cl]
		feat.append((w,cl))

		temp = inp.readline().strip()


def construct_graph():
	global mapping, var_map, splits, edges, vertex_count, weight_map

	mapping = {}
	var_map = {}
	dom2vars ={}
	splits = []
	edges = []
	vertex_count = 0
	weight_map = {}
	
	for i in range(num):
		mapping[i] = Vars[i]
		var_map[Vars[i]] = i

	splits.append(num)	# One colour for the hub nodes
	vertex_count = num

	for var in Vars:
		for d in Doms[var]:
			if d in dom2vars.keys():
				dom2vars[d].append(var)
			else:
				dom2vars[d]=[var]

	for d in dom2vars:
		for var in dom2vars[d]:
			mapping[vertex_count] = (var,d)
			var_map[(var,d)] = vertex_count
			edges.append((var_map[var],vertex_count))
			vertex_count += 1
		splits.append(vertex_count)			



	

	for (w, cl) in feat:
		if(weight_map.get(w) == None):
			weight_map[w] = [cl]
		else:
			weight_map[w].append(cl)

	for w in weight_map:
		for cl in weight_map[w]:
			mapping[vertex_count] = cl
			# var_map[cl] = vertex_count

			for l in cl:
				edges.append((vertex_count, var_map[l]))

			vertex_count += 1

		splits.append(vertex_count)


def write_file(file_name):
	out = open(file_name, 'w')

	num_col = len(splits)
	out.write(str(vertex_count) + ' ' + str(len(edges)) + ' ' + str(num_col))

	for c in range(num_col-1):
		out.write(' ' + str(splits[c]))

	out.write('\n')

	for e in edges:
		out.write(str(e[0]) + ' '  + str(e[1]) + '\n')

def main():
	read_file(argv[1])

	# print "Vars:"
	# print Vars

	# print "\nDomains:"
	# print Doms

	# print "\nFeatrues:"
	# print feat

	construct_graph()

	# print "\nWeight Map:"
	# print weight_map

	# print "\nMapping:"
	# print mapping

	# print "\nVar_map:"
	# print var_map

	# print "\nSplits:"
	# print splits

	# print "\nEdges:"
	# print edges

	write_file(argv[2])

main()