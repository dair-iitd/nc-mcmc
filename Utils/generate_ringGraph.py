import random
from sys import argv

num = int(argv[1])

out = open(argv[2], 'w')

out.write("Vars:")
random.seed()
for i in range(1, num):
	out.write(str(i) + ',')
out.write(str(num) + '\n\n')

for i in range(1, num+1):
	out.write(str(i) + '=0,1\n')
out.write('\n')
a=[None]*(num+1)

for i in range(1, num+1):
	print i+10
	if random.random() <0.5:
		a[i]=1
	else:
		a[i]=0

for i in range(1,num):
	if i%2==1:
		if a[i]==1 and a[i+1]==1:
			print 1
			out.write("1.2\t" + str(i) + " 0," + str(i+1) + " 1\n")
		elif a[i]==1 and a[i+1]==0:
			print 2			
			out.write("1.2\t" + str(i) + " 0," + str(i+1) + " 0\n")
		elif a[i]==0 and a[i+1]==1:
			print 3			
			out.write("1.2\t" + str(i) + " 1," + str(i+1) + " 1\n")
		else:
			print 4
			out.write("1.2\t" + str(i) + " 1," + str(i+1) + " 0\n")
	else:
		if a[i]==1 and a[i+1]==1:
			print 5			
			out.write("1.9\t" + str(i) + " 0," + str(i+1) + " 1\n")
		elif a[i]==1 and a[i+1]==0:
			print 6			
			out.write("1.9\t" + str(i) + " 0," + str(i+1) + " 0\n")
		elif a[i]==0 and a[i+1]==1:
			print 7			
			out.write("1.9\t" + str(i) + " 1," + str(i+1) + " 1\n")
		else:
			print 8
			out.write("1.9\t" + str(i) + " 1," + str(i+1) + " 0\n")
			
if a[num]==1 and a[1]==1:
	out.write("1.9\t" + str(num) + " 0," + str(1) + " 1\n")
elif a[num]==1 and a[1]==0:
	out.write("1.9\t" + str(num) + " 0," + str(1) + " 0\n")
elif a[num]==0 and a[1]==1:
	out.write("1.9\t" + str(num) + " 1," + str(1) + " 1\n")
else:
	out.write("1.9\t" + str(num) + " 1," + str(1) + " 0\n")

