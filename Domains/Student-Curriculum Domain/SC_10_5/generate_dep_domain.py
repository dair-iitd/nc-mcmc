from sys import argv
import random

n = int(argv[1])
r= int(argv[2])
out = open(argv[3], 'w')

#evidence=[None]*(num+1)
# for i in range(1,num+1):
# 	r = random.random()
# 	if(r<0.0):#float(argv[3])):
# 		evidence[i]=1
# 	else:
# 		evidence[i]=0


first_var_set=False
temp_str="Vars:"
for i in range(1, n+1):
	for j in range(1,r+1):
		if(first_var_set):
			temp_str+=","
		temp_str+="P"+str(i)+"R"+str(j)
		first_var_set=True
for i in range(1,n+1):
	for j in range(1,r+1):
 		for k in range(1,r+1):
 			temp_str+=",P"+str(i)+"R"+str(j)+"R"+str(k)
out.write(temp_str)
out.write('\n\n')
	

p=10

for i in range(1, n+1):
	for j in range(1,r+1):
		out.write("P"+str(i)+"R"+str(j))
		temp_str = '=0,'
		for x in range(1,j+1):
				#if(courses[x]):
			temp_str += str(x)+','
		out.write(temp_str[:-1])
		out.write('\n')
for i in range(1,n+1):
	for j in range(1,r+1):
 		for k in range(1,r+1):
 			out.write("P"+str(i)+"R"+str(j)+"R"+str(k)+"=0,1\n")
out.write('\n')

# for i in range(1,num+1):
# 	for j in range(1,num+1):
# 		if((evidence[i]==0) and evidence[j]==0):
# 			out.write("F("+str(i)+"-"+str(j)+")=0,1\n")
# out.write('\n')
weights=[None]*(n+1)
for i in range(1,n+1):
	weights[i]=1+random.random()
for i in range(1,n+1):
	for j in range(1,r+1):
		#if(evidence[i]==0) and (evidence[j]==0):
		out.write(str(weights[i])+"\t"+"P"+str(i)+"R"+str(j)+" 0\n")
for i in range(1,n+1):
	for j in range(1,r+1):
		for k in range(1,r+1):
			if(j!=k):
				out.write("1.2\t"+"P"+str(i)+"R"+str(j)+"R"+str(k)+" 0,P"+str(i)+"R"+str(j)+" 0,P"+str(i)+"R"+str(k)+" 0\n")
#out.write('\n')
	
# for i in range(1, num+1):
# 	if evidence[i]==0:
# 		out.write("1.9\t" + str(i) + " 0\n");

out.close()













