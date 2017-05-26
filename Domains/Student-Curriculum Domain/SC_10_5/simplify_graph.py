from sys import argv
import random
import math

Vars = []	# Contains list of variables
Doms = []	# Domain of each variable
Doms_map = []	# For each variable, has a map from domain values of that var to domain indices
num = -1	# Number of variables
feat = []	# A list of features. Each feature is given as (w, clause) where clause is a list of var-val pairs (var_ind,val)
var_map = {}	# Map from variable name to index (in state)
var_to_feat = []	# For each variable, has list of features containing that variable

state = []	# A list containing assignment of each variable

marginal = []	# For each variable we have the count for each value in it's domain

def str_to_literal(Str):
	[var,val] = Str.split()
	var_ind = var_map[var]
	val_ind = Doms_map[var_ind][val]
	return (var_ind, val_ind)

def read_file(file_name):
	global Vars, Doms, Doms_map, num, feat, var_map, var_to_feat

	inp = open(file_name, 'r')

	temp = inp.readline().strip()
	if(temp == ''):
		temp = inp.readline().strip()

	temp = temp.split(':')[1]
	Vars = temp.split(',')

	num = len(Vars)

	for i in range(num):
		var_map[Vars[i]] = i

	temp = inp.readline().strip()
	if(temp == ''):
		temp = inp.readline().strip()

	Doms = [None]*num
	Doms_map = [None]*num

	for i in range(num):
		[var, dom] = temp.split('=')
		this_ind = var_map[var]

		dom = dom.split(',')
		Doms[this_ind] = dom

		this_map = {}
		for j in range(len(dom)):
			this_map[dom[j]] = j
		Doms_map[this_ind] = this_map

		temp = inp.readline().strip()

	if(temp == ''):
		temp = inp.readline().strip()
	
	while(temp != ''):
		[w, cl] = temp.split('\t')
		w = float(w)
		cl = cl.split(',')
		cl = map(str_to_literal, cl)
		feat.append((w,cl))

		temp = inp.readline().strip()

	var_to_feat = [None]*num

	for i in range(num):
		this_feat = []

		for f in feat:
			include = False
			cl = f[1]
			for l in cl:
				if l[0] == i:
					include = True
					break

			if(include):
				this_feat.append(f)

		var_to_feat[i] = this_feat


def write_file(file_name):
	out = open(file_name, 'w')
	out.write(str(num) + '\n\n')

	for i in range(num):
		out.write(str(i+1) + ":" + str(len(Doms[i])) + '\n')

	out.write('\n')

	for (w,cl) in feat:
		out.write(str(w) + '\t')
		for l in cl:
			out.write(str(l[0]+1) + ' ' + str(l[1]) + ',')
		out.write('\n')


def main():
	read_file(argv[1])

	# print "Vars:"
	# print Vars

	# print "\nDomains:"
	# print Doms

	# print "\nDomain Map:"
	# print Doms_map

	# print "\nFeatures:"
	# print feat

	# print "\nMap:"
	# print var_map

	# print "\nFeatMap"
	# print var_to_feat

	write_file(argv[2])

main()